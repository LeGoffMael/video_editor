import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:video_editor/utils/styles.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';

class VideoEditorController extends ChangeNotifier with WidgetsBindingObserver {
  ///Style for [TrimSlider]
  final TrimSliderStyle trimStyle;

  ///Style for [CropGridViewer]
  final CropGridStyle cropStyle;

  ///View all formats on https://ffmpeg.org/ffmpeg-formats.html
  final String exportFormat;

  ///Video from [File].
  final File file;

  ///Constructs a [VideoEditorController] that edits a video from a file.
  VideoEditorController.file(
    this.file, {
    CropGridStyle trimStyle,
    TrimSliderStyle cropStyle,
    this.exportFormat = "mp4",
  })  : assert(file != null),
        assert(trimStyle != null),
        assert(cropStyle != null),
        assert(exportFormat != null),
        _videoController = VideoPlayerController.file(file),
        this.cropStyle = cropStyle ?? CropGridStyle(),
        this.trimStyle = trimStyle ?? TrimSliderStyle();

  FlutterFFmpeg _ffmpeg = FlutterFFmpeg();
  FlutterFFprobe _ffprobe = FlutterFFprobe();

  double _minTrim = 0.0;
  double _maxTrim = 1.0;
  Offset _minCrop = Offset.zero;
  Offset _maxCrop = Offset(1.0, 1.0);

  Duration _trimEnd = Duration.zero;
  Duration _trimStart = Duration.zero;
  VideoPlayerController _videoController;

  //----------------//
  //VIDEO CONTROLLER//
  //----------------//
  ///Attempts to open the given [File] and load metadata about the video.
  Future<void> initialize() async {
    WidgetsBinding.instance.addObserver(this);
    await _videoController.initialize();
    _videoController.addListener(_videoListener);
    _videoController.setLooping(true);
    _updateTrimRange();
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (isPlaying) _videoController?.pause();
    _videoController.removeListener(_videoListener);
    _videoController.dispose();
    _videoController = null;
    _ffprobe = null;
    _ffmpeg = null;
    super.dispose();
  }

  void _videoListener() {
    if (videoPosition < _trimStart || videoPosition >= _trimEnd)
      _videoController.seekTo(_trimStart);
    notifyListeners();
  }

  ///Get the `VideoPlayerController`
  VideoPlayerController get videoController => _videoController;

  ///Get the `VideoPlayerController.value.initialized`
  bool get initialized => _videoController.value.initialized;

  ///Get the `VideoPlayerController.value.isPlaying`
  bool get isPlaying => _videoController.value.isPlaying;

  ///Get the `VideoPlayerController.value.position`
  Duration get videoPosition => _videoController.value.position;

  ///Get the `VideoPlayerController.value.duration`
  Duration get videoDuration => _videoController.value.duration;

  //----------//
  //VIDEO CROP//
  //----------//
  Future<String> _getCrop(String path) async {
    final info = await _ffprobe.getMediaInformation(path);
    final streams = info.getStreams();
    int videoHeight = 0;
    int videoWidth = 0;

    if (streams != null && streams.length > 0) {
      for (var stream in streams) {
        final width = stream.getAllProperties()['width'];
        final height = stream.getAllProperties()['height'];
        if (width != null && width > videoWidth) videoWidth = width;
        if (height != null && height > videoHeight) videoHeight = height;
      }
    }

    final enddx = videoWidth * _maxCrop.dx;
    final enddy = videoHeight * _maxCrop.dy;
    final startdx = videoWidth * _minCrop.dx;
    final startdy = videoHeight * _minCrop.dy;
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
  String _getTrim() => "-ss $_trimStart -t ${_trimEnd - _trimStart}";

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

  //------------//
  //VIDEO EXPORT//
  //------------//
  ///Export the video at `TemporaryDirectory` and return a `File`.
  Future<File> exportVideo() async {
    final String tempPath = (await getTemporaryDirectory()).path;
    final String videoPath = file.path;
    final String videoName = path.basename(videoPath).split('.')[0];
    final String outputPath = tempPath + videoName + ".$exportFormat";

    final String crop = await _getCrop(videoPath);
    final String trim = _getTrim();

    final int code = await _ffmpeg.execute(
      " -i $videoPath $trim -filter:v $crop -c:a copy -y $outputPath",
    );

    if (code == 0)
      print("SUCCESS EXPORT AT $outputPath");
    else if (code == 255)
      print("USER CANCEL EXPORT");
    else
      print("ERROR ON EXPORT VIDEO (CODE $code)");

    return File(outputPath);
  }
}
