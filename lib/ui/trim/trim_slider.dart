import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_editor/domain/bloc/controller.dart';
import 'package:video_editor/ui/trim/thumbnail_slider.dart';
import 'package:video_editor/ui/trim/trim_slider_painter.dart';

enum _TrimBoundaries { left, right, inside, progress, none }

class TrimSlider extends StatefulWidget {
  ///Slider that trim video length.
  TrimSlider({
    Key? key,
    required this.controller,
    this.height = 60,
    this.quality = 10,
    this.maxDuration,
  }) : super(key: key);

  ///**Quality of thumbnails:** 0 is the worst quality and 100 is the highest quality.
  final int quality;

  ///It is the height of the thumbnails
  final double height;

  ///The max duration that can be trim video.
  final Duration? maxDuration;

  ///Essential argument for the functioning of the Widget
  final VideoEditorController controller;

  @override
  _TrimSliderState createState() => _TrimSliderState();
}

class _TrimSliderState extends State<TrimSlider> {
  final _boundary = ValueNotifier<_TrimBoundaries>(_TrimBoundaries.none);

  Rect _rect = Rect.zero;
  Size _layout = Size.zero;
  Duration? _maxDuration = Duration.zero;
  late VideoPlayerController _controller;

  @override
  void initState() {
    _controller = widget.controller.video;
    final Duration duration = _controller.value.duration;
    _maxDuration = widget.maxDuration == null || _maxDuration! > duration
        ? duration
        : widget.maxDuration;
    super.initState();
  }

  //--------//
  //GESTURES//
  //--------//
  void _onHorizontalDragStart(DragStartDetails details) {
    final double margin = 25.0;
    final double pos = details.localPosition.dx;
    final double max = _rect.right;
    final double min = _rect.left;
    final double progressTrim = _getTrimPosition();
    final List<double> minMargin = [min - margin, min + margin];
    final List<double> maxMargin = [max - margin, max + margin];

    //IS TOUCHING THE GRID
    if (pos >= minMargin[0] && pos <= maxMargin[1]) {
      //TOUCH BOUNDARIES
      if (pos >= minMargin[0] && pos <= minMargin[1])
        _boundary.value = _TrimBoundaries.left;
      else if (pos >= maxMargin[0] && pos <= maxMargin[1])
        _boundary.value = _TrimBoundaries.right;
      else if (pos >= progressTrim - margin && pos <= progressTrim + margin)
        _boundary.value = _TrimBoundaries.progress;
      else if (pos >= minMargin[1] && pos <= maxMargin[0])
        _boundary.value = _TrimBoundaries.inside;
      else
        _boundary.value = _TrimBoundaries.none;
      _updateControllerIsTrimming(true);
    } else {
      _boundary.value = _TrimBoundaries.none;
    }
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    final Offset delta = details.delta;
    switch (_boundary.value) {
      case _TrimBoundaries.left:
        final pos = _rect.topLeft + delta;
        _changeTrimRect(left: pos.dx, width: _rect.width - delta.dx);
        break;
      case _TrimBoundaries.right:
        _changeTrimRect(width: _rect.width + delta.dx);
        break;
      case _TrimBoundaries.inside:
        final pos = _rect.topLeft + delta;
        _changeTrimRect(left: pos.dx);
        break;
      case _TrimBoundaries.progress:
        final double pos = details.localPosition.dx;
        if (pos >= _rect.left && pos <= _rect.right) _controllerSeekTo(pos);
        break;
      case _TrimBoundaries.none:
        break;
    }
  }

  void _onHorizontalDragEnd(_) {
    if (_boundary.value != _TrimBoundaries.none) {
      final double _progressTrim = _getTrimPosition();
      if (_progressTrim >= _rect.right || _progressTrim < _rect.left)
        _controllerSeekTo(_progressTrim);
      _updateControllerIsTrimming(false);
      _updateControllerTrim();
    }
  }

  //----//
  //RECT//
  //----//
  void _changeTrimRect({double? left, double? width}) {
    left = left ?? _rect.left;
    width = width ?? _rect.width;

    final Duration diff = _getDurationDiff(left, width);

    if (left >= 0 && left + width <= _layout.width && diff <= _maxDuration!) {
      _rect = Rect.fromLTWH(left, _rect.top, width, _rect.height);
      _updateControllerTrim();
    }
  }

  void _createTrimRect() {
    void _normalRect() {
      _rect = Rect.fromPoints(
        Offset(widget.controller.minTrim * _layout.width, 0.0),
        Offset(widget.controller.maxTrim * _layout.width, widget.height),
      );
    }

    final Duration diff = _getDurationDiff(0.0, _layout.width);
    if (diff >= _maxDuration!)
      _rect = Rect.fromLTWH(
        0.0,
        0.0,
        (_maxDuration!.inMilliseconds /
                _controller.value.duration.inMilliseconds) *
            _layout.width,
        widget.height,
      );
    else
      _normalRect();
  }

  //----//
  //MISC//
  //----//
  void _controllerSeekTo(double position) async {
    await _controller.seekTo(
      _controller.value.duration * (position / _layout.width),
    );
  }

  void _updateControllerTrim() {
    final double width = _layout.width;
    widget.controller.minTrim = _rect.left / width;
    widget.controller.maxTrim = _rect.right / width;
  }

  void _updateControllerIsTrimming(bool value) {
    if (_boundary.value != _TrimBoundaries.none &&
        _boundary.value != _TrimBoundaries.progress)
      widget.controller.isTrimming = value;
  }

  double _getTrimPosition() {
    return _layout.width * widget.controller.trimPosition;
  }

  Duration _getDurationDiff(double left, double width) {
    final double min = left / _layout.width;
    final double max = (left + width) / _layout.width;
    final Duration duration = _controller.value.duration;
    return (duration * max) - (duration * min);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, contrainst) {
      final Size layout = Size(contrainst.maxWidth, contrainst.maxHeight);
      if (_layout != layout) {
        _layout = layout;
        _createTrimRect();
      }

      return GestureDetector(
        onHorizontalDragUpdate: _onHorizontalDragUpdate,
        onHorizontalDragStart: _onHorizontalDragStart,
        onHorizontalDragEnd: _onHorizontalDragEnd,
        behavior: HitTestBehavior.opaque,
        child: Stack(children: [
          ThumbnailSlider(
            controller: widget.controller,
            height: widget.height,
            quality: widget.quality,
          ),
          AnimatedBuilder(
            animation: Listenable.merge([widget.controller, _controller]),
            builder: (_, __) {
              return CustomPaint(
                size: Size.infinite,
                painter: TrimSliderPainter(
                  _rect,
                  _getTrimPosition(),
                  style: widget.controller.trimStyle,
                ),
              );
            },
          ),
        ]),
      );
    });
  }
}
