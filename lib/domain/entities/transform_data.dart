import 'package:flutter/material.dart';

class TransformData {
  TransformData({
    required this.scale,
    required this.rotation,
    required this.translate,
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
