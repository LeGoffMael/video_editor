import 'package:flutter/material.dart';
import 'package:video_editor/domain/bloc/controller.dart';

class TransformData {
  TransformData({
    this.scale = 1.0,
    this.rotation = 0.0,
    this.translate = Offset.zero,
  });
  final double rotation, scale;
  final Offset translate;

  factory TransformData.fromRect(
    Rect rect,
    Size layout,
    VideoEditorController controller,
  ) {
    final double videoAspect = controller.video.value.aspectRatio;
    final double relativeAspect = rect.width / rect.height;

    final double xScale = layout.width / rect.width;
    final double yScale = layout.height / rect.height;

    final double scale = videoAspect < 0.8
        ? relativeAspect <= 1
            ? yScale
            : xScale + videoAspect
        : relativeAspect < 0.8
            ? yScale + videoAspect
            : xScale;

    final double rotation = -controller.rotation * (3.1416 / 180.0);
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
      rotation: -controller.rotation * (3.1416 / 180.0),
      scale: 1.0,
      translate: Offset.zero,
    );
  }
}
