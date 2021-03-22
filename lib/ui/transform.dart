import 'package:flutter/material.dart';
import 'package:video_editor/domain/entities/transform_data.dart';

class CropTransform extends StatelessWidget {
  const CropTransform({
    Key? key,
    required this.transform,
    required this.child,
  }) : super(key: key);

  final Widget child;
  final TransformData transform;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: transform.rotation,
      child: Transform.scale(
        scale: transform.scale,
        child: Transform.translate(
          offset: transform.translate,
          child: child,
        ),
      ),
    );
  }
}
