import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffmpeg_kit_flutter_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/media_information_session.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/statistics.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
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

  /// Below this limit bitrate compression will not trigger
  final int? _cappedVideoBitRate;

  /// Below this limit bitrate compression will not trigger
  final int? _cappedAudioBitRate;

  /// This will limit the file size
  final int? _cappedOutputVideoSize;

  Size croppedDimensions = const Size(0, 0);

  /// Constructs a [VideoEditorController] that edits a video from a file.
  ///
  /// The [file] argument must not be null.
  VideoEditorController.file(
    this.file, {
    Duration? maxDuration,
    TrimSliderStyle? trimStyle,
    CoverSelectionStyle? coverStyle,
    CropGridStyle? cropStyle,

    /// 1000000 ie 1000kbps
    int? cappedVideoBitRate,

    /// 128000 ie 128kbps
    int? cappedAudioBitRate,

    /// 16777216 bytes ie. 16MB
    int? cappedOutputVideoSize,
  })  : _video = VideoPlayerController.file(file),
        _maxDuration = maxDuration ?? Duration.zero,
        cropStyle = cropStyle ?? CropGridStyle(),
        coverStyle = coverStyle ?? CoverSelectionStyle(),
        _cappedVideoBitRate = cappedVideoBitRate,
        _cappedAudioBitRate = cappedAudioBitRate,
        _cappedOutputVideoSize = cappedOutputVideoSize,
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

  int? currentAudioBitRate;
  int? currentVideoBitRate;

  int? effectiveAudioBitRate;
  int? effectiveVideoBitRate;

  Duration _trimEnd = Duration.zero;
  Duration _trimStart = Duration.zero;
  final VideoPlayerController _video;

  /// The max duration to trim the [file] video
  Duration _maxDuration;

  // Selected cover value
  final ValueNotifier<CoverData?> _selectedCover =
      ValueNotifier<CoverData?>(null);

  ValueNotifier<int?> estimatedOutputSize = ValueNotifier<int?>(null);

  /// Mute audio or remove audio from video
  ValueNotifier<bool> muteAudio = ValueNotifier<bool>(false);

  /// Duration of video with/without trimming
  ValueNotifier<Duration> trimmedDuration =
      ValueNotifier<Duration>(Duration.zero);

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

  //----------------//
  //VIDEO CONTROLLER//
  //----------------//

  /// Attempts to open the given video [File] and load metadata about the video.
  /// Update the trim position depending on the [maxDuration] param
  /// Generate the default cover [_selectedCover]
  Future<void> initialize() async {
    await _video.initialize();
    _videoWidth = _video.value.size.width;
    _videoHeight = _video.value.size.height;
    croppedDimensions = Size(_videoWidth, _videoHeight);

    /// Fetch current bitrates
    await _setCurrentBitRates();
    _video.addListener(_videoListener);
    _video.setLooping(true);

    updateMaxDuration();
  }

  updateMaxDuration() {
    /// If max output video size is not null calculate max duration according to total bitrates, if total bitrate is not possible to calculate then fall back to maxDuration value
    if (_cappedOutputVideoSize != null) {
      if ((effectiveAudioBitRate != null) || (effectiveVideoBitRate != null)) {
        int totalBitrate = effectiveVideoBitRate ?? 0;
        if (muteAudio.value == false) {
          totalBitrate += (effectiveAudioBitRate ?? 0);
        }
        //log("==> total bitrate : $totalBitrate bps");

        /// max possible duration will be bitrate/8 we will get bytes in 1 second then divide max output video size my it
        Duration maxPossibleDuration =
            Duration(seconds: (_cappedOutputVideoSize! * 8) ~/ totalBitrate);
        //log("==> max possible duration : ${maxPossibleDuration.inSeconds} seconds");

        if (maxPossibleDuration >= videoDuration) {
          _maxDuration = videoDuration;
        } else {
          _maxDuration = maxPossibleDuration;
        }
      } else {
        // if no [maxDuration] param given, maxDuration is the videoDuration
        _maxDuration =
            _maxDuration == Duration.zero ? videoDuration : _maxDuration;
      }
    } else {
      // if no [maxDuration] param given, maxDuration is the videoDuration
      _maxDuration =
          _maxDuration == Duration.zero ? videoDuration : _maxDuration;
    }
    //log("==> max allowed duration : ${_maxDuration.inSeconds} seconds");
    // Trim straight away when maxDuration is lower than video duration
    if (_maxDuration < videoDuration) {
      updateTrim(
          0.0, _maxDuration.inMilliseconds / videoDuration.inMilliseconds);
    } else {
      _updateTrimRange();
    }

    generateDefaultCoverThumbnail();

    notifyListeners();
  }

  /// Return metadata of the video file
  Future<void> getMetaData(
    String filePath, {
    required Function(Map<dynamic, dynamic>? metadata) onCompleted,
  }) async {
    await FFprobeKit.getMediaInformationAsync(filePath,
        (MediaInformationSession session) async {
      final information = (session).getMediaInformation();
      onCompleted.call(information?.getAllProperties());
    });
  }

  _setCurrentBitRates() async {
    Completer completer = Completer();
    getMetaData(
      file.path,
      onCompleted: (Map<dynamic, dynamic>? metadata) {
        //log(metadata.toString());
        if (metadata != null) {
          int abr = 0;
          int vbr = 0;
          for (var item in metadata['streams']) {
            // A video can have multiple
            if (item['codec_type'] == 'audio') {
              if (item['bit_rate'] != null) {
                abr = abr + int.parse(item['bit_rate']);
              }
            } else if (item['codec_type'] == 'video') {
              if (item['bit_rate'] != null) {
                vbr = vbr + int.parse(item['bit_rate']);
              }
            }
          }
          if (abr != 0) {
            //log('==> current audio bit rate : $abr bps');
            // Current bitrate of audio track
            currentAudioBitRate = abr;
            // If capped bitrate is not null then compare wheather the current bitrate is greater than capped.
            // If current bitrate exceeds capped bitrate then set effective bitrate to be capped otherwise set it to current bitrate to avoid processing on that track.
            //log('==> capped audio bit rate : $_cappedAudioBitRate bps');
            if (_cappedAudioBitRate != null) {
              if (currentAudioBitRate! > _cappedAudioBitRate!) {
                // Downgrade bitrate on export
                effectiveAudioBitRate = _cappedAudioBitRate;
              } else {
                effectiveAudioBitRate = currentAudioBitRate;
              }
            } else {
              effectiveAudioBitRate = currentAudioBitRate;
            }
          } else {
            effectiveAudioBitRate = null;
          }
          //log('==> effective audio bit rate : $effectiveAudioBitRate bps');
          if (vbr != 0) {
            //log('==> current video bit rate : $vbr bps');
            currentVideoBitRate = vbr;
            // If capped bitrate is not null then compare wheather the current bitrate is greater than capped.
            // If current bitrate exceeds capped bitrate then set effective bitrate to be capped otherwise set it to current bitrate to avoid processing on that track.
            //log('==> capped video bit rate : $_cappedVideoBitRate bps');
            if (_cappedVideoBitRate != null) {
              if (currentVideoBitRate! > _cappedVideoBitRate!) {
                // Downgrade bitrate on export
                effectiveVideoBitRate = _cappedVideoBitRate;
              } else {
                effectiveVideoBitRate = currentVideoBitRate;
              }
            } else {
              effectiveVideoBitRate = currentVideoBitRate;
            }
          } else {
            effectiveVideoBitRate = null;
          }
          //log('==> effective video bit rate : $effectiveVideoBitRate bps');
        } else {
          //log("==> bitrates not found");
          effectiveAudioBitRate = null;
          effectiveVideoBitRate = null;
        }
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      },
    );
    return completer.future;
  }

  //
  @override
  Future<void> dispose() async {
    if (_video.value.isPlaying) await _video.pause();
    _video.removeListener(_videoListener);
    final executions = await FFmpegKit.listSessions();
    if (executions.isNotEmpty) await FFmpegKit.cancel();
    _video.dispose();
    _selectedCover.dispose();
    estimatedOutputSize.dispose();
    trimmedDuration.dispose();
    muteAudio.dispose();
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
  Future<String> _getCrop() async {
    int enddx = (_videoWidth * maxCrop.dx).floor();
    int enddy = (_videoHeight * maxCrop.dy).floor();
    int startdx = (_videoWidth * minCrop.dx).floor();
    int startdy = (_videoHeight * minCrop.dy).floor();

    if (enddx > _videoWidth) enddx = _videoWidth.floor();
    if (enddy > _videoHeight) enddy = _videoHeight.floor();
    if (startdx < 0) startdx = 0;
    if (startdy < 0) startdy = 0;

    croppedDimensions =
        Size((enddx - startdx).toDouble(), (enddy - startdy).toDouble());

    return "crop=${enddx - startdx}:${enddy - startdy}:$startdx:$startdy";
  }

  /// Update the [minCrop] and [maxCrop] with [cacheMinCrop] and [cacheMaxCrop]
  void updateCrop() {
    minCrop = cacheMinCrop;
    maxCrop = cacheMaxCrop;
    // Update croppedDimensions variable
    _getCrop();
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
    trimmedDuration.value = _trimEnd - _trimStart;
    updateEstimatedOutputFileSize(trimmedDuration.value);
    _checkUpdateDefaultCover();

    notifyListeners();
  }

  /// Toggle mute
  set toggleMuteAudio(bool mute) {
    //estimatedOutputSize
    muteAudio.value = mute;
    updateMaxDuration();
    updateEstimatedOutputFileSize(trimmedDuration.value);
  }

  /// Update estimated output file size to show value as widget, null means cannot be determined and non null value is in bytes.
  updateEstimatedOutputFileSize(Duration trimmedLength) {
    if ((effectiveAudioBitRate != null) || (effectiveVideoBitRate != null)) {
      int totalBitrate = effectiveVideoBitRate ?? 0;
      if (muteAudio.value == false) {
        totalBitrate += effectiveAudioBitRate ?? 0;
      }
      estimatedOutputSize.value = (trimmedLength.inSeconds * totalBitrate) ~/ 8;
    } else {
      estimatedOutputSize.value = null;
    }
  }

  /// Get the [isTrimmed]
  ///
  /// `true` if the trimmed value has beem changed
  bool get isTrimmmed => _isTrimmed;

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
    final defaultCover =
        await generateCoverThumbnail(timeMs: startTrim.inMilliseconds);
    updateSelectedCover(defaultCover);
  }

  /// Generate a cover at [timeMs] in video
  ///
  /// return [CoverData] depending on [timeMs] milliseconds
  Future<CoverData> generateCoverThumbnail(
      {int timeMs = 0, int quality = 10}) async {
    print('cover thumbnails generating');
    final Uint8List? thumbData = await VideoThumbnail.thumbnailData(
      imageFormat: ImageFormat.JPEG,
      video: file.path,
      timeMs: timeMs,
      quality: quality,
    );

    return CoverData(thumbData: thumbData, timeMs: timeMs);
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
  /// The [capDimension] parameter will cap the largest side (height/width) to specified dimension and will reset other dimension to preserve aspect ratio.
  /// eg: [capDimension] = 640
  /// for: h=500,w=1080 video, new width will be 640 and height will be adjusted to preseve aspect ratio.
  /// if both [scale] and [capDimension] are specified the [scale] parameter will be applied.
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
  ///
  /// if output file is already present [overwriteFile] will first delete it then proceed to create new.
  ///
  /// libx264 is default for mp4 videos and height and width must be divisible by 2
  /// [dimensionDivisibleBy] is set to 2 for this purpose, while selecting libx265 codec pass value 8 as it needs height and width to be divisble by 8.
  ///
  ///
  /// Await for future to complete with file or use [onCompleted] callback to execute;
  /// Future is introduced to avoid nested callbacks thus promoting cleaner async code.
  ///
  Future<File?> exportVideoWithFuture({
    void Function(Object, StackTrace)? onError,
    String? name,
    String? outDir,
    String format = "mp4",
    double? scale,
    double? capDimension,
    String? customInstruction,
    void Function(Statistics, double)? onProgress,
    VideoExportPreset preset = VideoExportPreset.none,
    bool isFiltersEnabled = true,
    bool overwriteFile = true,
    int dimensionDivisibleBy = 2,
  }) async {
    Completer<File?> completer = Completer<File?>();
    final String tempPath = outDir ?? (await getTemporaryDirectory()).path;
    final String videoPath = file.path;
    name ??= path.basenameWithoutExtension(videoPath);
    final int epoch = DateTime.now().millisecondsSinceEpoch;
    final String outputPath = "$tempPath/${name}_$epoch.$format";

    File temp = File(outputPath);
    if (temp.existsSync()) {
      if (overwriteFile) {
        temp.deleteSync();
      }
    }
    String command = await _getVideoExportCommand(
      videoPath: videoPath,
      outputPath: outputPath,
      format: format,
      scale: scale,
      capDimension: capDimension,
      customInstruction: customInstruction,
      preset: preset,
      isFiltersEnabled: isFiltersEnabled,
      dimensionDivisibleBy: dimensionDivisibleBy,
    );
    FFmpegKit.executeAsync(
      command,
      (session) async {
        final state =
            FFmpegKitConfig.sessionStateToString(await session.getState());
        final code = await session.getReturnCode();

        if (code?.isValueSuccess() == true) {
          completer.complete(File(outputPath));
        } else {
          //log('FFmpeg process exited with state $state and return code $code.\n${await session.getOutput()}');
          if (onError != null) {
            onError(
              Exception(
                  'FFmpeg process exited with state $state and return code $code.\n${await session.getOutput()}'),
              StackTrace.current,
            );
          }
          completer.complete(null);
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
    //log("==> returning future");
    return completer.future;
  }

  Future<String> _getVideoExportCommand({
    required String videoPath,
    required String outputPath,
    String format = "mp4",
    double? scale,
    double? capDimension,
    String? customInstruction,
    VideoExportPreset preset = VideoExportPreset.none,
    bool isFiltersEnabled = true,
    int dimensionDivisibleBy = 2,
  }) async {
    final List<String> filters = [];
    final List<String> dynamicInstructionsList = [];
    final List<String> constantInstructionsList = [];

    constantInstructionsList.add(_getPreset(preset));
    // Dynamic Instructions
    if (customInstruction != null) {
      dynamicInstructionsList.add(customInstruction);
    }
    if (isTrimmmed) {
      dynamicInstructionsList.add("-ss $_trimStart -to $_trimEnd");
    }
    if ((effectiveVideoBitRate != null) &&
        (effectiveVideoBitRate != currentVideoBitRate)) {
      dynamicInstructionsList.add('-b:v ${effectiveVideoBitRate! ~/ 1000}k');
    }
    if ((effectiveAudioBitRate != null) &&
        (effectiveAudioBitRate != currentAudioBitRate)) {
      dynamicInstructionsList.add('-b:a ${effectiveAudioBitRate! ~/ 1000}k');
    }
    if (muteAudio.value == true) {
      dynamicInstructionsList.add('-an');
    }

//

    // CALCULATE FILTERS
    if (format == "gif") {
      const String gif = "fps=10 -loop 0";
      filters.add(gif);
    }

// (minCrop >= _min && maxCrop <= _max) was returning true always which was triggering scale always
    if (((minCrop == _min) && (maxCrop == _max)) == false) {
      filters.add(await _getCrop());
    }

    if (scale != null) {
      if (scale != 1) {
        filters.add("scale=iw*$scale:ih*$scale");
      }
    } else if (capDimension != null) {
      double tempWidth = croppedDimensions.width;
      double tempHeight = croppedDimensions.height;
      // Not needed as rotation will be applied after the scale
      // If rotated changed change dimensions
/*       if (isRotated) {
        if ((_rotation == 90) ||
            (_rotation == 270) ||
            (_rotation == -90) ||
            (_rotation == -270)) {
          log("==> rotated to change dimensions");
          tempWidth = croppedDimensions.height;
          tempHeight = croppedDimensions.width;
        }
      } */
      if (tempWidth > tempHeight) {
        if (tempWidth > capDimension) {
          // scale according to width
          filters.add("scale=$capDimension:-1");
        }
      } else {
        if (tempHeight > capDimension) {
          // scale according to height
          filters.add("scale=-1:$capDimension");
        }
      }
    }
    // h.264 needs height to be multiple of 2, thus dividing and rounding then multiplying with 2 will solve the problem.
    // h.265 needs height to be multiple of 8.
    filters.add(
        "pad=ceil(iw/$dimensionDivisibleBy)*$dimensionDivisibleBy:ceil(ih/$dimensionDivisibleBy)*$dimensionDivisibleBy");
    bool isRotated = !(_rotation >= 360 || _rotation <= 0);
    if (isRotated) {
      filters.add(_getRotation());
    }

    filters.removeWhere((item) => item.isEmpty);
    final String filter = filters.isNotEmpty && isFiltersEnabled
        ? "-vf ${filters.join(",")}"
        : "";

    // PROGRESS CALLBACKS
    final String execute =
        " -i '$videoPath' ${constantInstructionsList.join(' ')} ${dynamicInstructionsList.join(' ')} $filter -y '$outputPath'";
    return execute;
  }

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
  /// The [capDimension] parameter will cap the largest side (height/width) to specified dimension and will reset other dimension to preserve aspect ratio.
  /// eg: [capDimension] = 640
  /// for: h=500,w=1080 video, new width will be 640 and height will be adjusted to preseve aspect ratio.
  /// if both [scale] and [capDimension] are specified the [scale] parameter will be applied.
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
  ///
  /// if output file is already present [overwriteFile] will first delete it then proceed to create new.
  ///
  /// libx264 is default for mp4 videos and height and width must be divisible by 2
  /// [dimensionDivisibleBy] is set to 2 for this purpose, while selecting libx265 codec pass value 8 as it needs height and width to be divisble by 8.
  ///
  ///
  /// Await for future to complete with file or use [onCompleted] callback to execute;
  /// Future is introduced to avoid nested callbacks thus promoting cleaner async code.
  ///
  Future<void> exportVideo({
    required void Function(File file) onCompleted,
    void Function(Object, StackTrace)? onError,
    String? name,
    String? outDir,
    String format = "mp4",
    double? scale,
    double? capDimension,
    String? customInstruction,
    void Function(Statistics, double)? onProgress,
    VideoExportPreset preset = VideoExportPreset.none,
    bool isFiltersEnabled = true,
    bool overwriteFile = true,
    int dimensionDivisibleBy = 2,
  }) async {
    final String tempPath = outDir ?? (await getTemporaryDirectory()).path;
    final String videoPath = file.path;
    name ??= path.basenameWithoutExtension(videoPath);
    final int epoch = DateTime.now().millisecondsSinceEpoch;
    final String outputPath = "$tempPath/${name}_$epoch.$format";

    File temp = File(outputPath);
    if (temp.existsSync()) {
      if (overwriteFile) {
        temp.deleteSync();
      }
    }

    String command = await _getVideoExportCommand(
      videoPath: videoPath,
      outputPath: outputPath,
      format: format,
      scale: scale,
      capDimension: capDimension,
      customInstruction: customInstruction,
      preset: preset,
      isFiltersEnabled: isFiltersEnabled,
      dimensionDivisibleBy: dimensionDivisibleBy,
    );
    await FFmpegKit.executeAsync(
      command,
      (session) async {
        final state =
            FFmpegKitConfig.sessionStateToString(await session.getState());
        final code = await session.getReturnCode();

        if (code?.isValueSuccess() == true) {
          onCompleted.call(File(outputPath));
        } else {
          //log('FFmpeg process exited with state $state and return code $code.\n${await session.getOutput()}');
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
  /// The [capDimension] parameter will cap the largest side (height/width) to specified dimension and will reset other dimension to preserve aspect ratio.
  /// eg: [capDimension] = 640
  /// for: h=500,w=1080 video, new width will be 640 and height will be adjusted to preseve aspect ratio.
  /// if both [scale] and [capDimension] are specified the [scale] parameter will be applied.
  /// Set [isFiltersEnabled] to `false` if you do not want to apply any changes
  Future<void> extractCover({
    required void Function(File file) onCompleted,
    void Function(Object, StackTrace)? onError,
    String? name,
    String? outDir,
    String format = "jpg",
    double? scale,
    int quality = 100,
    double? capDimension,
    void Function(Statistics)? onProgress,
    bool isFiltersEnabled = true,
    bool overwriteFile = true,
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

    File temp = File(outputPath);
    if (temp.existsSync()) {
      if (overwriteFile) {
        temp.deleteSync();
      }
    }

    String command = await _getExportCoverCommand(
      coverPath: coverPath,
      outputPath: outputPath,
      scale: scale,
      capDimension: capDimension,
      isFiltersEnabled: isFiltersEnabled,
    );

    // PROGRESS CALLBACKS
    await FFmpegKit.executeAsync(
      command,
      (session) async {
        final state =
            FFmpegKitConfig.sessionStateToString(await session.getState());
        final code = await session.getReturnCode();

        if (code?.isValueSuccess() == true) {
          onCompleted.call(File(outputPath));
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

  Future<String> _getExportCoverCommand({
    required String coverPath,
    required String outputPath,
    double? scale,
    double? capDimension,
    bool isFiltersEnabled = true,
  }) async {
    final List<String> filters = [];
    // CALCULATE FILTERS
    if (((minCrop == _min) && (maxCrop == _max)) == false) {
      filters.add(await _getCrop());
    }

    if (scale != null) {
      if (scale != 1) {
        filters.add("scale=iw*$scale:ih*$scale");
      }
    } else if (capDimension != null) {
      double tempWidth = croppedDimensions.width;
      double tempHeight = croppedDimensions.height;
      if (tempWidth > tempHeight) {
        if (tempWidth > capDimension) {
          // scale according to width
          filters.add("scale=$capDimension:-1");
        }
      } else {
        if (tempHeight > capDimension) {
          // scale according to height
          filters.add("scale=-1:$capDimension");
        }
      }
    }
    bool isRotated = !(_rotation >= 360 || _rotation <= 0);
    if (isRotated) {
      filters.add(_getRotation());
    }
    // VALIDATE FILTERS
    filters.removeWhere((item) => item.isEmpty);
    final String filter = filters.isNotEmpty && isFiltersEnabled
        ? "-vf ${filters.join(",")}"
        : "";
    // ignore: unnecessary_string_escapes
    final String execute = "-i \'$coverPath\' $filter -y $outputPath";
    return execute;
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
  /// The [capDimension] parameter will cap the largest side (height/width) to specified dimension and will reset other dimension to preserve aspect ratio.
  /// eg: [capDimension] = 640
  /// for: h=500,w=1080 video, new width will be 640 and height will be adjusted to preseve aspect ratio.
  /// if both [scale] and [capDimension] are specified the [scale] parameter will be applied.
  /// Set [isFiltersEnabled] to `false` if you do not want to apply any changes
  Future<File?> extractCoverWithFuture({
    void Function(Object, StackTrace)? onError,
    String? name,
    String? outDir,
    String format = "jpg",
    double? scale,
    int quality = 100,
    double? capDimension,
    void Function(Statistics)? onProgress,
    bool isFiltersEnabled = true,
    bool overwriteFile = true,
  }) async {
    Completer<File?> completer = Completer<File?>();
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
      completer.complete(null);
    }
    name ??= path.basenameWithoutExtension(file.path);
    final int epoch = DateTime.now().millisecondsSinceEpoch;
    final String outputPath = "$tempPath/${name}_$epoch.$format";

    File temp = File(outputPath);
    if (temp.existsSync()) {
      if (overwriteFile) {
        temp.deleteSync();
      }
    }

    String command = await _getExportCoverCommand(
      coverPath: coverPath!,
      outputPath: outputPath,
      scale: scale,
      capDimension: capDimension,
      isFiltersEnabled: isFiltersEnabled,
    );
    // PROGRESS CALLBACKS
    FFmpegKit.executeAsync(
      command,
      (session) async {
        final state =
            FFmpegKitConfig.sessionStateToString(await session.getState());
        final code = await session.getReturnCode();

        if (code?.isValueSuccess() == true) {
          completer.complete(File(outputPath));
        } else {
          if (onError != null) {
            onError(
              Exception(
                  'FFmpeg process exited with state $state and return code $code.\n${await session.getOutput()}'),
              StackTrace.current,
            );
          }
          completer.complete(null);
        }
      },
      null,
      onProgress,
    );
    return completer.future;
  }
}
