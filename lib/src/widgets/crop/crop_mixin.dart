import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:video_editor/src/controller.dart';
import 'package:video_editor/src/utils/helpers.dart';
import 'package:video_editor/src/models/transform_data.dart';
import 'package:video_editor/src/widgets/crop/crop_grid.dart';
import 'package:video_editor/src/widgets/crop/crop_grid_painter.dart';
import 'package:video_editor/src/widgets/image_viewer.dart';
import 'package:video_editor/src/widgets/transform.dart';
import 'package:video_editor/src/widgets/video_viewer.dart';

mixin CropPreviewMixin<T extends StatefulWidget> on State<T> {
  final ValueNotifier<Rect> rect = ValueNotifier<Rect>(Rect.zero);
  final ValueNotifier<TransformData> transform =
      ValueNotifier<TransformData>(const TransformData());

  Size viewerSize = Size.zero;
  Size layout = Size.zero;

  @override
  void dispose() {
    transform.dispose();
    rect.dispose();
    super.dispose();
  }

  /// Returns the size of the max crop dimension based on available space and
  /// original video aspect ratio
  Size computeLayout(
    VideoEditorController controller, {
    EdgeInsets margin = EdgeInsets.zero,
    bool shouldFlipped = false,
  }) {
    if (viewerSize == Size.zero) return Size.zero;
    final videoRatio = controller.video.value.aspectRatio;
    final size = Size(viewerSize.width - margin.horizontal,
        viewerSize.height - margin.vertical);
    if (shouldFlipped) {
      return computeSizeWithRatio(videoRatio > 1 ? size.flipped : size,
              getOppositeRatio(videoRatio))
          .flipped;
    }
    return computeSizeWithRatio(size, videoRatio);
  }

  void updateRectFromBuild();

  Widget buildView(BuildContext context, TransformData transform);

  /// Returns the [VideoViewer] tranformed with editing view
  /// Paint rect on top of the video area outside of the crop rect
  Widget buildVideoView(
    VideoEditorController controller,
    TransformData transform,
    CropBoundaries boundary, {
    bool showGrid = false,
  }) {
    return SizedBox.fromSize(
      size: layout,
      child: CropTransformWithAnimation(
        shouldAnimate: layout != Size.zero,
        transform: transform,
        child: VideoViewer(
          controller: controller,
          child: buildPaint(
            controller,
            boundary: boundary,
            showGrid: showGrid,
            showCenterRects: controller.preferredCropAspectRatio == null,
          ),
        ),
      ),
    );
  }

  /// Returns the [ImageViewer] tranformed with editing view
  /// Paint rect on top of the video area outside of the crop rect
  Widget buildImageView(
    VideoEditorController controller,
    Uint8List bytes,
    TransformData transform,
  ) {
    return SizedBox.fromSize(
      size: layout,
      child: CropTransformWithAnimation(
        shouldAnimate: layout != Size.zero,
        transform: transform,
        child: ImageViewer(
          controller: controller,
          bytes: bytes,
          child:
              buildPaint(controller, showGrid: false, showCenterRects: false),
        ),
      ),
    );
  }

  Widget buildPaint(
    VideoEditorController controller, {
    CropBoundaries? boundary,
    bool showGrid = false,
    bool showCenterRects = false,
  }) {
    return ValueListenableBuilder(
      valueListenable: rect,

      /// Build a [Widget] that hides the cropped area and show the crop grid if widget.showGris is true
      builder: (_, Rect value, __) => RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: CropGridPainter(
            value,
            style: controller.cropStyle,
            boundary: boundary,
            showGrid: showGrid,
            showCenterRects: showCenterRects,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      final size = constraints.biggest;
      if (size != viewerSize) {
        viewerSize = constraints.biggest;
        updateRectFromBuild();
      }

      return ValueListenableBuilder(
        valueListenable: transform,
        builder: (_, TransformData transform, __) =>
            buildView(context, transform),
      );
    });
  }
}
