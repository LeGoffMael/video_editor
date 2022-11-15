import 'package:flutter/material.dart';
import 'package:video_editor/domain/entities/transform_data.dart';

class CropTransform extends StatelessWidget {
  const CropTransform({
    super.key,
    required this.transform,
    required this.child,
  });

  final Widget child;
  final TransformData transform;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: Transform.rotate(
        angle: transform.rotation,
        child: Transform.scale(
          scale: transform.scale,
          child: Transform.translate(
            offset: transform.translate,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// [CropTransform] with rotation animation
class CropTransformWithAnimation extends StatefulWidget {
  const CropTransformWithAnimation({
    super.key,
    required this.transform,
    required this.child,
  });

  final Widget child;
  final TransformData transform;

  @override
  State<CropTransformWithAnimation> createState() =>
      _CropTransformWithAnimationState();
}

class _CropTransformWithAnimationState
    extends State<CropTransformWithAnimation> {
  bool _isInit = true;

  @override
  void didUpdateWidget(covariant CropTransformWithAnimation oldWidget) {
    // to avoid animation on initialization
    if (oldWidget.transform.rotation != 0.0) {
      _isInit = false;
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedRotation(
      // convert rad to turns
      turns: widget.transform.rotation * (57.29578 / 360),
      curve: Curves.easeInOut,
      duration: _isInit ? Duration.zero : const Duration(milliseconds: 300),
      child: ClipRRect(
        child: Transform.scale(
          scale: widget.transform.scale,
          child: Transform.translate(
            offset: widget.transform.translate,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
