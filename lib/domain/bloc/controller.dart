import 'dart:io';
import 'dart:typed_data';
import 'package:ffmpeg_kit_flutter_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/ffprobe_kit.dart';
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

///A preset is a collection of options that will provide a certain encoding speed to compression ratio.
///
///A slower preset will provide better compression (compression is quality per filesize).
///
///This means that, for example, if you target a certain file size or constant bit rate,
///you will achieve better quality with a slower preset.
///Similarly, for constant quality encoding,
///you will simply save bitrate by choosing a slower preset.
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

///_max = Offset(1.0, 1.0);
const Offset _max = Offset(1.0, 1.0);

///_min = Offset.zero;
const Offset _min = Offset.zero;

class VideoEditorController extends ChangeNotifier {
  ///Style for [TrimSlider]
  final TrimSliderStyle trimStyle;

  ///Style for [CoverSelection]
  final CoverSelectionStyle coverStyle;

  ///Style for [CropGridViewer]
  final CropGridStyle cropStyle;

  ///Video from [File].
  final File file;

  ///Constructs a [VideoEditorController] that edits a video from a file.
  VideoEditorController.file(
    this.file, {
    Duration? maxDuration,
    TrimSliderStyle? trimStyle,
    CoverSelectionStyle? coverStyle,
    CropGridStyle? cropStyle,
  })  : _video = VideoPlayerController.file(file),
        this._maxDuration = maxDuration ?? Duration.zero,
        this.cropStyle = cropStyle ?? CropGridStyle(),
        this.coverStyle = coverStyle ?? CoverSelectionStyle(),
        this.trimStyle = trimStyle ?? TrimSliderStyle();

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
  VideoPlayerController _video;

  ///The max duration that can be trim video.
  Duration _maxDuration;

  //Cover parameters
  ValueNotifier<CoverData?> _selectedCover = ValueNotifier<CoverData?>(null);

  double _videoWidth = 0;
  double _videoHeight = 0;

  ///Get the `VideoPlayerController`
  VideoPlayerController get video => _video;

  ///Get the [Rotation Degrees]
  int get rotation => _rotation;

  ///Get the `VideoPlayerController.value.initialized`
  bool get initialized => _video.value.isInitialized;

  ///Get the `VideoPlayerController.value.isPlaying`
  bool get isPlaying => _video.value.isPlaying;

  ///Get the `VideoPlayerController.value.position`
  Duration get videoPosition => _video.value.position;

  ///Get the `VideoPlayerController.value.duration`
  Duration get videoDuration => _video.value.duration;

  ///Get the [Video Dimension] like VideoWidth and VideoHeight
  Size get videoDimension =>
      Size(_videoWidth.toDouble(), _videoHeight.toDouble());

  ///The **MinTrim** (Range is `0.0` to `1.0`).
  double get minTrim => _minTrim;
  set minTrim(double value) {
    if (value >= _min.dx && value <= _max.dx) {
      _minTrim = value;
      _updateTrimRange();
    }
  }

  ///The **MaxTrim** (Range is `0.0` to `1.0`).
  double get maxTrim => _maxTrim;
  set maxTrim(double value) {
    if (value >= _min.dx && value <= _max.dx) {
      _maxTrim = value;
      _updateTrimRange();
    }
  }

  ///The **startTrim**
  Duration get startTrim => _trimStart;

  ///The **endTrim**
  Duration get endTrim => _trimEnd;

  ///The **TopLeft Offset** (Range is `Offset(0.0, 0.0)` to `Offset(1.0, 1.0)`).
  Offset get minCrop => _minCrop;
  set minCrop(Offset value) {
    if (value >= _min && value <= _max) {
      _minCrop = value;
      notifyListeners();
    }
  }

  ///The **BottomRight Offset** (Range is `Offset(0.0, 0.0)` to `Offset(1.0, 1.0)`).
  Offset get maxCrop => _maxCrop;
  set maxCrop(Offset value) {
    if (value >= _min && value <= _max) {
      _maxCrop = value;
      notifyListeners();
    }
  }

