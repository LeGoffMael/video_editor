import 'package:flutter/material.dart';

class TransformData {
  TransformData({
    @required this.scale,
    @required this.rotation,
    @required this.translate,
  });
  double rotation, scale;
  Offset translate;

  factory TransformData.fromRect(Rect rect, Size layout, int degrees) {
    final double width = rect.width;
    final double height = rect.height;

    final double xScale = layout.width / width;
    final double yScale = layout.height / height;

    final double scale = degrees == 90 || degrees == 270
        ? width > height
            ? yScale
            : xScale
        : width < height
            ? yScale
            : xScale;

    final double rotation = -degrees * (3.1416 / 180.0);

    final Offset translate = Offset(
      ((layout.width - width) / 2) - rect.left,
      ((layout.height - height) / 2) - rect.top,
    );

    return TransformData(
      rotation: rotation,
      scale: scale,
      translate: translate,
    );
  }
}

class CropTransform extends StatelessWidget {
  const CropTransform({
    Key key,
    @required this.transform,
    @required this.child,
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
