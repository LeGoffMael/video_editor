import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:video_editor/src/controller.dart';
import 'package:video_editor/src/models/file_format.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class FFmpegVideoEditorExecute {
  const FFmpegVideoEditorExecute({
    required this.command,
    required this.outputPath,
    required this.filters,
  });

  final String command;
  final String outputPath;
  final String filters;
}

/// A preset is a collection of options that will provide a certain encoding speed to compression ratio.
///
/// A slower preset will provide better compression (compression is quality per filesize).
///
/// This means that, for example, if you target a certain file size or constant bit rate,
/// you will achieve better quality with a slower preset.
/// Similarly, for constant quality encoding,
/// you will simply save bitrate by choosing a slower preset.
enum VideoExportPreset {
  none,
  ultrafast,
  superfast,
  veryfast,
  faster,
  fast,
  medium,
  slow,
  slower,
  veryslow;

  const VideoExportPreset();

  /// Convert [VideoExportPreset] to ffmpeg preset as a [String], [More info about presets](https://trac.ffmpeg.org/wiki/Encode/H.264)
  ///
  /// Returns empty [String] for [VideoExportPreset.none]
  /// Or returns [String] in `-preset xxx` format
  String get cmd => this == VideoExportPreset.none ? '' : '-preset $name';
}

abstract class FFmpegVideoEditorConfig {
  final VideoEditorController controller;

  /// If the [name] is `null`, then it uses this video filename.
  final String? name;

  /// If the [outputDirectory] is `null`, then it uses `TemporaryDirectory`.
  final String? outputDirectory;

  /// The [scale] is `scale=width*scale:height*scale` and reduce or increase the file dimensions.
  /// Defaults to `false`.
  final double scale;

  /// Set [isFiltersEnabled] to `false` if you do not want to apply any changes.
  /// Defaults to `true`.
  final bool isFiltersEnabled;

  const FFmpegVideoEditorConfig(
    this.controller, {
    this.name,
    @protected this.outputDirectory,
    this.scale = 1.0,
    this.isFiltersEnabled = true,
  });

  /// Convert the controller's [minCrop] and [maxCrop] params into a [String]
  /// used to provide crop values to FFmpeg ([see more](https://ffmpeg.org/ffmpeg-filters.html#crop))
  ///
  /// The result is in the format `crop=w:h:x:y`
  String get cropCmd {
    if (controller.minCrop <= minOffset && controller.maxCrop >= maxOffset) {
      return "";
    }

    final enddx = controller.videoWidth * controller.maxCrop.dx;
    final enddy = controller.videoHeight * controller.maxCrop.dy;
    final startdx = controller.videoWidth * controller.minCrop.dx;
    final startdy = controller.videoHeight * controller.minCrop.dy;

    return "crop=${enddx - startdx}:${enddy - startdy}:$startdx:$startdy";
  }

  /// Convert the controller's [rotation] value into a [String]
  /// used to provide crop values to Ffmpeg ([see more](https://ffmpeg.org/ffmpeg-filters.html#transpose-1))
  ///
  /// The result is in the format `transpose=2` (repeated for every 90 degrees rotations)
  String get rotationCmd {
    final count = controller.rotation / 90;
    if (count <= 0 || count >= 4) return "";

    final List<String> transpose = [];
    for (int i = 0; i < controller.rotation / 90; i++) {
      transpose.add("transpose=2");
    }
    return transpose.isNotEmpty ? transpose.join(',') : "";
  }

  /// Returns the `-filter:v` command to use in ffmpeg execution
  String getExportFilters({VideoExportFormat? videoFormat}) {
    if (!isFiltersEnabled) return "";

    // CALCULATE FILTERS
    final bool isGif =
        videoFormat?.extension == VideoExportFormat.gif.extension;
    final String scaleCmd = scale == 1.0 ? "" : "scale=iw*$scale:ih*$scale";

    // VALIDATE FILTERS
    final List<String> filters = [
      cropCmd,
      scaleCmd,
      rotationCmd,
      isGif
          ? "fps=${videoFormat is GifExportFormat ? videoFormat.fps : VideoExportFormat.gif.fps}"
          : "",
    ];
    filters.removeWhere((item) => item.isEmpty);
    return filters.isNotEmpty
        ? "-vf '${filters.join(",")}'${isGif ? " -loop 0" : ""}"
        : "";
  }

  /// Returns the output path of the exported file
  Future<String> getOutputPath({
    required String filePath,
    required FileFormat format,
  }) async {
    final String tempPath =
        outputDirectory ?? (await getTemporaryDirectory()).path;
    final String n = name ?? path.basenameWithoutExtension(filePath);
    final int epoch = DateTime.now().millisecondsSinceEpoch;
    return "$tempPath/${n}_$epoch.${format.extension}";
  }

