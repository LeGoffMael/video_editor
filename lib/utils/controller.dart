import 'dart:io';
import 'package:flutter_ffmpeg/statistics.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:video_editor/utils/styles.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';

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

class VideoEditorController extends ChangeNotifier with WidgetsBindingObserver {
  ///Style for [TrimSlider]
  final TrimSliderStyle trimStyle;

  ///Style for [CropGridViewer]
  final CropGridStyle cropStyle;

  ///Video from [File].
  final File file;

  ///Constructs a [VideoEditorController] that edits a video from a file.
  VideoEditorController.file(
    this.file, {
    TrimSliderStyle trimStyle,
    CropGridStyle cropStyle,
  })  : assert(file != null),
        _video = VideoPlayerController.file(file),
        this.cropStyle = cropStyle ?? CropGridStyle(),
        this.trimStyle = trimStyle ?? TrimSliderStyle();

  FlutterFFmpeg _ffmpeg = FlutterFFmpeg();
  FlutterFFprobe _ffprobe = FlutterFFprobe();

  int _rotation = 0;
  bool isTrimming = false;
  bool isCropping = false;
  double _minTrim = 0.0;
  double _maxTrim = 1.0;
  Offset _minCrop = Offset.zero;
  Offset _maxCrop = Offset(1.0, 1.0);

  Duration _trimEnd = Duration.zero;
  Duration _trimStart = Duration.zero;
  VideoPlayerController _video;

  //----------------//
  //VIDEO CONTROLLER//
  //----------------//
  ///Attempts to open the given [File] and load metadata about the video.
  Future<void> initialize() async {
    WidgetsBinding.instance.addObserver(this);
    await _video.initialize();
    _video.addListener(_videoListener);
    _video.setLooping(true);
    _updateTrimRange();
    notifyListeners();
  }

