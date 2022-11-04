import 'package:flutter/material.dart';
import 'package:video_editor/domain/bloc/controller.dart';
import 'package:video_editor/domain/helpers.dart';

class AnimatedCropViewer extends StatefulWidget {
  final Widget child;
  final Rect rect;
  final Size layout;
  final Duration duration;
  final VideoEditorController controller;
  final bool scaleAfter;

  const AnimatedCropViewer({
    Key? key,
    required this.child,
    required this.rect,
    required this.layout,
    required this.controller,
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

  @override
  void didUpdateWidget(covariant AnimatedCropViewer oldWidget) {
    if (widget.scaleAfter) {
      // to update interactive view only at the end of cropping action (to improve performances ?), similar behavior as iOS photo
      if (!widget.controller.isCropping) {
        animateMatrix4(
            getMatrixToFitRect()); // TODO : position error after rotation
      }
    } else {
      animateMatrix4(
          getMatrixToFitRect()); // TODO : position error after rotation
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
    return InteractiveViewer(
      transformationController: _controller,
      onInteractionStart: _onInteractionStart,
      clipBehavior: Clip.none,
      child: widget.child,
    );
  }
}
