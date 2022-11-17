import 'dart:io';
import 'package:ffmpeg_kit_flutter_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/return_code.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/statistics.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:video_editor/domain/helpers.dart';
import 'package:video_editor/domain/thumbnails.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';

import 'package:video_editor/domain/entities/crop_style.dart';
import 'package:video_editor/domain/entities/trim_style.dart';
import 'package:video_editor/domain/entities/cover_style.dart';
import 'package:video_editor/domain/entities/cover_data.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

enum RotateDirection { left, right }

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
  veryslow
}

/// The default value of this property `Offset(1.0, 1.0)`
const Offset _max = Offset(1.0, 1.0);

/// The default value of this property `Offset.zero`
const Offset _min = Offset.zero;

/// Provides an easy way to change edition parameters to apply in the different widgets of the package and at the exportion
/// This controller allows to : rotate, crop, trim, cover generation and exportation (video and cover)
class VideoEditorController extends ChangeNotifier {
  /// Style for [TrimSlider]
  final TrimSliderStyle trimStyle;

  /// Style for [CoverSelection]
  final CoverSelectionStyle coverStyle;

  /// Style for [CropGridViewer]
  final CropGridStyle cropStyle;

  /// Video from [File].
  final File file;

  /// Constructs a [VideoEditorController] that edits a video from a file.
  ///
  /// The [file] argument must not be null.
  VideoEditorController.file(
    this.file, {
    Duration? maxDuration,
    TrimSliderStyle? trimStyle,
    CoverSelectionStyle? coverStyle,
    CropGridStyle? cropStyle,
  })  : _video = VideoPlayerController.file(File(
          // https://github.com/flutter/flutter/issues/40429#issuecomment-549746165
          Platform.isIOS ? Uri.encodeFull(file.path) : file.path,
        )),
        _maxDuration = maxDuration ?? Duration.zero,
        cropStyle = cropStyle ?? const CropGridStyle(),
        coverStyle = coverStyle ?? const CoverSelectionStyle(),
        trimStyle = trimStyle ?? TrimSliderStyle();

  int _rotation = 0;
  bool _isTrimming = false;
  bool _isTrimmed = false;
  bool isCropping = false;

  double? _preferredCropAspectRatio;

  double _minTrim = _min.dx;
  double _maxTrim = _max.dx;

  Offset _minCrop = _min;
  Offset _maxCrop = _max;

  Offset cacheMinCrop = _min;
  Offset cacheMaxCrop = _max;

  Duration _trimEnd = Duration.zero;
  Duration _trimStart = Duration.zero;
  final VideoPlayerController _video;

  /// The max duration to trim the [file] video
  Duration _maxDuration;

  // Selected cover value
  final ValueNotifier<CoverData?> _selectedCover =
      ValueNotifier<CoverData?>(null);

  /// This is the width of the [file] video
  double _videoWidth = 0;

  /// This is the heigth of the [file] video
  double _videoHeight = 0;

  /// Get the [VideoPlayerController]
  VideoPlayerController get video => _video;

  /// Get the rotation of the video
  int get rotation => _rotation;

  /// Get the [VideoPlayerController.value.initialized]
  bool get initialized => _video.value.isInitialized;

  /// Get the [VideoPlayerController.value.isPlaying]
  bool get isPlaying => _video.value.isPlaying;

  /// Get the [VideoPlayerController.value.position]
  Duration get videoPosition => _video.value.position;

  /// Get the [VideoPlayerController.value.duration]
  Duration get videoDuration => _video.value.duration;

  /// Get the [Size] of the video
  Size get videoDimension =>
      Size(_videoWidth.toDouble(), _videoHeight.toDouble());

  /// The [minTrim] param is the minimum position of the trimmed area on the slider
  ///
  /// The minimum value of this param is `0.0`
  /// The maximum value of this param is [maxTrim]
  double get minTrim => _minTrim;
  set minTrim(double value) {
    if (value >= _min.dx && value <= _max.dx) {
      _minTrim = value;
      _updateTrimRange();
    }
  }

  /// The [maxTrim] param is the maximum position of the trimmed area on the slider
  ///
  /// The minimum value of this param is [minTrim]
  /// The maximum value of this param is `1.0`
  double get maxTrim => _maxTrim;
  set maxTrim(double value) {
    if (value >= _min.dx && value <= _max.dx) {
      _maxTrim = value;
      _updateTrimRange();
    }
  }

  /// The [startTrim] param is the maximum position of the trimmed area in video position in [Duration] value
  Duration get startTrim => _trimStart;

