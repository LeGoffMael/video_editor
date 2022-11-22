import 'dart:math';

import 'package:flutter/material.dart';

/// Returns a desired dimension of [layout] that respect [r] aspect ratio
Size computeSizeWithRatio(Size layout, double r) {
  if (layout.aspectRatio == r) {
    return layout;
  }

  if (layout.aspectRatio > r) {
    return Size(layout.height * r, layout.height);
  }

  if (layout.aspectRatio < r) {
    return Size(layout.width, layout.width / r);
  }

  assert(false, 'An error occured while computing the aspectRatio');
  return Size.zero;
}

/// Returns a new crop [Rect] that respect [r] aspect ratio
/// inside a [layout] and based on an existing [crop] area
///
/// This rect must not become smaller and smaller, or be out of bounds from [layout]
Rect resizeCropToRatio(Size layout, Rect crop, double r) {
  // if target ratio is smaller than current crop ratio
  if (r < crop.size.aspectRatio) {
    // use longest crop side if smaller than layout longest side
    final maxSide = min(crop.longestSide, layout.shortestSide);
    // to calculate the ratio of the new crop area
    final size = Size(maxSide, maxSide / r);

    final rect = Rect.fromCenter(
      center: crop.center,
      width: size.width,
      height: size.height,
    );

    // if res is smaller than layout we can return it
    if (rect.size <= layout) return translateRectIntoBounds(layout, rect);
  }

  // if there is not enough space crop to the middle of the current [crop]
  final newCenteredCrop = computeSizeWithRatio(crop.size, r);
  final rect = Rect.fromCenter(
    center: crop.center,
    width: newCenteredCrop.width,
    height: newCenteredCrop.height,
  );

  // return rect into bounds
  return translateRectIntoBounds(layout, rect);
}

/// Returns a translated [Rect] that fit [layout] size
Rect translateRectIntoBounds(Size layout, Rect rect) {
  final double translateX = (rect.left < 0 ? rect.left.abs() : 0) +
      (rect.right > layout.width ? layout.width - rect.right : 0);
  final double translateY = (rect.top < 0 ? rect.top.abs() : 0) +
      (rect.bottom > layout.height ? layout.height - rect.bottom : 0);

  if (translateX != 0 || translateY != 0) {
    return rect.translate(translateX, translateY);
  }

  return rect;
}

/// Return the scale for [rect] to fit [layout]
double scaleToSize(Size layout, Rect rect) =>
    min(layout.width / rect.width, layout.height / rect.height);

/// Returns `true` if [rect] is left and top are bigger than 0
/// and if right and bottom are smaller than [size] width and height
bool isRectContained(Size size, Rect rect) =>
    rect.left >= 0 &&
    rect.top >= 0 &&
    rect.right <= size.width &&
    rect.bottom <= size.height;

/// Scale [rect] to [scale] and fit it into [size]
Rect scaleRectInSize(Rect rect, double scale, Size size) =>
    translateRectIntoBounds(
      size,
      Rect.fromCenter(
        center: rect.center,
        width: rect.width * scale,
        height: rect.height * scale,
      ),
    );

/// Returns the smallest number between [a], [b] and [c]
double minOf3(double a, double b, double c) => min(a, min(b, c));
