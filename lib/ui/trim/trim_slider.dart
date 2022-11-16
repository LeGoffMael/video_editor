import 'package:flutter/material.dart';
import 'package:video_editor/domain/bloc/controller.dart';
import 'package:video_editor/ui/trim/thumbnail_slider.dart';
import 'package:video_editor/ui/trim/trim_slider_painter.dart';

enum _TrimBoundaries { left, right, inside, progress, none }

class TrimSlider extends StatefulWidget {
  /// Slider that trim video length.
  const TrimSlider({
    super.key,
    required this.controller,
    this.height = 60,
    this.quality = 10,
    this.horizontalMargin = 0.0,
    this.child,
  });

  /// The [controller] param is mandatory so every change in the controller settings will propagate in the trim slider view
  final VideoEditorController controller;

  /// The [height] param specifies the height of the generated thumbnails
  ///
  /// Defaults to `60`
  final double height;

  /// The [quality] param specifies the quality of the generated thumbnails, from 0 to 100 (([more info](https://pub.dev/packages/video_thumbnail)))
  ///
  /// Defaults to `10`
  final int quality;

  /// The [horizontalMargin] param specifies the horizontal space to set around the slider.
  /// It is important when the trim can be dragged (`controller.maxDuration` < `controller.videoDuration`)
  ///
  /// Defaults to `0`
  final double horizontalMargin;

  /// The [child] param can be specify to display a widget below this one (e.g: [TrimTimeline])
  final Widget? child;

  @override
  State<TrimSlider> createState() => _TrimSliderState();
}