  double? get preferredCropAspectRatio => _preferredCropAspectRatio;
  set preferredCropAspectRatio(double? value) {
    if (value == null) {
      _preferredCropAspectRatio = value;
      notifyListeners();
    } else if (value >= 0) {
      final length = cropStyle.boundariesLength * 4;
      final videoWidth = videoDimension.width;
      final videoHeight = videoDimension.height;
      final cropHeight = (cacheMaxCrop.dy - cacheMinCrop.dy) * videoHeight;
      final cropWidth = (cacheMaxCrop.dx - cacheMinCrop.dx) * videoWidth;
      Offset newMax = Offset(
        cropWidth / videoWidth,
        (cropWidth / value) / videoWidth,
      );

      if (newMax.dy > _max.dy || newMax.dx > _max.dx) {
        newMax = Offset(
          (cropHeight * value) / cropHeight,
          cropHeight / videoHeight,
        );
      }

      if ((newMax.dx - cacheMinCrop.dx) * videoWidth > length &&
          (newMax.dy - cacheMinCrop.dy) * videoHeight > length) {
        cacheMaxCrop = newMax;
        _preferredCropAspectRatio = value;
        notifyListeners();
      }
    }
  }

  //----------------//
  //VIDEO CONTROLLER//
  //----------------//
  ///Attempts to open the given [File] and load metadata about the video.
  Future<void> initialize() async {
    await _video.initialize().then((_) {
      _videoWidth = _video.value.size.width;
      _videoHeight = _video.value.size.height;
    });
    _video.addListener(_videoListener);
    _video.setLooping(true);

    _maxDuration = _maxDuration == Duration.zero ? videoDuration : _maxDuration;

    // Trim straight away when maxDuration is lower than video duration
    if (_maxDuration < videoDuration)
      updateTrim(
          0.0, _maxDuration.inMilliseconds / videoDuration.inMilliseconds);
    else
      _updateTrimRange();

    generateDefaultCoverThumnail();

    notifyListeners();
  }

  @override
  Future<void> dispose() async {
    if (_video.value.isPlaying) await _video.pause();
    _video.removeListener(_videoListener);
    final executions = await FFmpegKit.listSessions();
    if (executions.length > 0) await FFmpegKit.cancel();
    _video.dispose();
    super.dispose();
  }

  void _videoListener() {
    final position = videoPosition;
    if (position < _trimStart || position >= _trimEnd)
      _video.seekTo(_trimStart);
  }

  //----------//
  //VIDEO CROP//
  //----------//
  Future<String> _getCrop() async {
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

  ///Update the [minCrop] and [maxCrop]
  void updateCrop() {
    minCrop = cacheMinCrop;
    maxCrop = cacheMaxCrop;
  }

  //----------//
  //VIDEO TRIM//
  //----------//
  ///Update minTrim and maxTrim. Arguments range are `0.0` to `1.0`.
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

    if (_trimStart != Duration.zero || _trimEnd != videoDuration)
      _isTrimmed = true;
    else
      _isTrimmed = false;

    _checkUpdateDefaultCover();

    notifyListeners();
  }

  ///Get the **isTrimmed**
  bool get isTrimmmed => _isTrimmed;

  ///Get the **isTrimming**
  bool get isTrimming => _isTrimming;
  set isTrimming(bool value) {
    _isTrimming = value;
    notifyListeners();
  }

  ///Get the **maxDuration**
  Duration get maxDuration => _maxDuration;

  ///Get the **VideoPosition** (Range is `0.0` to `1.0`).
  double get trimPosition =>
      videoPosition.inMilliseconds / videoDuration.inMilliseconds;

  //-----------//
  //VIDEO COVER//
  //-----------//
  void updateSelectedCover(CoverData selectedCover) async {
    _selectedCover.value = selectedCover;
  }

