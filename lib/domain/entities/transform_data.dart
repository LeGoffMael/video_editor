import 'package:flutter/material.dart';
import 'package:video_editor/domain/bloc/controller.dart';

class TransformData {
  TransformData({
    required this.scale,
    required this.rotation,
    required this.translate,
  });
  double rotation, scale;
  Offset translate;

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
        ? relativeAspect < 0.8
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
}