class _TrimSliderState extends State<TrimSlider>
    with AutomaticKeepAliveClientMixin<TrimSlider> {
  _TrimBoundaries _boundary = _TrimBoundaries.none;

  Rect _rect = Rect.zero;
  Size _trimLayout = Size.zero;
  Size _fullLayout = Size.zero;

  final _scrollController = ScrollController();
  double _thumbnailPosition = 0.0;

  /// Set to `true` if the video was playing before the gesture
  bool _isVideoPlayerHold = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
        _boundary = _TrimBoundaries.left;
      } else if (pos >= maxMargin[0] && pos <= maxMargin[1]) {
        _boundary = _TrimBoundaries.right;
      } else if (pos >= progressTrim - margin && pos <= progressTrim + margin) {
        _boundary = _TrimBoundaries.progress;
      } else if (pos >= minMargin[1] && pos <= maxMargin[0]) {
        _boundary = _TrimBoundaries.inside;
      } else {
        _boundary = _TrimBoundaries.none;
      }
      _updateControllerIsTrimming(true);
    } else {
      _boundary = _TrimBoundaries.none;
    }
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    final Offset delta = details.delta;
    final edgeWidth = widget.controller.trimStyle.edgeWidth;

    switch (_boundary) {
      case _TrimBoundaries.left:
        final pos = _rect.topLeft + delta;
        // avoid minTrim to be bigger than maxTrim
        if (pos.dx > widget.horizontalMargin &&
            pos.dx < _rect.right - edgeWidth * 2) {
          _changeTrimRect(left: pos.dx, width: _rect.width - delta.dx);
        }
        break;
      case _TrimBoundaries.right:
        final pos = _rect.topRight + delta;
        // avoid maxTrim to be smaller than minTrim
        if (pos.dx < _trimLayout.width + widget.horizontalMargin &&
            pos.dx > _rect.left + edgeWidth * 2) {
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
    if (_boundary == _TrimBoundaries.none) return;
    _updateControllerIsTrimming(false);
    if (_boundary != _TrimBoundaries.progress) {
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

  /// Reset the video cursor position to fit the rect
  void _resetControllerPosition(double startTrim, double endTrim) async {
    if (_boundary == _TrimBoundaries.progress &&
        _boundary == _TrimBoundaries.none) return;

    // if the left side changed and overtake the current postion
    if ((_boundary == _TrimBoundaries.inside ||
            _boundary == _TrimBoundaries.left) &&
        startTrim > widget.controller.trimPosition) {
      // reset position to startTrim
      await widget.controller.video.seekTo(widget.controller.startTrim);
    } else if ((_boundary == _TrimBoundaries.inside ||
            _boundary == _TrimBoundaries.right) &&
        endTrim < widget.controller.trimPosition) {
      // or if the right side changed and is under the current postion, reset position to endTrim
      // substract 10 milliseconds to avoid the video to loop and to show startTrim
      await widget.controller.video
          .seekTo(widget.controller.endTrim - const Duration(milliseconds: 10));
    }
  }

  void _controllerSeekTo(double position) => widget.controller.video.seekTo(
        widget.controller.videoDuration * (position / (_fullLayout.width)),
      );

  void _updateControllerTrim() {
    final double width = _fullLayout.width;
    final startTrim =
        (_rect.left + _thumbnailPosition - widget.horizontalMargin) / width;
    final endTrim =
        (_rect.right + _thumbnailPosition - widget.horizontalMargin) / width;

    widget.controller.updateTrim(startTrim, endTrim);
    _resetControllerPosition(startTrim, endTrim);
  }

  void _updateControllerIsTrimming(bool value) {
    if (_boundary == _TrimBoundaries.none) return;

    if (value && widget.controller.isPlaying) {
      _isVideoPlayerHold = true;
      widget.controller.video.pause();
    } else if (_isVideoPlayerHold) {
      _isVideoPlayerHold = false;
      widget.controller.video.play();
    }

    if (_boundary != _TrimBoundaries.progress) {
      widget.controller.isTrimming = value;
    }
  }

  // Using function instead of getter seems faster when grabbing the cursor
  double _getTrimPosition() =>
      _fullLayout.width * widget.controller.trimPosition -
      _thumbnailPosition +
      widget.horizontalMargin;

  Duration _getDurationDiff(double left, double width) {
    final double min = (left - widget.horizontalMargin) / _fullLayout.width;
    final double max =
        (left + width - widget.horizontalMargin) / _fullLayout.width;
    final Duration duration = widget.controller.videoDuration;
    return (duration * max) - (duration * min);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return LayoutBuilder(builder: (_, contrainst) {
      final Size trimLayout = Size(
        contrainst.maxWidth - widget.horizontalMargin * 2,
        contrainst.maxHeight,
      );
      final ratio = widget.controller.videoDuration.inMilliseconds /
          widget.controller.maxDuration.inMilliseconds;
      _fullLayout = Size(
        trimLayout.width * (ratio > 1 ? ratio : 1),
        contrainst.maxHeight,
      );
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
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.horizontalMargin,
                  ),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                            widget.controller.trimStyle.borderRadius),
                        child: SizedBox(
                          height: widget.height,
                          width: _fullLayout.width,
                          child: ThumbnailSlider(
                            controller: widget.controller,
                            height: widget.height,
                            quality: widget.quality,
                          ),
                        ),
                      ),
                      if (widget.child != null)
                        SizedBox(width: _fullLayout.width, child: widget.child)
                    ],
                  ),
                ),
              ),
              onNotification: (notification) {
                _boundary = _TrimBoundaries.inside;
                _updateControllerIsTrimming(true);
                if (notification is ScrollEndNotification) {
                  _thumbnailPosition = notification.metrics.pixels;
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
                animation: Listenable.merge([
                  widget.controller,
                  widget.controller.video,
                ]),
                builder: (_, __) {
                  return CustomPaint(
                    size: Size.fromHeight(widget.height),
                    painter: TrimSliderPainter(
                      _rect,
                      _getTrimPosition(),
                      widget.controller.trimStyle,
                      isTrimming: widget.controller.isTrimming,
                    ),
                  );
                },
              ),
            )
          ]));
    });
  }
}