  /// The [endTrim] param is the maximum position of the trimmed area in video position in [Duration] value
  Duration get endTrim => _trimEnd;

  /// The [minCrop] param is the [Rect.topLeft] position of the crop area
  ///
  /// The minimum value of this param is `0.0`
  /// The maximum value of this param is `1.0`
  Offset get minCrop => _minCrop;
  set minCrop(Offset value) {
    if (value >= _min && value <= _max) {
      _minCrop = value;
      notifyListeners();
    }
  }

  /// The [maxCrop] param is the [Rect.bottomRight] position of the crop area
  ///
  /// The minimum value of this param is `0.0`
  /// The maximum value of this param is `1.0`
  Offset get maxCrop => _maxCrop;
  set maxCrop(Offset value) {
    if (value >= _min && value <= _max) {
      _maxCrop = value;
      notifyListeners();
    }
  }

  /// The [preferredCropAspectRatio] param is the selected aspect ratio (9:16, 3:4, 1:1, ...)
  double? get preferredCropAspectRatio => _preferredCropAspectRatio;
  set preferredCropAspectRatio(double? value) {
    if (preferredCropAspectRatio == value) return;
    _preferredCropAspectRatio = value;
    notifyListeners();
  }

  /// Update the [preferredCropAspectRatio] param and init/reset crop parameters [minCrop] & [maxCrop] to match the desired ratio
  /// The crop area will be at the center of the layout
  void cropAspectRatio(double? value) {
    preferredCropAspectRatio = value;

    if (value != null) {
      final newSize =
          computeSizeWithRatio(Size(_videoWidth, _videoHeight), value);

      Rect centerCrop = Rect.fromCenter(
        center: Offset(_videoWidth / 2, _videoHeight / 2),
        width: newSize.width,
        height: newSize.height,
      );

      minCrop =
          Offset(centerCrop.left / _videoWidth, centerCrop.top / _videoHeight);
      maxCrop = Offset(
          centerCrop.right / _videoWidth, centerCrop.bottom / _videoHeight);
      notifyListeners();
    }
  }

  //----------------//
  //VIDEO CONTROLLER//
  //----------------//

  /// Attempts to open the given video [File] and load metadata about the video.
  /// Update the trim position depending on the [maxDuration] param
  /// Generate the default cover [_selectedCover]
  /// Initialize [minCrop] & [maxCrop] values based on [aspectRatio]
  Future<void> initialize({double? aspectRatio}) async {
    await _video.initialize().then((_) {
      _videoWidth = _video.value.size.width;
      _videoHeight = _video.value.size.height;
    });
    _video.addListener(_videoListener);
    _video.setLooping(true);

    // if no [maxDuration] param given, maxDuration is the videoDuration
    _maxDuration = _maxDuration == Duration.zero ? videoDuration : _maxDuration;

    // Trim straight away when maxDuration is lower than video duration
    if (_maxDuration < videoDuration) {
      updateTrim(
          0.0, _maxDuration.inMilliseconds / videoDuration.inMilliseconds);
    } else {
      _updateTrimRange();
    }

    cropAspectRatio(aspectRatio);
    generateDefaultCoverThumbnail();

    notifyListeners();
  }

  @override
  Future<void> dispose() async {
    if (_video.value.isPlaying) await _video.pause();
    _video.removeListener(_videoListener);
    final executions = await FFmpegKit.listSessions();
    if (executions.isNotEmpty) await FFmpegKit.cancel();
    _video.dispose();
    _selectedCover.dispose();
    super.dispose();
  }

  void _videoListener() {
    final position = videoPosition;
    if (position < _trimStart || position >= _trimEnd) {
      _video.seekTo(_trimStart);
    }
  }

  //----------//
  //VIDEO CROP//
  //----------//

  /// Convert the [minCrop] and [maxCrop] param in to a [String]
  /// used to provide crop values to Ffmpeg ([see more](https://ffmpeg.org/ffmpeg-filters.html#crop))
  ///
  /// The result is in the format `crop=w:h:x,y`
  String _getCrop() {
    int enddx = (_videoWidth * maxCrop.dx).floor();
    int enddy = (_videoHeight * maxCrop.dy).floor();
    int startdx = (_videoWidth * minCrop.dx).floor();
    int startdy = (_videoHeight * minCrop.dy).floor();

    if (enddx > _videoWidth) enddx = _videoWidth.floor();
    if (enddy > _videoHeight) enddy = _videoHeight.floor();
    if (startdx < 0) startdx = 0;
    if (startdy < 0) startdy = 0;
    return "crop=${enddx - startdx}:${enddy - startdy}:$startdx:$startdy";
  }