  /// Can be used from FFmpeg session callback, for example:
  /// ```dart
  /// FFmpegKitConfig.enableStatisticsCallback((stats) {
  ///   final progress = getFFmpegSessionProgress(stats.getTime());
  /// });
  /// ```
  /// Returns the [double] progress value between 0.0 and 1.0.
  double getFFmpegProgress(int time) {
    final double progressValue =
        time / controller.trimmedDuration.inMilliseconds;
    return progressValue.clamp(0.0, 1.0);
  }

  /// Returns the [FFmpegVideoEditorExecute] that contains the param to provide to FFmpeg.
  Future<FFmpegVideoEditorExecute?> getExecuteConfig();
}

class VideoFFmpegVideoEditorConfig extends FFmpegVideoEditorConfig {
  const VideoFFmpegVideoEditorConfig(
    super.controller, {
    super.name,
    super.outputDirectory,
    super.scale,
    super.isFiltersEnabled,
    this.format = VideoExportFormat.mp4,
    this.customInstruction,
    this.preset = VideoExportPreset.none,
  });

  /// The [format] of the video to be exported.
  /// You can export as a GIF file by using [VideoExportFormat.gif] or with
  /// [GifExportFormat()] which allows you to control the frame rate of the exported GIF file.
  ///
  /// Defaults to [VideoExportFormat.mp4].
  final VideoExportFormat format;

  /// The [customInstruction] param can be set to add custom commands to the FFmpeg eexecution
  /// (i.e. `-an` to mute the generated video), some commands require the GPL package
  final String? customInstruction;

  /// The [preset] is the `compress quality` **(Only available on GPL package)**.
  /// A slower preset will provide better compression (compression is quality per filesize).
  /// [More info about presets](https://trac.ffmpeg.org/wiki/Encode/H.264)
  ///
  /// Defaults to [VideoExportPreset.none].
  final VideoExportPreset preset;

  /// Returns the ffmpeg command to apply the controller's trim start and end parameters
  /// [see ffmpeg doc](https://trac.ffmpeg.org/wiki/Seeking#Cuttingsmallsections)
  String get trimCmd => "-ss ${controller.startTrim} -to ${controller.endTrim}";

  /// Returns a [FFmpegVideoEditorExecute] command to be executed with FFmpeg to export
  /// the video applying the editing parameters.
  @override
  Future<FFmpegVideoEditorExecute> getExecuteConfig() async {
    final String videoPath = controller.file.path;
    final String outputPath =
        await getOutputPath(filePath: videoPath, format: format);
    final String filters = getExportFilters(videoFormat: format);

    return FFmpegVideoEditorExecute(
      command:
          // ignore: unnecessary_string_escapes
          " -i \'$videoPath\' ${customInstruction ?? ""} $filters ${preset.cmd} $trimCmd -y \'$outputPath\'",
      outputPath: outputPath,
      filters: filters,
    );
  }
}

class CoverFFmpegVideoEditorConfig extends FFmpegVideoEditorConfig {
  const CoverFFmpegVideoEditorConfig(
    super.controller, {
    super.name,
    super.outputDirectory,
    super.scale,
    super.isFiltersEnabled,
    this.format = CoverExportFormat.jpg,
    this.quality = 100,
  });

  /// The [format] of the cover image to be exported.
  ///
  /// Defaults to [CoverExportFormat.jpg].
  final CoverExportFormat format;

  /// The [quality] of the exported image (from 0 to 100 ([more info](https://pub.dev/packages/video_thumbnail)))
  ///
  /// Defaults to `100`.
  final int quality;

  /// Generate this selected cover image as a JPEG [File]
  ///
  /// If this controller's [selectedCoverVal] is `null`, then it return the first frame of this video.
  Future<String?> _generateCoverFile() async => VideoThumbnail.thumbnailFile(
        imageFormat: ImageFormat.JPEG,
        thumbnailPath: (await getTemporaryDirectory()).path,
        video: controller.file.path,
        timeMs: controller.selectedCoverVal?.timeMs ??
            controller.startTrim.inMilliseconds,
        quality: quality,
      );

  /// Returns a [FFmpegVideoEditorExecute] command to be executed with FFmpeg to export
  /// the cover image applying the editing parameters.
  @override
  Future<FFmpegVideoEditorExecute?> getExecuteConfig() async {
    // file generated from the thumbnail library or video source
    final String? coverPath = await _generateCoverFile();
    if (coverPath == null) {
      debugPrint('VideoThumbnail library error while exporting the cover');
      return null;
    }
    final String outputPath =
        await getOutputPath(filePath: coverPath, format: format);
    final String filters = getExportFilters();

    return FFmpegVideoEditorExecute(
      // ignore: unnecessary_string_escapes
      command: "-i \'$coverPath\' $filters -y \'$outputPath\'",
      outputPath: outputPath,
      filters: filters,
    );
  }
}