  ///If condition are good update default cover
  ///Update only milliseconds time for performance reason
  void _checkUpdateDefaultCover() {
    if (!_isTrimming || _selectedCover.value == null)
      updateSelectedCover(CoverData(timeMs: startTrim.inMilliseconds));
  }

  ///Generate cover at startTrim time in milliseconds
  void generateDefaultCoverThumnail() async {
    final defaultCover =
        await generateCoverThumbnail(timeMs: startTrim.inMilliseconds);
    updateSelectedCover(defaultCover);
  }

  ///Generate cover data depending on milliseconds
  Future<CoverData> generateCoverThumbnail(
      {int timeMs = 0, int quality = 10}) async {
    final Uint8List? _thumbData = await VideoThumbnail.thumbnailData(
      imageFormat: ImageFormat.JPEG,
      video: file.path,
      timeMs: timeMs,
      quality: quality,
    );

    return new CoverData(thumbData: _thumbData, timeMs: timeMs);
  }

  ///Get the **selectedCover** notifier
  ValueNotifier<CoverData?> get selectedCoverNotifier => _selectedCover;

  ///Get the **selectedCover** value
  CoverData? get selectedCoverVal => _selectedCover.value;

  //------------//
  //VIDEO ROTATE//
  //------------//
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

  String _getRotation() {
    List<String> transpose = [];
    for (int i = 0; i < _rotation / 90; i++) transpose.add("transpose=2");
    return transpose.length > 0 ? "${transpose.join(',')}" : "";
  }

  //--------------//
  //VIDEO METADATA//
  //--------------//

  /// Return metadata of the video file
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

  ///Export the video using this edition parameters and return a `File`.
  ///
  ///If the [name] is `null`, then it uses this video filename.
  ///
  ///If the [outDir] is `null`, then it uses `TemporaryDirectory`.
  ///
  ///The [format] of the video to be exported, by default `mp4`.
  ///
  ///The [scale] is `scale=width*scale:height*scale` and reduce or increase video size.
  ///
  ///The [onProgress] is called while the video is exporting. This argument is usually used to update the export progress percentage.
  ///
  ///The [preset] is the `compress quality` **(Only available on min-gpl-lts package)**.
  ///A slower preset will provide better compression (compression is quality per filesize).
  ///**More info about presets**:  https://ffmpeg.org/ffmpeg-formats.htmlhttps://trac.ffmpeg.org/wiki/Encode/H.264
  Future<void> exportVideo({
    required void Function(File? file) onCompleted,
    String? name,
    String? outDir,
    String format = "mp4",
    double scale = 1.0,
    String? customInstruction,
    void Function(Statistics)? onProgress,
    VideoExportPreset preset = VideoExportPreset.none,
    bool isFiltersEnabled = true,
  }) async {
    final String tempPath = outDir ?? (await getTemporaryDirectory()).path;
    final String videoPath = file.path;
    if (name == null) name = path.basenameWithoutExtension(videoPath);
    final int epoch = DateTime.now().millisecondsSinceEpoch;
    final String outputPath = "$tempPath/${name}_$epoch.$format";

    //-----------------//
    //CALCULATE FILTERS//
    //-----------------//
    final String gif = format != "gif" ? "" : "fps=10 -loop 0";
    final String trim = minTrim >= _min.dx && maxTrim <= _max.dx
        ? "-ss $_trimStart -to $_trimEnd"
        : "";
    final String crop =
        minCrop >= _min && maxCrop <= _max ? await _getCrop() : "";
    final String rotation =
        _rotation >= 360 || _rotation <= 0 ? "" : _getRotation();
    final String scaleInstruction =
        scale == 1.0 ? "" : "scale=iw*$scale:ih*$scale";

    //----------------//
    //VALIDATE FILTERS//
    //----------------//
    final List<String> filters = [crop, scaleInstruction, rotation, gif];
    filters.removeWhere((item) => item.isEmpty);
    final String filter =
        filters.isNotEmpty && isFiltersEnabled ? "-filter:v " + filters.join(",") : "";
    final String execute =
        " -i \'$videoPath\' ${customInstruction ?? ""} $filter ${_getPreset(preset)} $trim -y $outputPath";

    //------------------//
    //PROGRESS CALLBACKS//
    //------------------//
    await FFmpegKit.executeAsync(
      execute,
      (session) async {
        final state =
            FFmpegKitConfig.sessionStateToString(await session.getState());
        final code = await session.getReturnCode();
        final failStackTrace = await session.getFailStackTrace();

        print(
            "FFmpeg process exited with state $state and return code $code.${(failStackTrace == null) ? "" : "\\n" + failStackTrace}");

        onCompleted(code?.isValueSuccess() == true ? File(outputPath) : null);
      },
      null,
      onProgress != null ? onProgress : null,
    );
  }

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