  /// Update the [minCrop] and [maxCrop] with [cacheMinCrop] and [cacheMaxCrop]
  void updateCrop() {
    minCrop = cacheMinCrop;
    maxCrop = cacheMaxCrop;
  }

  //----------//
  //VIDEO TRIM//
  //----------//

  /// Update [minTrim] and [maxTrim].
  ///
  /// Arguments range are `0.0` to `1.0`.
  void updateTrim(double min, double max) {
    _minTrim = min;
    _maxTrim = max;
    _updateTrimRange();
    notifyListeners();
  }

  void _updateTrimRange() {
    final duration = videoDuration;
    _trimStart = duration * minTrim;
    _trimEnd = duration * maxTrim;

    if (_trimStart != Duration.zero || _trimEnd != videoDuration) {
      _isTrimmed = true;
    } else {
      _isTrimmed = false;
    }

    _checkUpdateDefaultCover();

    notifyListeners();
  }

  /// Get the [isTrimmed]
  ///
  /// `true` if the trimmed value has beem changed
  bool get isTrimmed => _isTrimmed;

  /// Get the [isTrimming]
  ///
  /// `true` if the trimming values are curently getting updated
  bool get isTrimming => _isTrimming;
  set isTrimming(bool value) {
    _isTrimming = value;
    notifyListeners();
  }

  /// Get the [maxDuration] param
  ///
  /// if no [maxDuration] param given in VideoEditorController constructor, maxDuration is equal to the videoDuration
  Duration get maxDuration => _maxDuration;

  /// Get the [trimPosition], which is the videoPosition in the trim slider
  ///
  /// Range of the param is `0.0` to `1.0`.
  double get trimPosition =>
      videoPosition.inMilliseconds / videoDuration.inMilliseconds;

  //-----------//
  //VIDEO COVER//
  //-----------//

  /// Replace selected cover by [selectedCover]
  void updateSelectedCover(CoverData selectedCover) async {
    _selectedCover.value = selectedCover;
  }

  /// Init selected cover value at initialization or after trimming change
  ///
  /// If [isTrimming] is `false` or  [_selectedCover] is `null`, update _selectedCover
  /// Update only milliseconds time for performance reason
  void _checkUpdateDefaultCover() {
    if (!_isTrimming || _selectedCover.value == null) {
      updateSelectedCover(CoverData(timeMs: startTrim.inMilliseconds));
    }
  }

  /// Generate cover at [startTrim] time in milliseconds
  void generateDefaultCoverThumbnail() async {
    final defaultCover = await generateSingleCoverThumbnail(
      file.path,
      timeMs: startTrim.inMilliseconds,
    );
    updateSelectedCover(defaultCover);
  }

  /// Get the [selectedCover] notifier
  ValueNotifier<CoverData?> get selectedCoverNotifier => _selectedCover;

  /// Get the [selectedCover] value
  CoverData? get selectedCoverVal => _selectedCover.value;

  //------------//
  //VIDEO ROTATE//
  //------------//

  /// Rotate the video by 90 degrees in the [direction] provided
  void rotate90Degrees([RotateDirection direction = RotateDirection.right]) {
    switch (direction) {
      case RotateDirection.left:
        _rotation += 90;
        if (_rotation >= 360) _rotation = _rotation - 360;
        break;
      case RotateDirection.right:
        _rotation -= 90;
        if (_rotation <= 0) _rotation = 360 + _rotation;
        break;
    }
    notifyListeners();
  }

  bool get isRotated => rotation == 90 || rotation == 270;

  /// Convert the [_rotation] value into a [String]
  /// used to provide crop values to Ffmpeg ([see more](https://ffmpeg.org/ffmpeg-filters.html#transpose-1))
  ///
  /// The result is in the format `transpose=2` (repeated for every 90 degrees rotations)
  String _getRotation() {
    List<String> transpose = [];
    for (int i = 0; i < _rotation / 90; i++) {
      transpose.add("transpose=2");
    }
    return transpose.isNotEmpty ? transpose.join(',') : "";
  }

  //--------------//
  //VIDEO METADATA//
  //--------------//

  /// Return the metadata of the video [file] using Ffprobe
  Future<void> getMetaData(
      {required void Function(Map<dynamic, dynamic>? metadata)
          onCompleted}) async {
    await FFprobeKit.getMediaInformationAsync(file.path, (session) async {
      final information = session.getMediaInformation();
      onCompleted(information?.getAllProperties());
    });
  }

