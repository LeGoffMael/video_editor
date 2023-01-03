import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:video_editor/video_editor.dart';

const kDefaultSelectedColor = Color(0xffffcc00);

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

/// Return the scale for [rect] to not be smaller [layout]
double scaleToSizeMax(Size layout, Rect rect) =>
    max(layout.width / rect.width, layout.height / rect.height);

/// Calculate crop [Rect] area
/// depending of [controller] min and max crop values and the size of the layout
Rect calculateCroppedRect(
  VideoEditorController controller,
  Size layout, {
  Offset? min,
  Offset? max,
}) {
  final Offset minCrop = min ?? controller.minCrop;
  final Offset maxCrop = max ?? controller.maxCrop;

  return Rect.fromPoints(
    Offset(minCrop.dx * layout.width, minCrop.dy * layout.height),
    Offset(maxCrop.dx * layout.width, maxCrop.dy * layout.height),
  );
}

/// Return `true` if the difference between [a] and [b] is less than `0.001`
bool isNumberAlmost(double a, int b) => nearEqual(a, b.toDouble(), 0.01);

/// Return the best index to spread among the list [length] when limited to a [max] value
/// When [max] is 0 or smaller than [length], returns [index]
///
/// ```
/// i.e = max=4, length=11
/// index=0 => 1
/// index=1 => 4
/// index=2 => 7
/// index=3 => 9
/// ```
int getBestIndex(int max, int length, int index) =>
    max >= length || max == 0 ? index : 1 + (index * (length / max)).round();

/// Returns `true` if [rect] is left and top are bigger than 0
/// and if right and bottom are smaller than [size] width and height
bool isRectContained(Size size, Rect rect) =>
    rect.left >= 0 &&
    rect.top >= 0 &&
    rect.right <= size.width &&
    rect.bottom <= size.height;

/// Returns opposite aspect ratio
///
/// ```
/// i.e
/// ratio=4/5 => 5/4
/// ratio=5/4 => 4/5
/// ratio=9/16 => 16/9
/// ratio=1 => 1
/// ```
double getOppositeRatio(double ratio) => 1 / ratio;
