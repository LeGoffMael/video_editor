import 'dart:math';

import 'package:flutter/material.dart';

class AnimatedCropViewer extends StatefulWidget {
  final Widget child;
  final Rect rect;
  final Size layout;
  final Duration duration;

  const AnimatedCropViewer({
    Key? key,
    required this.child,
    required this.rect,
    required this.layout,
    this.duration = const Duration(milliseconds: 200),
  }) : super(key: key);

  @override
  State<AnimatedCropViewer> createState() => _AnimatedCropViewerState();
}

class _AnimatedCropViewerState extends State<AnimatedCropViewer>
    with TickerProviderStateMixin {
  final TransformationController _controller = TransformationController();
  late AnimationController _animationController;
  Animation<Matrix4>? _animationMatrix4;

  @override
  void initState() {
    _animationController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    super.initState();
  }

  @override
  void didUpdateWidget(covariant AnimatedCropViewer oldWidget) {
    // TODO : position error after rotation
    updateMatrixToFitRect();
    super.didUpdateWidget(oldWidget);
  }

  // Clear Matrix4D animation
  void _onInteractionStart(ScaleStartDetails details) {
    if (_animationController.status == AnimationStatus.forward) {
      _clearAnimation();
    }
  }

  Matrix4 pointToPoint(
      double scale, Offset srcFocalPoint, Offset dstFocalPoint) {
    return Matrix4.identity()
      ..translate(dstFocalPoint.dx, dstFocalPoint.dy)
      ..scale(scale)
      ..translate(-srcFocalPoint.dx, -srcFocalPoint.dy);
  }

  /// inspired from https://stackoverflow.com/a/68917749/7943785
  void updateMatrixToFitRect() {
    // scale from layout and rect
    FittedSizes fs =
        applyBoxFit(BoxFit.contain, widget.rect.size, widget.layout);
    double scaleX = fs.destination.width / fs.source.width;
    double scaleY = fs.destination.height / fs.source.height;

    // Offset center of layout
    final _layoutCenter = Rect.fromPoints(
            Offset.zero, Offset(widget.layout.width, widget.layout.height))
        .center;
    animateMatrix4(
        pointToPoint(min(scaleX, scaleY), widget.rect.center, _layoutCenter));
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