  //------------//
  //VIDEO EXPORT//
  //------------//

  /// Export the video using this edition parameters and return a `File`.
  ///
  /// The [onCompleted] param must be set to return the exported [File] video.
  ///
  /// The [onError] function provides the [Exception] and [StackTrace] that causes the exportation error.
  ///
  /// If the [name] is `null`, then it uses this video filename.
  ///
  /// If the [outDir] is `null`, then it uses `TemporaryDirectory`.
  ///
  /// The [format] of the video to be exported, by default `mp4`.
  ///
  /// The [scale] is `scale=width*scale:height*scale` and reduce or increase video size.
  ///
  /// The [customInstruction] param can be set to add custom commands to the FFmpeg eexecution
  /// (i.e. `-an` to mute the generated video), some commands require the GPL package
  ///
  /// The [onProgress] is called while the video is exporting.
  /// This argument is usually used to update the export progress percentage.
  /// This function return [Statistics] from FFmpeg session and the [double] progress value between 0.0 and 1.0.
  ///
  /// The [preset] is the `compress quality` **(Only available on GPL package)**.
  /// A slower preset will provide better compression (compression is quality per filesize).
  /// [More info about presets](https://trac.ffmpeg.org/wiki/Encode/H.264)
  ///
  /// Set [isFiltersEnabled] to `false` if you do not want to apply any changes
  Future<void> exportVideo({
    required void Function(File file) onCompleted,
    void Function(Object, StackTrace)? onError,
    String? name,
    String? outDir,
    String format = "mp4",
    double scale = 1.0,
    String? customInstruction,
    void Function(Statistics, double)? onProgress,
    VideoExportPreset preset = VideoExportPreset.none,
    bool isFiltersEnabled = true,
  }) async {
    final String tempPath = outDir ?? (await getTemporaryDirectory()).path;
    final String videoPath = file.path;
    name ??= path.basenameWithoutExtension(videoPath);
    final int epoch = DateTime.now().millisecondsSinceEpoch;
    final String outputPath = "$tempPath/${name}_$epoch.$format";

    // CALCULATE FILTERS
    final String gif = format != "gif" ? "" : "fps=10 -loop 0";
    final String trim = minTrim >= _min.dx && maxTrim <= _max.dx
        ? "-ss $_trimStart -to $_trimEnd"
        : "";
    final String crop = minCrop >= _min && maxCrop <= _max ? _getCrop() : "";
    final String rotation =
        _rotation >= 360 || _rotation <= 0 ? "" : _getRotation();
    final String scaleInstruction =
        scale == 1.0 ? "" : "scale=iw*$scale:ih*$scale";

    // VALIDATE FILTERS
    final List<String> filters = [crop, scaleInstruction, rotation, gif];
    filters.removeWhere((item) => item.isEmpty);
    final String filter = filters.isNotEmpty && isFiltersEnabled
        ? "-filter:v ${filters.join(",")}"
        : "";
    final String execute =
        // ignore: unnecessary_string_escapes
        " -i \'$videoPath\' ${customInstruction ?? ""} $filter ${_getPreset(preset)} $trim -y \"$outputPath\"";

    // PROGRESS CALLBACKS
    FFmpegKit.executeAsync(
      execute,
      (session) async {
        final state =
            FFmpegKitConfig.sessionStateToString(await session.getState());
        final code = await session.getReturnCode();

        if (ReturnCode.isSuccess(code)) {
          onCompleted(File(outputPath));
        } else {
          if (onError != null) {
            onError(
              Exception(
                  'FFmpeg process exited with state $state and return code $code.\n${await session.getOutput()}'),
              StackTrace.current,
            );
          }
          return;
        }
      },
      null,
      onProgress != null
          ? (stats) {
              // Progress value of encoded video
              double progressValue =
                  stats.getTime() / (_trimEnd - _trimStart).inMilliseconds;
              onProgress(stats, progressValue.clamp(0.0, 1.0));
            }
          : null,
    );
  }

