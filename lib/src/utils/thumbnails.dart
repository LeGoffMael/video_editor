import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:video_editor/src/controller.dart';
import 'package:video_editor/src/models/cover_data.dart';
import 'package:stream_thumbnail/stream_thumbnail.dart';

Uint8List? thumbnailAtOrNull(List<Uint8List> thumbnails, int index) {
  if (index < 0 || index >= thumbnails.length) return null;
  return thumbnails[index];
}

Stream<List<Uint8List>> generateTrimThumbnails(
  VideoEditorController controller, {
  required int quantity,
}) async* {
  final String path = controller.file.path;
  final double eachPart = controller.videoDuration.inMilliseconds / quantity;
  List<Uint8List> byteList = [];

  for (int i = 1; i <= quantity; i++) {
    try {
      final Uint8List bytes = await StreamThumbnail.thumbnailData(
        imageFormat: StreamThumbnailFormat.jpeg,
        video: path,
        timeMs: (eachPart * i).toInt(),
        quality: controller.trimThumbnailsQuality,
      );
      byteList.add(bytes);
    } catch (e) {
      debugPrint(e.toString());
    }

    yield byteList;
  }
}

Stream<List<CoverData>> generateCoverThumbnails(
  VideoEditorController controller, {
  required int quantity,
}) async* {
  final int duration = controller.isTrimmed
      ? controller.trimmedDuration.inMilliseconds
      : controller.videoDuration.inMilliseconds;
  final double eachPart = duration / quantity;
  List<CoverData> byteList = [];

  for (int i = 0; i < quantity; i++) {
    try {
      final CoverData bytes = await generateSingleCoverThumbnail(
        controller.file.path,
        timeMs: (controller.isTrimmed
                ? (eachPart * i) + controller.startTrim.inMilliseconds
                : (eachPart * i))
            .toInt(),
        quality: controller.coverThumbnailsQuality,
      );

      if (bytes.thumbData != null) {
        byteList.add(bytes);
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    yield byteList;
  }
}

/// Generate a cover at [timeMs] in video
///
/// Returns a [CoverData] depending on [timeMs] milliseconds
Future<CoverData> generateSingleCoverThumbnail(
  String filePath, {
  int timeMs = 0,
  int quality = 10,
}) async {
  final Uint8List thumbData = await StreamThumbnail.thumbnailData(
    imageFormat: StreamThumbnailFormat.jpeg,
    video: filePath,
    timeMs: timeMs,
    quality: quality,
  );

  return CoverData(thumbData: thumbData, timeMs: timeMs);
}
