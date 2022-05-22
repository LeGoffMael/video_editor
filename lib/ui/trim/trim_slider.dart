import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_editor/domain/bloc/controller.dart';
import 'package:video_editor/ui/trim/thumbnail_slider.dart';
import 'package:video_editor/ui/trim/trim_slider_painter.dart';

enum _TrimBoundaries { left, right, inside, progress, none }

class TrimSlider extends StatefulWidget {
  /// Slider that trim video length.
  const TrimSlider({
    Key? key,
    required this.controller,
    this.height = 60,
    this.quality = 10,
    this.horizontalMargin = 0.0,
    this.child,
  }) : super(key: key);

  /// The [controller] param is mandatory so every change in the controller settings will propagate in the trim slider view
  final VideoEditorController controller;

  /// The [height] param specifies the height of the generated thumbnails
  final double height;

  /// The [quality] param specifies the quality of the generated thumbnails, from 0 to 100 (([more info](https://pub.dev/packages/video_thumbnail)))
  final int quality;

  /// The [horizontalMargin] param specifies the horizontal space to set around the slider.
  /// It is important when the trim can be dragged (`controller.maxDuration` < `controller.videoDuration`)
  final double horizontalMargin;

  /// The [child] param can be specify to display a widget below this one (e.g: [TrimTimeline])
  final Widget? child;

  @override
  State<TrimSlider> createState() => _TrimSliderState();
}

