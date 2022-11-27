import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    this.hasHaptic = true,
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

  //// Should haptic feed back be triggered when the trim touch an edge (left or right)
  final bool hasHaptic;

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

  /// Set to `true` if the video was playing before the gesture
  bool _isVideoPlayerHold = false;

  /// Horizontal margin around the [ThumbnailSlider]
  late final double _horizontalMargin =
      widget.horizontalMargin + widget.controller.trimStyle.edgeWidth;

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
    final double pos = details.localPosition.dx;
    final double progressTrim = _getTrimPosition();
    final List<double> minMargin = [
      _rect.left - _horizontalMargin,
      _rect.left + _horizontalMargin,
    ];
    final List<double> maxMargin = [
      _rect.right - _horizontalMargin,
      _rect.right + _horizontalMargin,
    ];

    //IS TOUCHING THE GRID
    if (pos >= minMargin[0] && pos <= maxMargin[1]) {
      //TOUCH BOUNDARIES
      if (pos >= minMargin[0] && pos <= minMargin[1]) {
        _boundary = _TrimBoundaries.left;
      } else if (pos >= maxMargin[0] && pos <= maxMargin[1]) {
        _boundary = _TrimBoundaries.right;
      } else if (pos >= progressTrim - _horizontalMargin &&
          pos <= progressTrim + _horizontalMargin) {
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
    final posLeft = _rect.topLeft + delta;
    final posRight = _rect.topRight + delta;

    switch (_boundary) {
      case _TrimBoundaries.left:
        // avoid minTrim to be bigger than maxTrim
        if (posLeft.dx > _horizontalMargin && posLeft.dx < _rect.right) {
          _changeTrimRect(left: posLeft.dx, width: _rect.width - delta.dx);
        }
        break;
      case _TrimBoundaries.right:
        // avoid maxTrim to be smaller than minTrim
        if (posRight.dx < _trimLayout.width + _horizontalMargin &&
            posRight.dx > _rect.left) {
          _changeTrimRect(width: _rect.width + delta.dx);
        }
        break;
      case _TrimBoundaries.inside:
        // Move thumbs slider when the trimmer is on the edges
        if (_rect.topLeft.dx + delta.dx < _horizontalMargin ||
            _rect.topRight.dx + delta.dx > _trimLayout.width) {
          _scrollController.position.moveTo(
            _scrollController.offset + delta.dx,
          );
        }
        if (posLeft.dx > _horizontalMargin &&
            posRight.dx < _trimLayout.width + _horizontalMargin) {
          _changeTrimRect(left: posLeft.dx);
        }
        break;
      case _TrimBoundaries.progress:
        final double pos = details.localPosition.dx;
        if (pos >= _rect.left - _horizontalMargin &&
            pos <= _rect.right + _horizontalMargin) _controllerSeekTo(pos);
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

    bool shouldHaptic = false;
    final isNotMin = _rect.left != _horizontalMargin;
    final isNotMax = _rect.right != _trimLayout.width + _horizontalMargin;

    // if touch left edge, set left to minimum (UI can be not accurate)
    if (isNotMin &&
        left - _horizontalMargin < 1 &&
        _scrollController.offset < _horizontalMargin) {
      shouldHaptic = true;
      width += left - _horizontalMargin; // to not affect width by changing left
      left = _horizontalMargin;
    }
    // if touch right edge, set right to maximum (UI can be not accurate)
    if (isNotMax &&
        (_trimLayout.width + _horizontalMargin) - (left + width) < 1 &&
        _scrollController.offset ==
            _scrollController.position.maxScrollExtent) {
      shouldHaptic = true;
      width = _trimLayout.width + _horizontalMargin - left;
    }

    final Duration diff = _getDurationDiff(left, width);

    if (left >= 0 &&
        left + width - _horizontalMargin <= _trimLayout.width &&
        diff <= widget.controller.maxDuration) {
      _rect = Rect.fromLTWH(left, _rect.top, width, _rect.height);
      _updateControllerTrim();
      // if left edge or right edge is touched, vibrate
      if (widget.hasHaptic && shouldHaptic) {
        HapticFeedback.lightImpact();
      }
    }
  }

  void _createTrimRect() {
    _rect = Rect.fromPoints(
      Offset(widget.controller.minTrim * _fullLayout.width, 0.0),
      Offset(widget.controller.maxTrim * _fullLayout.width, widget.height),
    ).shift(Offset(_horizontalMargin, 0));
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
      await widget.controller.video.seekTo(widget.controller.endTrim);
    }
  }

  /// Sets the video's current timestamp to be at the [position] on the slider
  /// If the expected position is bigger than [controller.endTrim], set it to [controller.endTrim]
  void _controllerSeekTo(double position) async {
    final to = widget.controller.videoDuration *
        ((position + _scrollController.offset) /
            (_fullLayout.width + _horizontalMargin * 2));
    await widget.controller.video.seekTo(
        to > widget.controller.endTrim ? widget.controller.endTrim : to);
  }

  void _updateControllerTrim() {
    final double width = _fullLayout.width;
    final startTrim =
        (_rect.left + _scrollController.offset - _horizontalMargin) / width;
    final endTrim =
        (_rect.right + _scrollController.offset - _horizontalMargin) / width;

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
      _scrollController.offset +
      _horizontalMargin;

  Duration _getDurationDiff(double left, double width) {
    final double min = (left - _horizontalMargin) / _fullLayout.width;
    final double max = (left + width - _horizontalMargin) / _fullLayout.width;
    final Duration duration = widget.controller.videoDuration;
    return (duration * max) - (duration * min);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return LayoutBuilder(builder: (_, contrainst) {
      final Size trimLayout = Size(
        contrainst.maxWidth - _horizontalMargin * 2,
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
                  padding: EdgeInsets.symmetric(horizontal: _horizontalMargin),
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
                _updateControllerTrim();
                if (notification is ScrollEndNotification) {
                  _updateControllerIsTrimming(false);
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
                      isTrimmed: widget.controller.isTrimmed,
                    ),
                  );
                },
              ),
            )
          ]));
    });
  }
}
