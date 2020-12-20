import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:video_editor/utils/styles.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';

class VideoEditorController extends ChangeNotifier with WidgetsBindingObserver {
  final TrimSliderStyle trimStyle;
  final CropGridStyle cropStyle;
  final File file;

  VideoEditorController.file(
    this.file, {
    CropGridStyle cropStyle,
    TrimSliderStyle trimStyle,
  })  : assert(file != null),
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

  VideoPlayerController get videoController => _videoController;
  bool get initialized => _videoController.value.initialized;
  bool get isPlaying => _videoController.value.isPlaying;

  Duration get videoPosition => _videoController.value.position;
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

  void updateCrop(Offset min, Offset max) {
    _minCrop = min;
    _maxCrop = max;
    notifyListeners();
  }

  Offset get minCrop => _minCrop;
  Offset get maxCrop => _maxCrop;

  //----------//
  //VIDEO TRIM//
  //----------//
  String _getTrim() => "-ss $_trimStart -t ${_trimEnd - _trimStart}";

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

  double get minTrim => _minTrim;
  double get maxTrim => _maxTrim;
  double get trimPosition =>
      videoPosition.inMilliseconds / videoDuration.inMilliseconds;

  //------------//
  //VIDEO EXPORT//
  //------------//
  Future<File> exportVideo() async {
    final String tempPath = (await getTemporaryDirectory()).path;
    final String videoPath = file.path;
    final String videoName = path.basename(videoPath).split('.')[0];
    final String outputPath = tempPath + videoName + "_output.mp4";

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