  /// Convert [VideoExportPreset] to ffmpeg preset as a [String], [More info about presets](https://trac.ffmpeg.org/wiki/Encode/H.264)
  ///
  /// Return [String] in `-preset xxx` format
  String _getPreset(VideoExportPreset preset) {
    String? newPreset = "";

    switch (preset) {
      case VideoExportPreset.ultrafast:
        newPreset = "ultrafast";
        break;
      case VideoExportPreset.superfast:
        newPreset = "superfast";
        break;
      case VideoExportPreset.veryfast:
        newPreset = "veryfast";
        break;
      case VideoExportPreset.faster:
        newPreset = "faster";
        break;
      case VideoExportPreset.fast:
        newPreset = "fast";
        break;
      case VideoExportPreset.medium:
        newPreset = "medium";
        break;
      case VideoExportPreset.slow:
        newPreset = "slow";
        break;
      case VideoExportPreset.slower:
        newPreset = "slower";
        break;
      case VideoExportPreset.veryslow:
        newPreset = "veryslow";
        break;
      case VideoExportPreset.none:
        newPreset = "";
        break;
    }

    return newPreset.isEmpty ? "" : "-preset $newPreset";
  }

  //------------//
  //COVER EXPORT//
  //------------//

  /// Generate this selected cover image as a JPEG [File]
  ///
  /// If this [selectedCoverVal] is `null`, then it return the first frame of this video.
  ///
  /// The [quality] param specifies the quality of the generated cover, from 0 to 100 (([more info](https://pub.dev/packages/video_thumbnail)))
  Future<String?> _generateCoverFile({int quality = 100}) async {
    return await VideoThumbnail.thumbnailFile(
      imageFormat: ImageFormat.JPEG,
      thumbnailPath: (await getTemporaryDirectory()).path,
      video: file.path,
      timeMs: selectedCoverVal?.timeMs ?? startTrim.inMilliseconds,
      quality: quality,
    );
  }

  /// Export this selected cover, or by default the first one, return an image [File].
  ///
  /// The [onCompleted] param must be set to return the exported [File] cover
  ///
  /// The [onError] function provides the [Exception] and [StackTrace] that causes the exportation error.
  ///
  /// If the [name] is `null`, then it uses this video filename.
  ///
  /// If the [outDir] is `null`, then it uses [TemporaryDirectory].
  ///
  /// The [format] of the image to be exported, by default `jpg`.
  ///
  /// The [scale] is `scale=width*scale:height*scale` and reduce or increase cover size.
  ///
  /// The [quality] of the exported image (from 0 to 100 ([more info](https://pub.dev/packages/video_thumbnail)))
  ///
  /// The [onProgress] is called while the video is exporting.
  /// This argument is usually used to update the export progress percentage.
  /// This function return [Statistics] from FFmpeg session.
  ///
  /// Set [isFiltersEnabled] to `false` if you do not want to apply any changes
  Future<void> extractCover({
    required void Function(File file) onCompleted,
    void Function(Object, StackTrace)? onError,
    String? name,
    String? outDir,
    String format = "jpg",
    double scale = 1.0,
    int quality = 100,
    void Function(Statistics)? onProgress,
    bool isFiltersEnabled = true,
  }) async {
    final String tempPath = outDir ?? (await getTemporaryDirectory()).path;
    // file generated from the thumbnail library or video source
    final String? coverPath = await _generateCoverFile(quality: quality);
    if (coverPath == null) {
      if (onError != null) {
        onError(
          Exception('VideoThumbnail library error while exporting the cover'),
          StackTrace.current,
        );
      }
      return;
    }
    name ??= path.basenameWithoutExtension(file.path);
    final int epoch = DateTime.now().millisecondsSinceEpoch;
    final String outputPath = "$tempPath/${name}_$epoch.$format";

    // CALCULATE FILTERS
    final String crop = minCrop >= _min && maxCrop <= _max ? _getCrop() : "";
    final String rotation =
        _rotation >= 360 || _rotation <= 0 ? "" : _getRotation();
    final String scaleInstruction =
        scale == 1.0 ? "" : "scale=iw*$scale:ih*$scale";

    // VALIDATE FILTERS
    final List<String> filters = [crop, scaleInstruction, rotation];
    filters.removeWhere((item) => item.isEmpty);
    final String filter = filters.isNotEmpty && isFiltersEnabled
        ? "-filter:v ${filters.join(",")}"
        : "";
    // ignore: unnecessary_string_escapes
    final String execute = "-i \'$coverPath\' $filter -y $outputPath";

    // PROGRESS CALLBACKS
    FFmpegKit.executeAsync(
      execute,
      (session) async {
        final state =
            FFmpegKitConfig.sessionStateToString(await session.getState());
        final code = await session.getReturnCode();

        if (ReturnCode.isSuccess(code)) {
          onCompleted(File(outputPath));
        } else {
          if (onError != null) {
            onError(
              Exception(
                  'FFmpeg process exited with state $state and return code $code.\n${await session.getOutput()}'),
              StackTrace.current,
            );
          }
          return;
        }
      },
      null,
      onProgress,
    );
  }
}
