import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
// Use the generated codec to exercise the actual native API contract.
// ignore: implementation_imports
import 'package:stream_thumbnail/src/messages.g.dart';
import 'package:video_editor/src/controller.dart';
import 'package:video_editor/src/export/ffmpeg_export_config.dart';
import 'package:video_editor/src/models/cover_data.dart';
import 'package:video_editor/src/utils/thumbnails.dart';

const _duration = Duration(seconds: 10);
const _trimStart = Duration(seconds: 2);
const _trimmedDuration = Duration(seconds: 6);
const _coverQuality = 83;
const _trimQuality = 47;
const _thumbnailChannel = BasicMessageChannel<Object?>(
  'dev.flutter.pigeon.stream_thumbnail.StreamThumbnailHostApi.thumbnailData',
  StreamThumbnailHostApi.pigeonChannelCodec,
);
const _fileChannel = BasicMessageChannel<Object?>(
  'dev.flutter.pigeon.stream_thumbnail.StreamThumbnailHostApi.thumbnailFile',
  StreamThumbnailHostApi.pigeonChannelCodec,
);

class _Controller extends VideoEditorController {
  _Controller()
    : super.file(
        File('/tmp/clip.mp4'),
        maxDuration: _duration,
        coverThumbnailsQuality: _coverQuality,
        trimThumbnailsQuality: _trimQuality,
      );

  @override
  Duration get videoDuration => _duration;
  @override
  Duration get startTrim => _trimStart;
  @override
  Duration get trimmedDuration => _trimmedDuration;
  @override
  bool get isTrimmed => true;
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final bytes = Uint8List.fromList([1, 2, 3]);
  late _Controller controller;
  late List<ThumbnailRequest> requests;

  setUp(() {
    controller = _Controller();
    requests = [];
    binding.defaultBinaryMessenger.setMockDecodedMessageHandler<Object?>(
      _thumbnailChannel,
      (message) async {
        requests.add((message! as List<Object?>).single! as ThumbnailRequest);
        return <Object?>[bytes];
      },
    );
  });

  tearDown(() async {
    binding.defaultBinaryMessenger.setMockDecodedMessageHandler<Object?>(
      _thumbnailChannel,
      null,
    );
    binding.defaultBinaryMessenger.setMockDecodedMessageHandler<Object?>(
      _fileChannel,
      null,
    );
    await controller.dispose();
  });

  test('trim strip keeps JPEG, sample positions, and quality', () async {
    final frames = await generateTrimThumbnails(controller, quantity: 2).last;
    expect(frames, [bytes, bytes]);
    expect(requests.map((r) => r.timeMs), [5000, 10000]);
    expect(
      requests.every(
        (r) => r.format == ThumbnailFormat.jpeg && r.quality == _trimQuality,
      ),
      isTrue,
    );
    expect(requests.every((r) => r.video == controller.file.path), isTrue);
  });

  test(
    'cover strip skips a failed frame and continues inside the trim range',
    () async {
      binding.defaultBinaryMessenger.setMockDecodedMessageHandler<Object?>(
        _thumbnailChannel,
        (message) async {
          requests.add((message! as List<Object?>).single! as ThumbnailRequest);
          if (requests.length == 1) {
            return <Object?>['DECODE_ERROR', 'Unsupported frame', null];
          }
          return <Object?>[bytes];
        },
      );
      final frames = await generateCoverThumbnails(
        controller,
        quantity: 2,
      ).last;
      expect(frames.single.thumbData, bytes);
      expect(frames.single.timeMs, 5000);
      expect(requests.map((r) => r.timeMs), [2000, 5000]);
      expect(
        requests.every(
          (r) => r.format == ThumbnailFormat.jpeg && r.quality == _coverQuality,
        ),
        isTrue,
      );
    },
  );

  test('single cover uses the requested timestamp and JPEG quality', () async {
    final cover = await generateSingleCoverThumbnail(
      controller.file.path,
      timeMs: 1500,
      quality: _coverQuality,
    );
    expect(cover.thumbData, bytes);
    expect(cover.timeMs, 1500);
    expect(requests.single.timeMs, 1500);
    expect(requests.single.format, ThumbnailFormat.jpeg);
    expect(requests.single.quality, _coverQuality);
  });

  test(
    'default cover failure is contained and a later successful request updates the selection',
    () async {
      final previous = CoverData(timeMs: 500);
      controller.updateSelectedCover(previous);
      binding.defaultBinaryMessenger.setMockDecodedMessageHandler<Object?>(
        _thumbnailChannel,
        null,
      );
      await controller.generateDefaultCoverThumbnail();
      expect(controller.selectedCoverVal, same(previous));
      binding.defaultBinaryMessenger.setMockDecodedMessageHandler<Object?>(
        _thumbnailChannel,
        (_) async => <Object?>[bytes],
      );
      await controller.generateDefaultCoverThumbnail();
      expect(controller.selectedCoverVal!.thumbData, bytes);
      expect(controller.selectedCoverVal!.timeMs, _trimStart.inMilliseconds);
    },
  );

  test(
    'cover export retains the Stream temporary file until FFmpeg consumes its command',
    () async {
      final directory = Directory.systemTemp.createTempSync(
        'stream-cover-export-',
      );
      addTearDown(() => directory.deleteSync(recursive: true));
      final thumbnail = File('${directory.path}/clip.jpg')
        ..writeAsBytesSync(bytes);
      binding.defaultBinaryMessenger.setMockDecodedMessageHandler<Object?>(
        _fileChannel,
        (message) async {
          final request =
              (message! as List<Object?>).single! as ThumbnailRequest;
          expect(request.format, ThumbnailFormat.jpeg);
          expect(request.timeMs, _trimStart.inMilliseconds);
          return <Object?>[thumbnail.path];
        },
      );
      final config = CoverFFmpegVideoEditorConfig(
        controller,
        outputDirectory: directory.path,
        isFiltersEnabled: false,
      );
      final execute = await config.getExecuteConfig();
      expect(execute!.command, contains(thumbnail.path));
      expect(thumbnail.readAsBytesSync(), bytes);
    },
  );
}
