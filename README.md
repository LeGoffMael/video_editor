# Flutter video editor

[![Pub](https://img.shields.io/pub/v/video_editor.svg)](https://pub.dev/packages/video_editor)
[![GitHub stars](https://img.shields.io/github/stars/LeGoffMael/video_editor?style=social)](https://github.com/LeGoffMael/video_editor/stargazers)

A video editor that allows to edit (trim, crop, rotate and scale) and choose a cover with a very flexible UI design.

## 📖 Installation

Following steps will help you add this library as a dependency in your flutter project.

- Run `flutter pub add video_editor`, or add video_editor to `pubspec.yaml` file manually.

```yaml
dependencies:
  video_editor: ^2.4.0
```

- Import the package in your code:

```dart
import 'package:video_editor/video_editor.dart';
```

## 📸 Screenshots

| Example app running on an Iphone 11 pro | Customization example, light mode |
| --------------------------------------- | --------------------------------- |
| ![](./assets/demo.gif)                  | ![](./assets/light_editor.png)    |

## 👀 Usage

```dart
final VideoEditorController _controller = VideoEditorController.file(
  XFile('/path/to/video.mp4'),
  minDuration: const Duration(seconds: 1),
  maxDuration: const Duration(seconds: 10),
);

@override
void initState() {
  super.initState();
  _controller.initialize().then((_) => setState(() {}));
}

@override
void dispose() {
  _controller.dispose();
  super.dispose();
}
```

For more details check out the [example](https://github.com/LeGoffMael/video_editor/tree/master/example).

### VideoEditorController

| Function                         | Description                                                                                           |
| -------------------------------- |-------------------------------------------------------------------------------------------------------|
| initialize(aspectRatio)          | Init the `controller` parameters, the video, the trim and the cover, call `cropAspectRatio`           |
| rotate90Degrees(RotateDirection) | Rotate the video by 90 degrees in the direction provided                                              |
| preferredCropAspectRatio         | Update the aspect ratio of the crop area                                                              |
| setPreferredRatioFromCrop        | Update the aspect ratio to the current crop area ratio                                                |
| cropAspectRatio                  | Update the aspect ratio + update the crop area to the center of the video size                        |
| updateCrop                       | Update the controller crop min and max values                                                         |
| updateTrim                       | Update the controller trim min and max values                                                         |
| createVideoFFmpegConfig          | Creates a `VideoFFmpegConfig` object that can be used to generate an ffmpeg command via the `createExportCommand` method |
| createCoverFFmpegConfig          | Creates a `CoverFFmpegConfig` object that can be used to generate an ffmpeg command via the `createExportCommand` method  |

| Getter                           | Description                       |
| -------------------------------- | --------------------------------- |
| Duration startTrim               | The start value of the trimmed area |
| Duration endTrim                 | The end value of the trimmed area |
| Duration trimmedDuration         | The duration of the selected trimmed area |
| bool isTrimmed                   | Set to `true` when the trimmed values are not the default video duration |
| bool isTrimming                  | Set to `true` when startTrim or endTrim is changing |
| Duration maxDuration             | The maxDuration possible for the trimmed area |
| Duration minDuration             | The minDuration possible for the trimmed area |
| Offset minCrop                   | The top left position of the crop area (between `0.0` and `1.0`) |
| Offset maxCrop                   | The bottom right position of the crop area (between `0.0` and `1.0`) |
| Size croppedArea                 | The actual Size of the crop area |
| double? preferredCropAspectRatio | The preferred crop aspect ratio selected |
| bool isRotated                   | Set to `true` when the rotation is different to `0` |
| int rotation                     | The rotation angle set `0`, `90`, `180` and `270` |
| int cacheRotation                | The sum of all the rotation applied in the editor |
| CoverData? selectedCoverVal      | The selected cover thumbnail that will be used to export the final cover |

### Widgets

<details>
  <summary>Click to expand widgets documentation</summary>

####  Crop
##### 1. CropGridViewer

This widget is used to enable the crop actions on top of the video (CropGridViewer.edit), or only to preview the cropped result (CropGridViewer.preview).

| Param                            | Description                       |
| -------------------------------- | --------------------------------- |
| required VideoEditorController controller | The `controller` param is mandatory so every change in the controller settings will propagate in the crop view |
| EdgeInsets margin | The amount of space by which to inset the crop view, not used in preview mode |
| bool rotateCropArea | To preserve `preferredCropAspectRatio` when crop view is rotated |

#### Trimmer

##### 1. TrimSlider

Display the trimmer containing video thumbnails with rotation and crop parameters.

| Param                            | Description                       |
| -------------------------------- | --------------------------------- |
| required VideoEditorController controller | The `controller` param is mandatory so every change in the controller settings will propagate in the trim slider view |
| double height = 0.0 | The `height` param specifies the height of the generated thumbnails |
| double quality = 10 | The `quality` param specifies the quality of the generated thumbnails, from 0 to 100 ([more info](https://pub.dev/packages/video_thumbnail)) |
| double horizontalMargin = 0.0 | The `horizontalMargin` param specifies the horizontal space to set around the slider. It is important when the trim can be dragged (`controller.maxDuration` < `controller.videoDuration`) |
| Widget? child | The `child` param can be specify to display a widget below this one (e.g: TrimTimeline) |
| bool hasHaptic = true | The `hasHaptic` param specifies if haptic feed back can be triggered when the trim touch an edge (left or right) |
| double maxViewportRatioo = 2.5 | The `maxViewportRatio` param specifies the upper limit of the view ratio |
| ScrollController? scrollController | The `scrollController` param specifies the scroll controller to use for the trim slider view |

##### 2. TrimTimeline

Display the video timeline.

| Param                            | Description                       |
| -------------------------------- | --------------------------------- |
| required VideoEditorController controller | The `controller` param is mandatory so depending on the `controller.maxDuration`, the generated timeline will be different |
| double quantity = 8 | Expected `quantity` of elements shown in the timeline |
| EdgeInsets padding = EdgeInsets.zero | The `padding` param specifies the space surrounding the timeline |
| String localSeconds = 's' | The String to represents the seconds to show next to each timeline element |
| TextStyle? textStyle | The TextStyle to use to style the timeline text |

#### Cover
##### 1. CoverSelection

Display a couple of generated covers with rotation and crop parameters to updated the selected cover.

| Param                            | Description                       |
| -------------------------------- | --------------------------------- |
| required VideoEditorController controller | The `controller` param is mandatory so every change in the controller settings will propagate in the cover selection view |
| double size = 0.0 | The `size` param specifies the max size of the generated thumbnails |
| double quality = 10 | The `quality` param specifies the quality of the generated thumbnails, from 0 to 100 ([more info](https://pub.dev/packages/video_thumbnail)) |
| double horizontalMargin = 0.0 | The `horizontalMargin` param need to be specify when there is a margin outside the crop view, so in case of a change the new layout can be computed properly. |
| int quantity = 5 | The `quantity` param specifies the quantity of thumbnails to generate |
| Wrap? wrap | The `wrap` widget to use to customize the thumbnails wrapper |
| Function? selectedCoverBuilder | To returns how the selected cover should be displayed |

##### 2. CoverViewer

Display the selected cover with rotation and crop parameters.

| Param                            | Description                       |
| -------------------------------- | --------------------------------- |
| required VideoEditorController controller | The `controller` param is mandatory so every change in the controller settings will propagate the crop parameters in the cover view |
| String noCoverText = 'No selection' | The `noCoverText` param specifies the text to display when selectedCover is `null` |

</details>

### Style

<details>
  <summary>Click to expand style documentation</summary>

#### 1. CropStyle

You can create your own CropStyle class to customize the CropGridViewer appareance.

| Param                            | Description                       |
| -------------------------------- | --------------------------------- |
| Color croppingBackground = Colors.black.withOpacity(0.48) | The `croppingBackground` param specifies the color of the paint area outside the crop area when copping |
| Color background = Colors.black | The `background` param specifies the color of the paint area outside the crop area when not copping |
| double gridLineWidth = 1 | The `gridLineWidth` param specifies the width of the crop lines |
| Color gridLineColor = Colors.white | The `gridLineColor` param specifies the color of the crop lines |
| int gridSize = 3 | The `gridSize` param specifies the quantity of columns and rows in the crop view |
| Color boundariesColor = Colors.white | The `boundariesColor` param specifies the color of the crop area's corner |
| Color selectedBoundariesColor = kDefaultSelectedColor | The `selectedBoundariesColor` param specifies the color of the selected crop area's corner |
| double boundariesLength = 20 | The `boundariesLength` param specifies the length of the crop area's corner |
| double boundariesWidth = 5 | The `boundariesWidth` param specifies the width of the crop area's corner |

#### 2. TrimStyle

You can create your own TrimStyle class to customize the TrimSlider appareance.

| Param                            | Description                       |
| -------------------------------- | --------------------------------- |
| Color background = Colors.black.withOpacity(0.6) | The `background` param specifies the color of the paint area outside the trimmed area |
| Color positionLineColor = Colors.red | The `positionLineColor` param specifies the color of the line showing the video position |
| double positionLineWidth = 2 | The `positionLineWidth` param specifies the width  of the line showing the video position |
| Color lineColor = Colors.white | The `lineColor` param specifies the color of the borders around the trimmed area |
| Color onTrimmingColor = kDefaultSelectedColor | The `onTrimmingColor` param specifies the color of the borders around the trimmed area while it is getting trimmed |
| Color onTrimmedColor = kDefaultSelectedColor | The `onTrimmedColor` param specifies the color of the borders around the trimmed area when the trimmed parameters are not default values |
| double lineWidth = 2 | The `lineWidth` param specifies the width of the borders around the trimmed area |
| TrimSliderEdgesType borderRadius = 5 | The `borderRadius` param specifies the border radius around the trimmer |
| double edgesType = TrimSliderEdgesType.bar | The `edgesType` param specifies the style to apply to the edges (left & right) of the trimmer |
| double edgesSize | The `edgesSize` param specifies the size of the edges behind the icons |
| Color iconColor = Colors.black | The `iconColor` param specifies the color of the icons on the trimmed area's edges |
| double iconSize = 25 | The `iconSize` param specifies the size of the icon on the trimmed area's edges |
| IconData? leftIcon = Icons.arrow_left | The `leftIcon` param specifies the icon to show on the left edge of the trimmed area |
| IconData? rightIcon = Icons.arrow_right | The `rightIcon` param specifies the icon to show on the right edge of the trimmed area |

#### 3. CoverStyle

You can create your own CoverStyle class to customize the CoverSelection appareance.

| Param                            | Description                       |
| -------------------------------- | --------------------------------- |
| Color selectedBorderColor = Colors.white | The `selectedBorderColor` param specifies the color of the border around the selected cover thumbnail |
| double borderWidth = 2 | The `borderWidth` param specifies the width of the border around each cover thumbnails |
| double borderRadius = 5.0 | The `borderRadius` param specifies the border radius of each cover thumbnail |

</details>

## ✂ How to export video / cover images?

Since version `3.0.0`, you have complete control over the video / cover image export process. The `VideoEditorController`'s new methods, `createVideoFFmpegConfig` and `createCoverFFmpegConfig`, allow you to create your own ffmpeg configurations and export commands. This means that you can now choose your preferred ffmpeg library for iOS / Android, such as `ffmpeg_kit_flutter_min`, `ffmpeg_kit_flutter_min_gpl`, `ffmpeg_kit_flutter_full_gpl`, or `ffmpeg_kit_flutter_full`. For web platforms, you can choose `ffmpeg_wasm`. Alternatively, you can choose not to include any ffmpeg package to minimize your app's size, and instead delegate the exportation task to a webservice by passing the ffmpeg command to it.

<details>
  <summary>Example of how to export with the `ffmpeg_kit` package</summary>

```dart
import 'package:ffmpeg_kit_flutter_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/return_code.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/statistics.dart';

Future<XFile> executeFFmpegIO({
  required String execute,
  required String outputPath,
  String? outputMimeType,
  void Function(FFmpegStatistics)? onStatistics,
}) {
  final completer = Completer<XFile>();

  FFmpegKit.executeAsync(
    execute,
        (session) async {
      final code = await session.getReturnCode();

      if (ReturnCode.isSuccess(code)) {
        completer.complete(XFile(outputPath, mimeType: outputMimeType));
      } else {
        final state = FFmpegKitConfig.sessionStateToString(
          await session.getState(),
        );
        completer.completeError(
          Exception(
            'FFmpeg process exited with state $state and return code $code.'
                '${await session.getOutput()}',
          ),
        );
      }
    },
    null,
    onStatistics != null
        ? (s) => onStatistics(FFmpegStatistics.fromIOStatistics(s))
        : null,
  );

  return completer.future;
}
```

</details>

<details>
  <summary>Example of how to export with the `ffmpeg_wasm` package</summary>

```dart
import 'package:ffmpeg_wasm/ffmpeg_wasm.dart';

Future<XFile> executeFFmpegWeb({
  required String execute,
  required Uint8List inputData,
  required String inputPath,
  required String outputPath,
  String? outputMimeType,
  void Function(FFmpegStatistics)? onStatistics,
}) async {
  FFmpeg? ffmpeg;
  final logs = <String>[];
  try {
    ffmpeg = createFFmpeg(CreateFFmpegParam(log: false));
    ffmpeg.setLogger((LoggerParam logger) {
      logs.add('[${logger.type}] ${logger.message}');

      if (onStatistics != null && logger.type == 'fferr') {
        final statistics = FFmpegStatistics.fromMessage(logger.message);
        if (statistics != null) {
          onStatistics(statistics);
        }
      }
    });

    await ffmpeg.load();

    ffmpeg.writeFile(inputPath, inputData);
    await ffmpeg.runCommand(execute);

    final data = ffmpeg.readFile(outputPath);
    return XFile.fromData(data, mimeType: outputMimeType);
  } catch (e, s) {
    Error.throwWithStackTrace(
      Exception('Exception:\n$e\n\nLogs:${logs.join('\n')}}'),
      s,
    );
  } finally {
    ffmpeg?.exit();
  }
}
```

</details>

<details>
  <summary>Example of how to export video / cover images</summary>

```dart
Future<String> ioOutputPath(String filePath, FileFormat format) async {
  final tempPath = (await getTemporaryDirectory()).path;
  final name = path.basenameWithoutExtension(filePath);
  final epoch = DateTime.now().millisecondsSinceEpoch;
  return "$tempPath/${name}_$epoch.${format.extension}";
}

String _webPath(String prePath, FileFormat format) {
  final epoch = DateTime.now().millisecondsSinceEpoch;
  return '${prePath}_$epoch.${format.extension}';
}

String webInputPath(FileFormat format) => _webPath('input', format);

String webOutputPath(FileFormat format) => _webPath('output', format);

Future<XFile> exportVideo({
  void Function(FFmpegStatistics)? onStatistics,
  VideoExportFormat outputFormat = VideoExportFormat.mp4,
  double scale = 1.0,
  String customInstruction = '',
  VideoExportPreset preset = VideoExportPreset.none,
  bool isFiltersEnabled = true,
}) async {
  final inputPath = kIsWeb
      ? webInputPath(FileFormat.fromMimeType(_controller.file.mimeType))
      : _controller.file.path;
  final outputPath = kIsWeb
      ? webOutputPath(outputFormat)
      : await ioOutputPath(inputPath, outputFormat);

  final config = _controller.createVideoFFmpegConfig();
  final execute = config.createExportCommand(
    inputPath: inputPath,
    outputPath: outputPath,
    outputFormat: outputFormat,
    scale: scale,
    customInstruction: customInstruction,
    preset: preset,
    isFiltersEnabled: isFiltersEnabled,
  );

  debugPrint('run export video command : [$execute]');

  if (kIsWeb) {
    return executeFFmpegWeb(
      execute: execute,
      inputData: await _controller.file.readAsBytes(),
      inputPath: inputPath,
      outputPath: outputPath,
      outputMimeType: outputFormat.mimeType,
      onStatistics: onStatistics,
    );
  } else {
    return executeFFmpegIO(
      execute: execute,
      outputPath: outputPath,
      outputMimeType: outputFormat.mimeType,
      onStatistics: onStatistics,
    );
  }
}

Future<XFile> extractCover({
  void Function(FFmpegStatistics)? onStatistics,
  CoverExportFormat outputFormat = CoverExportFormat.jpg,
  double scale = 1.0,
  int quality = 100,
  bool isFiltersEnabled = true,
}) async {
  // file generated from the thumbnail library or video source
  final coverFile = await VideoThumbnail.thumbnailFile(
    imageFormat: ImageFormat.JPEG,
    thumbnailPath: kIsWeb ? null : (await getTemporaryDirectory()).path,
    video: _controller.file.path,
    timeMs: _controller.selectedCoverVal?.timeMs ??
        _controller.startTrim.inMilliseconds,
    quality: quality,
  );

  final inputPath = kIsWeb
      ? webInputPath(FileFormat.fromMimeType(_controller.file.mimeType))
      : coverFile.path;
  final outputPath = kIsWeb
      ? webOutputPath(outputFormat)
      : await ioOutputPath(coverFile.path, outputFormat);

  var config = _controller.createCoverFFmpegConfig();
  final execute = config.createExportCommand(
    inputPath: inputPath,
    outputPath: outputPath,
    scale: scale,
    quality: quality,
    isFiltersEnabled: isFiltersEnabled,
  );

  debugPrint('VideoEditor - run export cover command : [$execute]');

  if (kIsWeb) {
    return executeFFmpegWeb(
      execute: execute,
      inputData: await _controller.file.readAsBytes(),
      inputPath: inputPath,
      outputPath: outputPath,
      outputMimeType: outputFormat.mimeType,
    );
  } else {
    return executeFFmpegIO(
      execute: execute,
      outputPath: outputPath,
      outputMimeType: outputFormat.mimeType,
    );
  }
}

/// Common class for ffmpeg_kit and ffmpeg_wasm statistics.
class FFmpegStatistics {
  final int videoFrameNumber;
  final double videoFps;
  final double videoQuality;
  final int size;
  final int time;
  final double bitrate;
  final double speed;

  static final statisticsRegex = RegExp(
    r'frame\s*=\s*(\d+)\s+fps\s*=\s*(\d+(?:\.\d+)?)\s+q\s*=\s*([\d.-]+)\s+L?size\s*=\s*(\d+)\w*\s+time\s*=\s*([\d:.]+)\s+bitrate\s*=\s*([\d.]+)\s*(\w+)/s\s+speed\s*=\s*([\d.]+)x',
  );

  const FFmpegStatistics({
    required this.videoFrameNumber,
    required this.videoFps,
    required this.videoQuality,
    required this.size,
    required this.time,
    required this.bitrate,
    required this.speed,
  });

  FFmpegStatistics.fromIOStatistics(Statistics s)
      : this(
    videoFrameNumber: s.getVideoFrameNumber(),
    videoFps: s.getVideoFps(),
    videoQuality: s.getVideoQuality(),
    size: s.getSize(),
    time: s.getTime(),
    bitrate: s.getBitrate(),
    speed: s.getSpeed(),
  );

  static FFmpegStatistics? fromMessage(String message) {
    final match = statisticsRegex.firstMatch(message);
    if (match != null) {
      return FFmpegStatistics(
        videoFrameNumber: int.parse(match.group(1)!),
        videoFps: double.parse(match.group(2)!),
        videoQuality: double.parse(match.group(3)!),
        size: int.parse(match.group(4)!),
        time: _timeToMs(match.group(5)!),
        bitrate: double.parse(match.group(6)!),
        // final bitrateUnit = match.group(7);
        speed: double.parse(match.group(8)!),
      );
    }

    return null;
  }

  double getProgress(int videoDurationMs) {
    return videoDurationMs <= 0.0
        ? 0.0
        : (time / videoDurationMs).clamp(0.0, 1.0);
  }

  static int _timeToMs(String timeString) {
    final parts = timeString.split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    final secondsParts = parts[2].split('.');
    final seconds = int.parse(secondsParts[0]);
    final milliseconds = int.parse(secondsParts[1]);
    return ((hours * 60 * 60 + minutes * 60 + seconds) * 1000 + milliseconds);
  }
}
```

</details>

For more details check out the [example](https://github.com/LeGoffMael/video_editor/tree/master/example).

## ✨ Credit

Many thanks to [seel-channel](https://github.com/seel-channel) who is the original creator of this library.