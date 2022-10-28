import 'package:flutter/material.dart';

/// Return desired dimension of [layout] that respect [r] aspect ratio
Size computeSizeWithRatio(Size layout, double r) {
  if (layout.aspectRatio == r) {
    return layout;
  }

  if (r == 1) {
    return Size(layout.shortestSide, layout.shortestSide);
  }

  /// Resize on width when the layout ratio is greater than 1 (16:9, 4:3, ...)
  /// or if layout ratio is equal to 1 (1:1) and desired ratio grater than 1 (16:9, 4:3, ...)
  final resizeWidth =
      layout.aspectRatio > 1 || (layout.aspectRatio == 1 && r > 1);

  if (resizeWidth) {
    return Size(layout.height * r, layout.height);
  } else {
    return Size(layout.width, layout.width / r);
  }
}
