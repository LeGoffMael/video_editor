import 'package:flutter/material.dart';
import 'package:video_editor/utils/controller.dart';
import 'package:video_editor/widgets/trim/trim_slider_painter.dart';
import 'package:video_editor/widgets/trim/thumbnail_slider.dart';
import 'package:video_player/video_player.dart';

enum TrimBoundaries { left, right, inside, progress }

class TrimSlider extends StatefulWidget {
  TrimSlider({
    Key key,
    @required this.controller,
    this.height = 60,
    this.quality = 25,
  }) : super(key: key);

  final int quality;
  final double height;
  final VideoEditorController controller;

  @override
  _TrimSliderState createState() => _TrimSliderState();
}

class _TrimSliderState extends State<TrimSlider> {
  VideoPlayerController _controller;
  TrimBoundaries boundary;
  double _progressTrim = 0.0;
  Size _layout = Size.zero;
  Rect _rect;
  bool _wasPlaying = false;

  @override
  void initState() {
    _controller = widget.controller.videoController;
    _controller.addListener(_listener);
    super.initState();
  }

  @override
  void dispose() {
    _controller.removeListener(_listener);
    super.dispose();
  }

  void _listener() {
    setState(() {
      _progressTrim = _layout.width * widget.controller.trimPosition;
    });
  }

  void onHorizontalDragStart(DragStartDetails details) {
    final double margin = 25.0;
    final double pos = details.localPosition.dx;
    final double max = _rect.right;
    final double min = _rect.left;

    //IS TOUCHING THE GRID
    if (pos >= min - margin && pos <= max + margin) {
      //TOUCH BOUNDARIES
      if (pos >= min - margin && pos <= min + margin) {
        boundary = TrimBoundaries.left;
      } else if (pos >= max - margin && pos <= max + margin) {
        boundary = TrimBoundaries.right;
      } else if (pos >= _progressTrim - margin &&
          pos <= _progressTrim + margin) {
        boundary = TrimBoundaries.progress;
      } else {
        boundary = TrimBoundaries.inside;
      }
    } else {
      boundary = null;
    }
    setState(() {});
  }

  void onHorizontalDragUpdate(DragUpdateDetails details) {
    if (boundary != null) {
      final Offset delta = details.delta;
      switch (boundary) {
        case TrimBoundaries.left:
          final pos = _rect.topLeft + delta;
          _changeRect(left: pos.dx, width: _rect.width - delta.dx);
          break;
        case TrimBoundaries.right:
          _changeRect(width: _rect.width + delta.dx);
          break;
        case TrimBoundaries.inside:
          final pos = _rect.topLeft + delta;
          _changeRect(left: pos.dx);
          break;
        case TrimBoundaries.progress:
          final double pos = details.localPosition.dx;
          if (pos >= _rect.left && pos <= _rect.right) {
            if (_controller.value.isPlaying) {
              _controller?.pause();
              _wasPlaying = true;
            }
            _progressTrim = pos;
            setState(() {});
          }
          break;
      }
    }
  }

  void onHorizontalDragEnd(_) async {
    final double width = _layout.width;
    widget.controller.updateTrim(_rect.left / width, _rect.right / width);
    if (boundary == TrimBoundaries.progress) {
      await _controller.seekTo(
        _controller.value.duration * (_progressTrim / width),
      );
      if (_wasPlaying) {
        await _controller?.play();
        _wasPlaying = false;
      }
    }
  }

  void _changeRect({double left, double width}) {
    left = left ?? _rect.left;
    width = width ?? _rect.width;
    if (left >= 0 && left + width <= _layout.width) {
      _rect = Rect.fromLTWH(left, _rect.top, width, _rect.height);
      setState(() {});
    }
  }

  void _createRect() {
    final double min = widget.controller.minTrim;
    final double max = widget.controller.maxTrim;
    final double width = _layout.width;
    _rect = Rect.fromLTWH(
      min * width,
      0.0,
      max * width,
      widget.height,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      _layout = Size(constraints.maxWidth, constraints.maxHeight);
      if (_rect == null) _createRect();

      return GestureDetector(
        onHorizontalDragUpdate: onHorizontalDragUpdate,
        onHorizontalDragStart: onHorizontalDragStart,
        onHorizontalDragEnd: onHorizontalDragEnd,
        child: Container(
          color: Colors.transparent,
          child: Stack(children: [
            ThumbnailSlider(
              controller: widget.controller,
              height: widget.height,
              quality: widget.quality,
            ),
            CustomPaint(
              size: Size.infinite,
              painter: TrimSliderPainter(
                _rect,
                _progressTrim,
                style: widget.controller.trimStyle,
              ),
            ),
          ]),
        ),
      );
    });
  }
}