  ///Generate this selected cover image as a JPEG [File]
  ///
  ///If this [selectedCoverVal] is `null`, then it return the first frame of this video.
  Future<String?> _generateCoverFile({int quality = 100}) async {
    return await VideoThumbnail.thumbnailFile(
      imageFormat: ImageFormat.JPEG,
      thumbnailPath: (await getTemporaryDirectory()).path,
      video: file.path,
      timeMs: selectedCoverVal?.timeMs ?? startTrim.inMilliseconds,
      quality: quality,
    );
  }

  ///Export this selected cover, or by default the first one, return an image `File`.
  ///
  ///If the [name] is `null`, then it uses this video filename.
  ///
  ///If the [outDir] is `null`, then it uses `TemporaryDirectory`.
  ///
  ///The [format] of the image to be exported, by default `jpg`.
  ///
  ///The [scale] is `scale=width*scale:height*scale` and reduce or increase cover size.
  ///
  ///The [quality] of the exported image (from 0 to 100)
  Future<void> extractCover({
    required void Function(File? file) onCompleted,
    String? name,
    String? outDir,
    String format = "jpg",
    double scale = 1.0,
    int quality = 100,
    void Function(Statistics)? onProgress,
  }) async {
    // final FlutterFFmpegConfig _config = FlutterFFmpegConfig();
    final String tempPath = outDir ?? (await getTemporaryDirectory()).path;
    // file generated from the thumbnail library or video source
    final String? _coverPath = await _generateCoverFile(
      quality: quality,
    );
    if (_coverPath == null) {
      print("ERROR ON COVER EXTRACTION WITH VideoThumbnail LIBRARY");
      return null;
    }
    if (name == null) name = path.basenameWithoutExtension(file.path);
    final int epoch = DateTime.now().millisecondsSinceEpoch;
    final String outputPath = "$tempPath/${name}_$epoch.$format";

    //-----------------//
    //CALCULATE FILTERS//
    //-----------------//
    final String crop =
        minCrop >= _min && maxCrop <= _max ? await _getCrop() : "";
    final String rotation =
        _rotation >= 360 || _rotation <= 0 ? "" : _getRotation();
    final String scaleInstruction =
        scale == 1.0 ? "" : "scale=iw*$scale:ih*$scale";

    //----------------//
    //VALIDATE FILTERS//
    //----------------//
    final List<String> filters = [crop, scaleInstruction, rotation];
    filters.removeWhere((item) => item.isEmpty);
    final String filter =
        filters.isNotEmpty ? "-filter:v " + filters.join(",") : "";
    final String execute = "-i \'$_coverPath\' $filter -y $outputPath";

    //------------------//
    //PROGRESS CALLBACKS//
    //------------------//
    await FFmpegKit.executeAsync(
      execute,
      (session) async {
        final state =
            FFmpegKitConfig.sessionStateToString(await session.getState());
        final code = await session.getReturnCode();
        final failStackTrace = await session.getFailStackTrace();

        print(
            "FFmpeg process exited with state $state and return code $code.${(failStackTrace == null) ? "" : "\\n" + failStackTrace}");

        onCompleted(code?.isValueSuccess() == true ? File(outputPath) : null);
      },
      null,
      onProgress != null ? onProgress : null,
    );
  }
}
