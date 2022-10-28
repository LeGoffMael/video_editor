import 'package:flutter/material.dart';

/// Return desired dimension of [layout] that respect [r] aspect ratio
Size computeSizeWithRatio(Size layout, double r) {
  if (layout.aspectRatio == r) {
    return layout;
  }

  if (layout.aspectRatio > r) {
    return Size(layout.height / r, layout.height);
  }

  if (layout.aspectRatio < r) {
    return Size(layout.width, layout.width * r);
  }

  assert(false, 'An error occured while computing the aspectRatio');
  return Size.zero;
}
