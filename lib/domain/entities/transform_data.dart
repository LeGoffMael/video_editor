import 'dart:math';

import 'package:flutter/material.dart';
import 'package:video_editor/domain/bloc/controller.dart';
import 'package:video_editor/domain/helpers.dart';

class TransformData {
  TransformData({
    this.scale = 1.0,
    this.rotation = 0.0,
    this.translate = Offset.zero,
  });
  final double rotation, scale;
  final Offset translate;

  factory TransformData.fromRect(
    // the selected crop rect area
    Rect rect,
    // the maximum size of the crop area
    Size layout,
    // the maximum size to display
    Size maxSize,
    VideoEditorController controller,
  ) {
    if (controller.rotation == 90 || controller.rotation == 270) {
      maxSize = maxSize.flipped;
    }

    final double scale = scaleToSize(maxSize, rect);
    final double rotation = -controller.rotation * (pi / 180.0);
    final Offset translate = Offset(
      ((layout.width - rect.width) / 2) - rect.left,
      ((layout.height - rect.height) / 2) - rect.top,
    );

    return TransformData(
      rotation: rotation,
      scale: scale,
      translate: translate,
    );
  }

  factory TransformData.fromController(
    VideoEditorController controller,
  ) {
    return TransformData(
      rotation: -controller.rotation * (pi / 180.0),
      scale: 1.0,
      translate: Offset.zero,
    );
  }
}
