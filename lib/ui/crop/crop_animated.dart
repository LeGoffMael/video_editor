import 'dart:math';

import 'package:flutter/material.dart';
import 'package:video_editor/domain/bloc/controller.dart';
import 'package:video_editor/domain/helpers.dart';
import 'package:video_editor/ui/video_viewer.dart';

enum _CropBoundaries {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  inside,
  topCenter,
  centerRight,
  centerLeft,
  bottomCenter,
  none
}

class AnimatedCropViewer extends StatefulWidget {
  final Widget child;
  final Rect rect;
  final Size layout;
  final Duration duration;
  final VideoEditorController controller;
  final Function(Rect) onChangeRect;
  final bool scaleAfter;

  const AnimatedCropViewer({
    Key? key,
    required this.child,
    required this.rect,
    required this.layout,
    required this.controller,
    required this.onChangeRect,
    this.scaleAfter = false,
    this.duration = const Duration(milliseconds: 200),
  }) : super(key: key);

  @override
  State<AnimatedCropViewer> createState() => _AnimatedCropViewerState();
}

class _AnimatedCropViewerState extends State<AnimatedCropViewer>
    with TickerProviderStateMixin {
  late final TransformationController _controller =
      TransformationController(getMatrixToFitRect());
  late final AnimationController _animationController = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  Animation<Matrix4>? _animationMatrix4;

  _CropBoundaries _boundary = _CropBoundaries.none;

  /// Minimum size of the cropped area
  late final double minRectSize =
      widget.controller.cropStyle.boundariesLength * 2;

  @override
  void didUpdateWidget(covariant AnimatedCropViewer oldWidget) {
    if (widget.scaleAfter) {
      // to update interactive view only at the end of cropping action (to improve performances ?), similar behavior as iOS photo
      if (!widget.controller.isCropping) {
        animateMatrix4(getMatrixToFitRect());
      }
    } else {
      animateMatrix4(getMatrixToFitRect());
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _clearAnimation();
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  //----------------//
  // CROP GESTURE //
  //----------------//

  /// Return [Rect] expanded position to improve grab facility, the size will be equal to a single grid square
  Rect _expandedPosition(Offset position) => Rect.fromCenter(
        center: position,
        // the width of one grid square
        width: (widget.rect.width / widget.controller.cropStyle.gridSize),
        // the height of one grid square
        height: (widget.rect.height / widget.controller.cropStyle.gridSize),
      );

  /// Return expanded [Rect] to includes all corners [_expandedPosition]
  Rect _expandedRect() {
    Rect expandedPosition = _expandedPosition(widget.rect.center);
    return Rect.fromCenter(
        center: widget.rect.center,
        width: widget.rect.width + expandedPosition.width,
        height: widget.rect.height + expandedPosition.height);
  }

  void _onPanStart(DragStartDetails details) {
    final Offset pos = details.localPosition;

    _boundary = _CropBoundaries.none;

    if (_expandedRect().contains(pos)) {
      if (widget.rect.contains(pos)) {
        _boundary = _CropBoundaries.inside;
      }

      // CORNERS
      if (_expandedPosition(widget.rect.topLeft).contains(pos)) {
        _boundary = _CropBoundaries.topLeft;
      } else if (_expandedPosition(widget.rect.topRight).contains(pos)) {
        _boundary = _CropBoundaries.topRight;
      } else if (_expandedPosition(widget.rect.bottomRight).contains(pos)) {
        _boundary = _CropBoundaries.bottomRight;
      } else if (_expandedPosition(widget.rect.bottomLeft).contains(pos)) {
        _boundary = _CropBoundaries.bottomLeft;
      } else if (widget.controller.preferredCropAspectRatio == null) {
        // CENTERS
        if (_expandedPosition(widget.rect.centerLeft).contains(pos)) {
          _boundary = _CropBoundaries.centerLeft;
        } else if (_expandedPosition(widget.rect.topCenter).contains(pos)) {
          _boundary = _CropBoundaries.topCenter;
        } else if (_expandedPosition(widget.rect.centerRight).contains(pos)) {
          _boundary = _CropBoundaries.centerRight;
        } else if (_expandedPosition(widget.rect.bottomCenter).contains(pos)) {
          _boundary = _CropBoundaries.bottomCenter;
        }
      }
    }
    widget.controller.isCropping = true;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_boundary != _CropBoundaries.none) {
      final Offset delta = details.delta;

      switch (_boundary) {
        case _CropBoundaries.inside:
          final Offset pos = widget.rect.topLeft + delta;
          widget.onChangeRect(
            Rect.fromLTWH(
              pos.dx.clamp(0, widget.layout.width - widget.rect.width),
              pos.dy.clamp(0, widget.layout.height - widget.rect.height),
              widget.rect.width,
              widget.rect.height,
            ),
          );
          break;
        // CORNERS
        case _CropBoundaries.topLeft:
          final Offset pos = widget.rect.topLeft + delta;
          _changeRect(left: pos.dx, top: pos.dy);
          break;
        case _CropBoundaries.topRight:
          final Offset pos = widget.rect.topRight + delta;
          _changeRect(right: pos.dx, top: pos.dy);
          break;
        case _CropBoundaries.bottomRight:
          final Offset pos = widget.rect.bottomRight + delta;
          _changeRect(right: pos.dx, bottom: pos.dy);
          break;
        case _CropBoundaries.bottomLeft:
          final Offset pos = widget.rect.bottomLeft + delta;
          _changeRect(left: pos.dx, bottom: pos.dy);
          break;
        // CENTERS
        case _CropBoundaries.topCenter:
          _changeRect(top: widget.rect.top + delta.dy);
          break;
        case _CropBoundaries.bottomCenter:
          _changeRect(bottom: widget.rect.bottom + delta.dy);
          break;
        case _CropBoundaries.centerLeft:
          _changeRect(left: widget.rect.left + delta.dx);
          break;
        case _CropBoundaries.centerRight:
          _changeRect(right: widget.rect.right + delta.dx);
          break;
        case _CropBoundaries.none:
          break;
      }
    }
  }

  /// Update [Rect] crop from incoming values, while respecting [_preferredCropAspectRatio]
  void _changeRect({double? left, double? top, double? right, double? bottom}) {
    top = (top ?? widget.rect.top)
        .clamp(0, max(0.0, widget.rect.bottom - minRectSize));
    left = (left ?? widget.rect.left)
        .clamp(0, max(0.0, widget.rect.right - minRectSize));
    right = (right ?? widget.rect.right)
        .clamp(widget.rect.left + minRectSize, widget.layout.width);
    bottom = (bottom ?? widget.rect.bottom)
        .clamp(widget.rect.top + minRectSize, widget.layout.height);

    // update crop height or width to adjust to the selected aspect ratio
    if (widget.controller.preferredCropAspectRatio != null) {
      final width = right - left;
      final height = bottom - top;

      if (width / height > widget.controller.preferredCropAspectRatio!) {
        switch (_boundary) {
          case _CropBoundaries.topLeft:
          case _CropBoundaries.bottomLeft:
            left = right - height * widget.controller.preferredCropAspectRatio!;
            break;
          case _CropBoundaries.topRight:
          case _CropBoundaries.bottomRight:
            right = left + height * widget.controller.preferredCropAspectRatio!;
            break;
          default:
            assert(false);
        }
      } else {
        switch (_boundary) {
          case _CropBoundaries.topLeft:
          case _CropBoundaries.topRight:
            top = bottom - width / widget.controller.preferredCropAspectRatio!;
            break;
          case _CropBoundaries.bottomLeft:
          case _CropBoundaries.bottomRight:
            bottom = top + width / widget.controller.preferredCropAspectRatio!;
            break;
          default:
            assert(false);
        }
      }
    }

    widget.onChangeRect(Rect.fromLTRB(left, top, right, bottom));
  }

  //----------------//
  // CROP ANIMATION //
  //----------------//

  // Clear Matrix4D animation
  void _onInteractionStart(ScaleStartDetails details) {
    if (_animationController.status == AnimationStatus.forward) {
      _clearAnimation();
    }
  }

  /// inspired from https://stackoverflow.com/a/68917749/7943785
  Matrix4 getMatrixToFitRect() {
    // Offset center of layout
    final layoutRect = rectFromSize(widget.layout);

    Rect rect = widget.rect;
    if (widget.rect == Rect.zero) {
      rect = layoutRect;
    }

    // scale from layout and rect
    FittedSizes fs = applyBoxFit(BoxFit.contain, rect.size, widget.layout);
    return pointToPoint(
      scaleToSize(fs.destination, rectFromSize(fs.source)),
      rect.center,
      layoutRect.center,
    );
  }

  Rect rectFromSize(Size size) =>
      Rect.fromPoints(Offset.zero, Offset(size.width, size.height));

  Matrix4 pointToPoint(
    double scale,
    Offset srcFocalPoint,
    Offset dstFocalPoint,
  ) {
    return Matrix4.identity()
      ..translate(dstFocalPoint.dx, dstFocalPoint.dy)
      ..scale(scale)
      //..rotateZ(TransformData.fromController(widget.controller).rotation)
      ..translate(-srcFocalPoint.dx, -srcFocalPoint.dy);
  }

  void _changeControllerMatrix4() {
    if (_animationMatrix4?.value != null) {
      _controller.value = _animationMatrix4!.value;
      if (!_animationController.isAnimating) _clearAnimation();
    }
  }

  void _clearAnimation() {
    _animationController.stop();
    _animationMatrix4?.removeListener(_changeControllerMatrix4);
    _animationMatrix4 = null;
    _animationController.reset();
  }

  Future<void> animateMatrix4(Matrix4 value) async {
    _animationMatrix4 = Matrix4Tween(
      begin: _controller.value,
      end: value,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.ease,
    ));
    _animationController.duration = widget.duration;
    _animationMatrix4!.addListener(_changeControllerMatrix4);
    await _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final Rect gestureArea = _expandedRect();

    return InteractiveViewer(
      transformationController: _controller,
      onInteractionStart: _onInteractionStart,
      clipBehavior: Clip.none,
      child: VideoViewer(
        controller: widget.controller,
        child: Stack(children: [
          widget.child,
          GestureDetector(
            onPanEnd: (_) {
              if (_boundary != _CropBoundaries.none) {
                widget.controller.cacheMinCrop = Offset(
                  widget.rect.left / widget.layout.width,
                  widget.rect.top / widget.layout.height,
                );
                widget.controller.cacheMaxCrop = Offset(
                  widget.rect.right / widget.layout.width,
                  widget.rect.bottom / widget.layout.height,
                );
                widget.controller.isCropping = false;
              }
            },
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            child: Container(
              margin: EdgeInsets.only(
                left: max(0.0, gestureArea.left),
                top: max(0.0, gestureArea.top),
              ),
              color: Colors.transparent,
              width: gestureArea.width,
              height: gestureArea.height,
            ),
          ),
        ]),
      ),
    );
  }
}
