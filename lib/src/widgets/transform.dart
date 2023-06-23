import 'package:flutter/material.dart';
import 'package:video_editor/src/models/transform_data.dart';

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
    return RepaintBoundary(
      child: ClipRRect(
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
      ),
    );
  }
}

/// [CropTransform] with rotation animation
class CropTransformWithAnimation extends StatelessWidget {
  const CropTransformWithAnimation({
    super.key,
    required this.transform,
    required this.child,
    this.shouldAnimate = true,
  });

  final Widget child;
  final TransformData transform;

  final bool shouldAnimate;

  @override
  Widget build(BuildContext context) {
    if (shouldAnimate == false) {
      return CropTransform(transform: transform, child: child);
    }

    return RepaintBoundary(
      child: AnimatedRotation(
        // convert rad to turns
        turns: transform.rotation * (57.29578 / 360),
        curve: Curves.easeInOut,
        duration: const Duration(milliseconds: 300),
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
