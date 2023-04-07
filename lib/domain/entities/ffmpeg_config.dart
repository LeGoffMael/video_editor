import 'package:video_editor/domain/bloc/controller.dart';
import 'package:video_editor/domain/entities/file_format.dart';

abstract class FFmpegConfig {
  const FFmpegConfig({
    required this.crop,
    required this.rotation,
  });

  /// Used to provide crop values to Ffmpeg ([see more](https://ffmpeg.org/ffmpeg-filters.html#crop))
  /// The result is in the format `crop=w:h:x:y`
  final String crop;

  /// FFmpeg crop value ([see more](https://ffmpeg.org/ffmpeg-filters.html#transpose-1))
  /// The result is in the format `transpose=2` (repeated for every 90 degrees rotations)
  final String rotation;

  /// Returns the `-filter:v` command to use in ffmpeg execution
  String getExportFilters({
    VideoExportFormat? videoFormat,
    double scale = 1.0,
    bool isFiltersEnabled = true,
  }) {
    if (!isFiltersEnabled) return "";

    // CALCULATE FILTERS
    final bool isGif =
        videoFormat?.extension == VideoExportFormat.gif.extension;
    final String scaleInstruction =
        scale == 1.0 ? "" : "scale=iw*$scale:ih*$scale";

    // VALIDATE FILTERS
    final filters = [
      crop,
      scaleInstruction,
      rotation,
      isGif
          ? "fps=${videoFormat is GifExportFormat ? videoFormat.fps : VideoExportFormat.gif.fps}"
          : "",
    ]..removeWhere((item) => item.isEmpty);

    return filters.isNotEmpty
        ? "-vf '${filters.join(",")}'${isGif ? " -loop 0" : ""}"
        : "";
  }
}

class VideoFFmpegConfig extends FFmpegConfig {
  const VideoFFmpegConfig({
    required this.trimCommand,
    required super.crop,
    required super.rotation,
  });

  /// ffmpeg command to apply the trim start and end parameters
  /// [see ffmpeg doc](https://trac.ffmpeg.org/wiki/Seeking#Cuttingsmallsections)
  final String trimCommand;

  /// Create an FFmpeg command string to export a video with the specified parameters.
  ///
  /// The [inputPath] specifies the location of the input video file to be exported.
  ///
  /// The [outputPath] specifies the path where the exported video file should be saved.
  ///
  /// The [format] of the video to be exported, by default [VideoExportFormat.mp4].
  /// You can export as a GIF file by using [VideoExportFormat.gif] or with
  /// [GifExportFormat()] which allows you to control the frame rate of the exported GIF file.
  ///
  /// The [scale] is `scale=width*scale:height*scale` and reduce or increase video size.
  ///
  /// The [customInstruction] param can be set to add custom commands to the FFmpeg eexecution
  /// (i.e. `-an` to mute the generated video), some commands require the GPL package
  ///
  /// The [preset] is the `compress quality` **(Only available on GPL package)**.
  /// A slower preset will provide better compression (compression is quality per filesize).
  /// [More info about presets](https://trac.ffmpeg.org/wiki/Encode/H.264)
  ///
  /// Set [isFiltersEnabled] to `false` if you do not want to apply any changes
  String createExportCommand({
    required String inputPath,
    required String outputPath,
    VideoExportFormat format = VideoExportFormat.mp4,
    double scale = 1.0,
    String customInstruction = '',
    VideoExportPreset preset = VideoExportPreset.none,
    bool isFiltersEnabled = true,
  }) {
    final filter = getExportFilters(
      videoFormat: format,
      scale: scale,
      isFiltersEnabled: isFiltersEnabled,
    );

    return "-i '$inputPath' $customInstruction $filter ${preset.ffmpegPreset} $trimCommand -y '$outputPath'";
  }
}

class CoverFFmpegConfig extends FFmpegConfig {
  CoverFFmpegConfig({
    required super.crop,
    required super.rotation,
  });

  /// Create an FFmpeg command string to export a cover image from the specified video.
  ///
  /// The [inputPath] specifies the location of the input video file to extract the cover image from.
  ///
  /// The [outputPath] specifies the path where the exported cover image file should be saved.
  ///
  /// The [scale] is `scale=width*scale:height*scale` and reduce or increase cover size.
  ///
  /// The [quality] of the exported image (from 0 to 100 ([more info](https://pub.dev/packages/video_thumbnail)))
  ///
  /// Set [isFiltersEnabled] to `false` if you do not want to apply any changes
  String createCoverExportCommand({
    required String inputPath,
    required String outputPath,
    double scale = 1.0,
    int quality = 100,
    bool isFiltersEnabled = true,
  }) {
    final filter = getExportFilters(
      scale: scale,
      isFiltersEnabled: isFiltersEnabled,
    );

    return "-i '$inputPath' $filter -y $outputPath";
  }
}
