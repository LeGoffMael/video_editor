import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_editor/src/utils/helpers.dart';
import 'package:video_editor/src/utils/thumbnails.dart';
import 'package:video_editor/src/models/cover_data.dart';
import 'package:video_editor/video_editor.dart';
import 'package:video_player/video_player.dart';

class VideoMinDurationError extends Error {
  final Duration minDuration;
  final Duration videoDuration;

  VideoMinDurationError(this.minDuration, this.videoDuration);

  @override
  String toString() =>
      "Invalid argument (minDuration): The minimum duration ($minDuration) cannot be bigger than the duration of the video file ($videoDuration)";
}

enum RotateDirection { left, right }

/// The default value of this property `Offset(1.0, 1.0)`
const Offset maxOffset = Offset(1.0, 1.0);

/// The default value of this property `Offset.zero`
const Offset minOffset = Offset.zero;

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
    this.maxDuration = Duration.zero,
    this.minDuration = Duration.zero,
    this.coverThumbnailsQuality = 10,
    this.trimThumbnailsQuality = 10,
    this.coverStyle = const CoverSelectionStyle(),
    this.cropStyle = const CropGridStyle(),
    TrimSliderStyle? trimStyle,
  })  : _video = VideoPlayerController.file(File(
          // https://github.com/flutter/flutter/issues/40429#issuecomment-549746165
          Platform.isIOS ? Uri.encodeFull(file.path) : file.path,
        )),
        trimStyle = trimStyle ?? TrimSliderStyle(),
        assert(maxDuration > minDuration,
            'The maximum duration must be bigger than the minimum duration');

  int _rotation = 0;
  bool _isTrimming = false;
  bool _isTrimmed = false;
  bool isCropping = false;

  double? _preferredCropAspectRatio;

  double _minTrim = minOffset.dx;
  double _maxTrim = maxOffset.dx;

  Offset _minCrop = minOffset;
  Offset _maxCrop = maxOffset;

  Offset cacheMinCrop = minOffset;
  Offset cacheMaxCrop = maxOffset;

  Duration _trimEnd = Duration.zero;
  Duration _trimStart = Duration.zero;
  final VideoPlayerController _video;

  // Selected cover value
  final ValueNotifier<CoverData?> _selectedCover =
      ValueNotifier<CoverData?>(null);

  /// Get the [VideoPlayerController]
  VideoPlayerController get video => _video;

  /// Get the [VideoPlayerController.value.initialized]
  bool get initialized => _video.value.isInitialized;

  /// Get the [VideoPlayerController.value.isPlaying]
  bool get isPlaying => _video.value.isPlaying;

  /// Get the [VideoPlayerController.value.position]
  Duration get videoPosition => _video.value.position;

  /// Get the [VideoPlayerController.value.duration]
  Duration get videoDuration => _video.value.duration;

  /// Get the [VideoPlayerController.value.size]
  Size get videoDimension => _video.value.size;
  double get videoWidth => videoDimension.width;
  double get videoHeight => videoDimension.height;

  /// The [minTrim] param is the minimum position of the trimmed area on the slider
  ///
  /// The minimum value of this param is `0.0`
  /// The maximum value of this param is [maxTrim]
  double get minTrim => _minTrim;

  /// The [maxTrim] param is the maximum position of the trimmed area on the slider
  ///
  /// The minimum value of this param is [minTrim]
  /// The maximum value of this param is `1.0`
  double get maxTrim => _maxTrim;

  /// The [startTrim] param is the maximum position of the trimmed area in video position in [Duration] value
  Duration get startTrim => _trimStart;

  /// The [endTrim] param is the maximum position of the trimmed area in video position in [Duration] value
  Duration get endTrim => _trimEnd;

  /// The [Duration] of the selected trimmed area, it is the difference of [endTrim] and [startTrim]
  Duration get trimmedDuration => endTrim - startTrim;

  /// The [minCrop] param is the [Rect.topLeft] position of the crop area
  ///
  /// The minimum value of this param is `0.0`
  /// The maximum value of this param is `1.0`
  Offset get minCrop => _minCrop;

  /// The [maxCrop] param is the [Rect.bottomRight] position of the crop area
  ///
  /// The minimum value of this param is `0.0`
  /// The maximum value of this param is `1.0`
  Offset get maxCrop => _maxCrop;

  /// Get the [Size] of the [videoDimension] cropped by the points [minCrop] & [maxCrop]
  Size get croppedArea => Rect.fromLTWH(
        0,
        0,
        videoWidth * (maxCrop.dx - minCrop.dx),
        videoHeight * (maxCrop.dy - minCrop.dy),
      ).size;

  /// The [preferredCropAspectRatio] param is the selected aspect ratio (9:16, 3:4, 1:1, ...)
  double? get preferredCropAspectRatio => _preferredCropAspectRatio;
  set preferredCropAspectRatio(double? value) {
    if (preferredCropAspectRatio == value) return;
    _preferredCropAspectRatio = value;
    notifyListeners();
  }

  /// Set [preferredCropAspectRatio] to the current cropped area ratio
  void setPreferredRatioFromCrop() {
    _preferredCropAspectRatio = croppedArea.aspectRatio;
    notifyListeners();
  }

  /// Update the [preferredCropAspectRatio] param and init/reset crop parameters [minCrop] & [maxCrop] to match the desired ratio
  /// The crop area will be at the center of the layout
  void cropAspectRatio(double? value) {
    preferredCropAspectRatio = value;

    if (value != null) {
      final newSize = computeSizeWithRatio(videoDimension, value);

      Rect centerCrop = Rect.fromCenter(
        center: Offset(videoWidth / 2, videoHeight / 2),
        width: newSize.width,
        height: newSize.height,
      );

      _minCrop =
          Offset(centerCrop.left / videoWidth, centerCrop.top / videoHeight);
      _maxCrop = Offset(
          centerCrop.right / videoWidth, centerCrop.bottom / videoHeight);
      notifyListeners();
    }
  }

  //----------------//
  //VIDEO CONTROLLER//
  //----------------//

  /// Attempts to open the given video [File] and load metadata about the video.
  ///
  /// Update the trim position depending on the [maxDuration] param
  /// Generate the default cover [_selectedCover]
  /// Initialize [minCrop] & [maxCrop] values base on [aspectRatio]
  ///
  /// Throw a [VideoMinDurationError] error if the [minDuration] is bigger than [videoDuration], the error should be handled as such:
  /// ```dart
  ///  controller
  ///     .initialize()
  ///     .then((_) => setState(() {}))
  ///     .catchError((error) {
  ///   // NOTE : handle the error here
  /// }, test: (e) => e is VideoMinDurationError);
  /// ```
  Future<void> initialize({double? aspectRatio}) async {
    await _video.initialize();

    if (minDuration > videoDuration) {
      throw VideoMinDurationError(minDuration, videoDuration);
    }

    _video.addListener(_videoListener);
    _video.setLooping(true);

    // if no [maxDuration] param given, maxDuration is the videoDuration
    maxDuration = maxDuration == Duration.zero ? videoDuration : maxDuration;

    // Trim straight away when maxDuration is lower than video duration
    if (maxDuration < videoDuration) {
      updateTrim(
          0.0, maxDuration.inMilliseconds / videoDuration.inMilliseconds);
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
    _video.dispose();
    _selectedCover.dispose();
    super.dispose();
  }

  void _videoListener() {
    final position = videoPosition;
    if (position < _trimStart || position > _trimEnd) {
      _video.seekTo(_trimStart);
    }
  }

  //----------//
  //VIDEO CROP//
  //----------//

  /// Update the [minCrop] and [maxCrop] with [cacheMinCrop] and [cacheMaxCrop]
  void applyCacheCrop() => updateCrop(cacheMinCrop, cacheMaxCrop);

  // Update [minCrop] and [maxCrop].
  ///
  /// The [min] param is the [Rect.topLeft] position of the crop area
  /// The [max] param is the [Rect.bottomRight] position of the crop area
  ///
  /// Arguments range are [Offset.zero] to `Offset(1.0, 1.0)`.
  void updateCrop(Offset min, Offset max) {
    assert(min < max,
        'Minimum crop value ($min) cannot be bigger and maximum crop value ($max)');

    _minCrop = min;
    _maxCrop = max;
    notifyListeners();
  }

  //----------//
  //VIDEO TRIM//
  //----------//

  /// Update [minTrim] and [maxTrim].
  ///
  /// The [min] param is the minimum position of the trimmed area on the slider
  /// The [max] param is the maximum position of the trimmed area on the slider
  ///
  /// Arguments range are `0.0` to `1.0`.
  void updateTrim(double min, double max) {
    assert(min < max,
        'Minimum trim value ($min) cannot be bigger and maximum trim value ($max)');
    // check that the new params does not cause a wrong duration
    final double newDuration = videoDuration.inMicroseconds * (max - min);
    // since [Duration] object does not takes integer we must round the
    // new duration up and down to check if the values are correct or not (#157)
    final Duration newDurationCeil = Duration(microseconds: newDuration.ceil());
    final Duration newDurationFloor =
        Duration(microseconds: newDuration.floor());
    assert(newDurationFloor <= maxDuration,
        'Trim duration ($newDurationFloor) cannot be smaller than $minDuration');
    assert(newDurationCeil >= minDuration,
        'Trim duration ($newDurationCeil) cannot be bigger than $maxDuration');

    _minTrim = min;
    _maxTrim = max;
    _updateTrimRange();
  }

  void _updateTrimRange() {
    _trimStart = videoDuration * minTrim;
    _trimEnd = videoDuration * maxTrim;

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
    if (!value) {
      _checkUpdateDefaultCover();
    }
    notifyListeners();
  }

  /// Get the [maxDuration] param. By giving this parameters, you ensure that
  /// the UI and controller function will avoid to select or generate a video
  /// bigger than this [Duration].
  ///
  /// If the value of [maxDuration] is bigger than [videoDuration],
  /// then this parameter will be ignored.
  ///
  /// Defaults to [videoDuration].
  Duration maxDuration;

  /// Get the [minDuration] param. By giving this parameters, you ensure that
  /// the UI and controller function will avoid to select or generate a video
  /// smaller than this [Duration].
  ///
  /// Defaults to [Duration.zero].
  /// Throw a [VideoMinDurationError] error at initialization if the [minDuration] is bigger then [videoDuration]
  final Duration minDuration;

  /// Get the [trimPosition], which is the videoPosition in the trim slider
  ///
  /// Range of the param is `0.0` to `1.0`.
  double get trimPosition =>
      videoPosition.inMilliseconds / videoDuration.inMilliseconds;

  //-----------//
  //VIDEO COVER//
  //-----------//

  /// The [coverThumbnailsQuality] param specifies the quality of the generated
  /// cover selection thumbnails (from 0 to 100 ([more info](https://pub.dev/packages/video_thumbnail)))
  ///
  /// Defaults to `10`.
  final int coverThumbnailsQuality;

  /// The [trimThumbnailsQuality] param specifies the quality of the generated
  /// trim slider thumbnails (from 0 to 100 ([more info](https://pub.dev/packages/video_thumbnail)))
  ///
  /// Defaults to `10`.
  final int trimThumbnailsQuality;

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

  /// Generate cover thumbnail at [startTrim] time in milliseconds
  void generateDefaultCoverThumbnail() async {
    final defaultCover = await generateSingleCoverThumbnail(
      file.path,
      timeMs: startTrim.inMilliseconds,
      quality: coverThumbnailsQuality,
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

  /// Get the rotation of the video, value should be a multiple of `90`
  int get cacheRotation => _rotation;

  /// Get the rotation of the video,
  /// possible values are: `0`, `90`, `180` and `270`
  int get rotation => (_rotation ~/ 90 % 4) * 90;

  /// Rotate the video by 90 degrees in the [direction] provided
  void rotate90Degrees([RotateDirection direction = RotateDirection.right]) {
    switch (direction) {
      case RotateDirection.left:
        _rotation += 90;
        break;
      case RotateDirection.right:
        _rotation -= 90;
        break;
    }
    notifyListeners();
  }

  bool get isRotated => rotation == 90 || rotation == 270;
}