class _TrimSliderState extends State<TrimSlider>
    with AutomaticKeepAliveClientMixin<TrimSlider> {
  final _boundary = ValueNotifier<_TrimBoundaries>(_TrimBoundaries.none);
  final _scrollController = ScrollController();

  Rect _rect = Rect.zero;
  Size _trimLayout = Size.zero;
  Size _fullLayout = Size.zero;
  late VideoPlayerController _controller;

  double _thumbnailPosition = 0.0;
  double? _ratio;
  // trim line width set in the style
  double _trimWidth = 0.0;

  @override
  void initState() {
    _controller = widget.controller.video;
    _ratio = getRatioDuration();
    _trimWidth = widget.controller.trimStyle.lineWidth;
    super.initState();
  }

  @override
  bool get wantKeepAlive => true;

  //--------//
  //GESTURES//
  //--------//
  void _onHorizontalDragStart(DragStartDetails details) {
    final double margin = 25.0 + widget.horizontalMargin;
    final double pos = details.localPosition.dx;
    final double max = _rect.right;
    final double min = _rect.left;
    final double progressTrim = _getTrimPosition();
    final List<double> minMargin = [min - margin, min + margin];
    final List<double> maxMargin = [max - margin, max + margin];

    //IS TOUCHING THE GRID
    if (pos >= minMargin[0] && pos <= maxMargin[1]) {
      //TOUCH BOUNDARIES
      if (pos >= minMargin[0] && pos <= minMargin[1]) {
        _boundary.value = _TrimBoundaries.left;
      } else if (pos >= maxMargin[0] && pos <= maxMargin[1]) {
        _boundary.value = _TrimBoundaries.right;
      } else if (pos >= progressTrim - margin && pos <= progressTrim + margin) {
        _boundary.value = _TrimBoundaries.progress;
      } else if (pos >= minMargin[1] && pos <= maxMargin[0]) {
        _boundary.value = _TrimBoundaries.inside;
      } else {
        _boundary.value = _TrimBoundaries.none;
      }
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
        // avoid minTrim to be bigger than maxTrim
        if (pos.dx > widget.horizontalMargin &&
            pos.dx < _rect.right - _trimWidth * 2) {
          _changeTrimRect(left: pos.dx, width: _rect.width - delta.dx);
        }
        break;
      case _TrimBoundaries.right:
        final pos = _rect.topRight + delta;
        // avoid maxTrim to be smaller than minTrim
        if (pos.dx < _trimLayout.width + widget.horizontalMargin &&
            pos.dx > _rect.left + _trimWidth * 2) {
          _changeTrimRect(width: _rect.width + delta.dx);
        }
        break;
      case _TrimBoundaries.inside:
        final pos = _rect.topLeft + delta;
        // Move thumbs slider when the trimmer is on the edges
        if (_rect.topLeft.dx + delta.dx < widget.horizontalMargin ||
            _rect.topRight.dx + delta.dx > _trimLayout.width) {
          _scrollController.position.moveTo(
            _scrollController.offset + delta.dx,
          );
        }
        if (pos.dx > widget.horizontalMargin && pos.dx < _rect.right) {
          _changeTrimRect(left: pos.dx);
        }
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
      final double progressTrim = _getTrimPosition();
      if (progressTrim >= _rect.right || progressTrim < _rect.left) {
        _controllerSeekTo(progressTrim);
      }
      _updateControllerIsTrimming(false);
      if (_boundary.value != _TrimBoundaries.progress) {
        if (_boundary.value != _TrimBoundaries.right) {
          _controllerSeekTo(_rect.left);
        }
        _updateControllerTrim();
      }
    }
  }

  //----//
  //RECT//
  //----//
  void _changeTrimRect({double? left, double? width}) {
    left = left ?? _rect.left;
    width = width ?? _rect.width;

    final Duration diff = _getDurationDiff(left, width);

    if (left >= 0 &&
        left + width - widget.horizontalMargin <= _trimLayout.width &&
        diff <= widget.controller.maxDuration) {
      _rect = Rect.fromLTWH(left, _rect.top, width, _rect.height);
      _updateControllerTrim();
    }
  }

  void _createTrimRect() {
    _rect = Rect.fromPoints(
      Offset(
          widget.controller.minTrim * _fullLayout.width +
              widget.horizontalMargin,
          0.0),
      Offset(
          widget.controller.maxTrim * _fullLayout.width +
              widget.horizontalMargin,
          widget.height),
    );
  }

  //----//
  //MISC//
  //----//
  void _controllerSeekTo(double position) async {
    await _controller.seekTo(
      _controller.value.duration * (position / _fullLayout.width),
    );
  }

  void _updateControllerTrim() {
    final double width = _fullLayout.width;
    widget.controller.updateTrim(
        (_rect.left + _thumbnailPosition - widget.horizontalMargin) / width,
        (_rect.right + _thumbnailPosition - widget.horizontalMargin) / width);
  }

  void _updateControllerIsTrimming(bool value) {
    if (_boundary.value != _TrimBoundaries.none &&
        _boundary.value != _TrimBoundaries.progress) {
      widget.controller.isTrimming = value;
    }
  }

  double _getTrimPosition() {
    return _fullLayout.width * widget.controller.trimPosition -
        _thumbnailPosition +
        widget.horizontalMargin;
  }

  double getRatioDuration() {
    return widget.controller.videoDuration.inMilliseconds /
        widget.controller.maxDuration.inMilliseconds;
  }

  Duration _getDurationDiff(double left, double width) {
    final double min = (left - widget.horizontalMargin) / _fullLayout.width;
    final double max =
        (left + width - widget.horizontalMargin) / _fullLayout.width;
    final Duration duration = _controller.value.duration;
    return (duration * max) - (duration * min);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return LayoutBuilder(builder: (_, contrainst) {
      final Size trimLayout = Size(
          contrainst.maxWidth - widget.horizontalMargin * 2,
          contrainst.maxHeight);
      final Size fullLayout = Size(
          trimLayout.width * (_ratio! > 1 ? _ratio! : 1), contrainst.maxHeight);
      _fullLayout = fullLayout;
      if (_trimLayout != trimLayout) {
        _trimLayout = trimLayout;
        _createTrimRect();
      }

      return SizedBox(
          width: _fullLayout.width,
          child: Stack(children: [
            NotificationListener<ScrollNotification>(
              child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  child: Container(
                      margin: EdgeInsets.symmetric(
                          horizontal: widget.horizontalMargin),
                      child: Column(children: [
                        SizedBox(
                            height: widget.height,
                            width: _fullLayout.width,
                            child: ThumbnailSlider(
                                controller: widget.controller,
                                height: widget.height,
                                quality: widget.quality)),
                        if (widget.child != null)
                          SizedBox(
                              width: _fullLayout.width, child: widget.child)
                      ]))),
              onNotification: (notification) {
                _boundary.value = _TrimBoundaries.inside;
                _updateControllerIsTrimming(true);
                if (notification is ScrollEndNotification) {
                  _thumbnailPosition = notification.metrics.pixels;
                  _controllerSeekTo(_rect.left);
                  _updateControllerIsTrimming(false);
                  _updateControllerTrim();
                }
                return true;
              },
            ),
            GestureDetector(
              onHorizontalDragUpdate: _onHorizontalDragUpdate,
              onHorizontalDragStart: _onHorizontalDragStart,
              onHorizontalDragEnd: _onHorizontalDragEnd,
              behavior: HitTestBehavior.opaque,
              child: AnimatedBuilder(
                animation: Listenable.merge([widget.controller, _controller]),
                builder: (_, __) {
                  return CustomPaint(
                    size: Size.fromHeight(widget.height),
                    painter: TrimSliderPainter(
                      _rect,
                      _getTrimPosition(),
                      widget.controller.trimStyle,
                    ),
                  );
                },
              ),
            )
          ]));
    });
  }
}
