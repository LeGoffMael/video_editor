import 'package:flutter/material.dart';
import 'package:video_editor/domain/bloc/controller.dart';
import 'package:video_editor/ui/trim/thumbnail_slider.dart';
import 'package:video_editor/ui/trim/trim_slider_painter.dart';

enum _TrimBoundaries { left, right, inside, progress }

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
  _TrimBoundaries? _boundary;

  Rect _rect = Rect.zero;
  Size _trimLayout = Size.zero;
  Size _fullLayout = Size.zero;

  late final ratio = widget.controller.videoDuration.inMilliseconds /
      widget.controller.maxDuration.inMilliseconds;
  late final isExtendTrim = ratio > 1;

  final _scrollController = ScrollController();

  /// The distance of rect left side to the left of the scroll view before bouncing
  double _preSynchLeft = 0.0;

  /// The distance of rect right side to the right of the scroll view before bouncing
  double _preSynchRight = 0.0;

  /// The last position in pixels in the scroll view
  double? _previousScrollPixels;

  /// Set to `true` if the video was playing before the gesture
  bool _isVideoPlayerHold = false;

  late final trimWidth = widget.controller.trimStyle.lineWidth;

  @override
  void initState() {
    super.initState();
    if (isExtendTrim) _scrollController.addListener(attachTrimToScroll);
  }

  @override
  void dispose() {
    if (isExtendTrim) _scrollController.removeListener(attachTrimToScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void attachTrimToScroll() {
    if (_scrollController.position.outOfRange == false) {
      _preSynchLeft = 0.0;
      _preSynchRight = 0.0;
      return;
    }

    // if is clamping
    if (_scrollController.position.isScrollingNotifier.value &&
        _previousScrollPixels != null) {
      if (_scrollController.position.extentBefore == 0.0 &&
          _preSynchLeft == 0.0) {
        // TODO : not perfectly accurate
        _preSynchLeft = _rect.left -
            widget.horizontalMargin -
            // use the last scroll position because [isScrollingNotifier] will be set after
            (_previousScrollPixels?.abs() ?? 0);
      } else if (_scrollController.position.extentAfter == 0.0 &&
          _preSynchRight == 0.0) {
        _preSynchRight = _trimLayout.width -
            (_rect.right - widget.horizontalMargin) -
            (_scrollController.position.maxScrollExtent -
                    _scrollController.position.pixels)
                .abs();
      }
    }

    // distance of bounce on the right
    final rightOffset = _scrollController.position.maxScrollExtent -
        _scrollController.position.pixels;
    // distance of rect to right side
    final rectRightOffset =
        _trimLayout.width - (_rect.right - widget.horizontalMargin);

    if (_scrollController.position.extentAfter == 0.0 &&
        (_preSynchRight > 0 || rightOffset.abs() > rectRightOffset)) {
      final right = _scrollController.position.maxScrollExtent -
          (_scrollController.position.pixels -
              _scrollController.position.maxScrollExtent -
              (widget.horizontalMargin * 2));

      _changeTrimRect(
        left: right -
            _rect.width +
            widget.horizontalMargin -
            trimWidth -
            _preSynchRight,
      );
    } else if (_scrollController.position.extentBefore == 0.0 &&
        (_preSynchLeft > 0 ||
            _scrollController.offset.abs() + widget.horizontalMargin >
                _rect.left)) {
      _changeTrimRect(
        left: -_scrollController.position.pixels +
            widget.horizontalMargin +
            _preSynchLeft,
      );
    }

    _previousScrollPixels = _scrollController.position.pixels;
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

    _boundary = _TrimBoundaries.inside;
    // TOUCH BOUNDARIES
    if (pos >= minMargin[0] && pos <= minMargin[1]) {
      _boundary = _TrimBoundaries.left;
    } else if (pos >= maxMargin[0] && pos <= maxMargin[1]) {
      _boundary = _TrimBoundaries.right;
    } else if (pos >= progressTrim - margin && pos <= progressTrim + margin) {
      _boundary = _TrimBoundaries.progress;
    }
    _updateControllerIsTrimming(true);
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    final Offset delta = details.delta;

    switch (_boundary) {
      case _TrimBoundaries.left:
        final pos = _rect.topLeft + delta;
        // avoid minTrim to be bigger than maxTrim
        if (pos.dx > widget.horizontalMargin &&
            pos.dx < _rect.right - trimWidth * 2) {
          _changeTrimRect(left: pos.dx, width: _rect.width - delta.dx);
        }
        break;
      case _TrimBoundaries.right:
        final pos = _rect.topRight + delta;
        // avoid maxTrim to be smaller than minTrim
        if (pos.dx < _trimLayout.width + widget.horizontalMargin &&
            pos.dx > _rect.left + trimWidth * 2) {
          _changeTrimRect(width: _rect.width + delta.dx);
        }
        break;
      case _TrimBoundaries.inside:
        final pos = _rect.topLeft + delta;
        if (isExtendTrim) {
          _scrollController.position.moveTo(
            _scrollController.offset - delta.dx,
            clamp: false,
          );
        } else if (pos.dx > widget.horizontalMargin && pos.dx < _rect.right) {
          _changeTrimRect(left: pos.dx);
        }
        break;
      case _TrimBoundaries.progress:
        final double pos = details.localPosition.dx;
        if (pos >= _rect.left && pos <= _rect.right) _controllerSeekTo(pos);
        break;
      default:
        break;
    }
  }

  void _onHorizontalDragEnd(_) {
    if (_boundary == null) return;
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
    if (diff <= widget.controller.maxDuration) {
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
    if (_boundary == _TrimBoundaries.progress || _boundary == null) return;

    // if the left side changed and overtake the current postion
    if (_boundary == _TrimBoundaries.inside ||
        (_boundary == _TrimBoundaries.left &&
            startTrim > widget.controller.trimPosition)) {
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

  // TODO : must be fixed
  void _updateControllerTrim() {
    final double width = _fullLayout.width;
    final startTrim = (_rect.left - widget.horizontalMargin) / width;
    final endTrim = (_rect.right - widget.horizontalMargin) / width;

    widget.controller.updateTrim(startTrim, endTrim);
    _resetControllerPosition(startTrim, endTrim);
  }

  void _updateControllerIsTrimming(bool value) {
    if (_boundary == null) return;

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
    if (value == false) {
      _boundary = null;
    }
  }

  // TODO : must be fixed
  // NOTE : Using function instead of getter seems faster when grabbing the cursor
  // Returns the video position in the layout
  double _getTrimPosition() =>
      _fullLayout.width * widget.controller.trimPosition -
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
      _fullLayout = Size(
        trimLayout.width * (isExtendTrim ? ratio : 1),
        contrainst.maxHeight,
      );
      if (_trimLayout != trimLayout) {
        _trimLayout = trimLayout;
        _createTrimRect();
      }

      return SizedBox(
          width: _fullLayout.width,
          child: Stack(children: [
            SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.horizontalMargin,
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: widget.height,
                      width: _fullLayout.width,
                      child: ThumbnailSlider(
                        controller: widget.controller,
                        height: widget.height,
                        quality: widget.quality,
                      ),
                    ),
                    if (widget.child != null)
                      SizedBox(width: _fullLayout.width, child: widget.child)
                  ],
                ),
              ),
            ),
            GestureDetector(
              onHorizontalDragStart: _onHorizontalDragStart,
              onHorizontalDragUpdate: _onHorizontalDragUpdate,
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
                    ),
                  );
                },
              ),
            )
          ]));
    });
  }
}