  @override
  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    if (isPlaying) _video?.pause();
    _video.removeListener(_videoListener);
    _video.dispose();
    _video = null;
    final executions = await _ffmpeg.listExecutions();
    if (executions.length > 0) await _ffmpeg.cancel();
    _ffprobe = null;
    _ffmpeg = null;
    super.dispose();
  }

  void _videoListener() {
    if (videoPosition < _trimStart || videoPosition >= _trimEnd)
      _video.seekTo(_trimStart);
    notifyListeners();
  }

  ///Get the `VideoPlayerController`
  VideoPlayerController get video => _video;

  ///Get the `VideoPlayerController.value.initialized`
  bool get initialized => _video.value.initialized;

  ///Get the `VideoPlayerController.value.isPlaying`
  bool get isPlaying => _video.value.isPlaying;

  ///Get the `VideoPlayerController.value.position`
  Duration get videoPosition => _video.value.position;

  ///Get the `VideoPlayerController.value.duration`
  Duration get videoDuration => _video.value.duration;

  //----------//
  //VIDEO CROP//
  //----------//
  Future<String> _getCrop(String path) async {
    final info = await _ffprobe.getMediaInformation(path);
    final streams = info.getStreams();
    int _videoHeight = 0;
    int _videoWidth = 0;

    if (streams != null && streams.length > 0) {
      for (var stream in streams) {
        final width = stream.getAllProperties()['width'];
        final height = stream.getAllProperties()['height'];
        if (width != null && width > _videoWidth) _videoWidth = width;
        if (height != null && height > _videoHeight) _videoHeight = height;
      }
    }

    final enddx = _videoWidth * _maxCrop.dx;
    final enddy = _videoHeight * _maxCrop.dy;
    final startdx = _videoWidth * _minCrop.dx;
    final startdy = _videoHeight * _minCrop.dy;
    final cropWidth = enddx - startdx;
    final cropHeight = enddy - startdy;

    return "crop=$cropWidth:$cropHeight:$startdx:$startdy";
  }

  ///Update minCrop and maxCrop.
  ///Arguments range are `Offset(0.0, 0.0)` to `Offset(1.0, 1.0)`.
  void updateCrop(Offset min, Offset max) {
    _minCrop = min;
    _maxCrop = max;
    notifyListeners();
  }

  ///Get the **TopLeftOffset** (Range is `Offset(0.0, 0.0)` to `Offset(1.0, 1.0)`).
  Offset get minCrop => _minCrop;

  ///Get the **BottomRightOffset** (Range is `Offset(0.0, 0.0)` to `Offset(1.0, 1.0)`).
  Offset get maxCrop => _maxCrop;

  //----------//
  //VIDEO TRIM//
  //----------//
  String _getTrim() => "-ss $_trimStart -to $_trimEnd";

  ///Update minTrim and maxTrim. Arguments range are `0.0` to `1.0`.
  void updateTrim(double min, double max) {
    _minTrim = min;
    _maxTrim = max;
    _updateTrimRange();
    notifyListeners();
  }

  void _updateTrimRange() {
    _trimEnd = videoDuration * _maxTrim;
    _trimStart = videoDuration * _minTrim;
  }

  ///Get the **MinTrim** (Range is `0.0` to `1.0`).
  double get minTrim => _minTrim;

  ///Get the **MaxTrim** (Range is `0.0` to `1.0`).
  double get maxTrim => _maxTrim;

  ///Get the **VideoPosition** (Range is `0.0` to `1.0`).
  double get trimPosition =>
      videoPosition.inMilliseconds / videoDuration.inMilliseconds;

  ///Don't touch this >:)

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
    if (_rotation >= 360 || _rotation <= 0) {
      return "";
    } else {
      List<String> transpose = [];
      for (int i = 0; i < _rotation / 90; i++) transpose.add("transpose=2");
      return transpose.length > 0 ? ",${transpose.join(',')}" : "";
    }
  }

  int get rotation => _rotation;

  //------------//
  //VIDEO EXPORT//
  //------------//
  ///Export the video at `TemporaryDirectory` and return a `File`.
  ///
  ///
  ///If the [name] is `null`, then it uses the filename.
  ///
  ///
  ///The [scaleVideo] is `scale=width*scale:height*scale` and reduce o increase video size.
  ///
  ///**View all** export formats on https://ffmpeg.org/ffmpeg-formats.html
  ///
  ///
  ///The [preset] is the `compress quality` **(Only available on some devices an full-lts package)**. A slower preset will provide better compression (compression is quality per filesize)
  ///
  ///**More info about presets**:  https://ffmpeg.org/ffmpeg-formats.htmlhttps://trac.ffmpeg.org/wiki/Encode/H.264
  Future<File> exportVideo({
    String name,
    String format = "mp4",
    double scale = 1.0,
    String customInstruction,
    VideoExportPreset preset = VideoExportPreset.none,
    void Function(Statistics) progressCallback,
  }) async {
    final FlutterFFmpegConfig _config = FlutterFFmpegConfig();
    final String tempPath = (await getTemporaryDirectory()).path;
    final String videoPath = file.path;
    if (name == null) name = path.basename(videoPath).split('.')[0];
    final String outputPath = tempPath + name + ".$format";

    final String scaleInstruction = ",scale=iw*$scale:ih*$scale";
    final String rotation = _getRotation();
    final String crop = await _getCrop(videoPath);
    final String trim = _getTrim();
    final String gif = format == "gif" ? ",fps=10 -loop 0" : "";

    final String execute =
        " -i $videoPath ${customInstruction ?? ""} -filter:v $crop$scaleInstruction$rotation$gif ${_getPreset(preset)} $trim -c:a copy -y $outputPath";

    _config.enableStatisticsCallback(progressCallback);
    final int code = await _ffmpeg.execute(execute);
    await _config.disableStatistics();

    if (code == 0) {
      print("SUCCESS EXPORT AT $outputPath");
      return File(outputPath);
    } else if (code == 255) {
      print("USER CANCEL EXPORT");
      return null;
    } else {
      print("ERROR ON EXPORT VIDEO (CODE $code)");
      return null;
    }
  }

  String _getPreset(VideoExportPreset preset) {
    String newPreset = "medium";

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
        break;
    }

    return preset == VideoExportPreset.none ? "" : "-preset $newPreset";
  }
}
