import 'package:flutter/material.dart';
import 'package:video_editor/domain/entities/transform_data.dart';
import 'package:video_editor/ui/crop/crop_animated.dart';
import 'package:video_editor/domain/helpers.dart';
import 'package:video_editor/ui/crop/crop_grid_painter.dart';
import 'package:video_editor/domain/bloc/controller.dart';
import 'package:video_editor/ui/video_viewer.dart';
import 'package:video_editor/ui/transform.dart';

class CropGridViewer extends StatefulWidget {
  /// It is the viewer that allows you to crop the video
  const CropGridViewer({
    Key? key,
    required this.controller,
    this.showGrid = true,
    this.horizontalMargin = 0.0,
    this.scaleAfter = false,
  }) : super(key: key);

  /// The [controller] param is mandatory so every change in the controller settings will propagate in the crop view
  final VideoEditorController controller;

  /// The [showGrid] param specifies whether the crop action can be triggered and if the crop grid is shown.
  /// Set this param to `false` to display the preview of the cropped video
  final bool showGrid;

  /// The [horizontalMargin] param need to be specify when there is a margin outside the crop view,
  /// so in case of a change the new layout can be computed properly (i.e after a rotation)
  final double horizontalMargin;

  /// TODO
  /// Only useful when [showGrid] is `true`
  final bool scaleAfter;

  @override
  State<CropGridViewer> createState() => _CropGridViewerState();
}

class _CropGridViewerState extends State<CropGridViewer> {
  final ValueNotifier<Rect> _rect = ValueNotifier<Rect>(Rect.zero);
  final ValueNotifier<TransformData> _transform =
      ValueNotifier<TransformData>(TransformData());

  Size _viewerSize = Size.zero;
  Size _layout = Size.zero;

  late VideoEditorController _controller;

  @override
  void initState() {
    _controller = widget.controller;
    _controller.addListener(!widget.showGrid ? _scaleRect : _updateRect);
    if (widget.showGrid) {
      _controller.cacheMaxCrop = _controller.maxCrop;
      _controller.cacheMinCrop = _controller.minCrop;

      // init the crop area with preferredCropAspectRatio
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateRect());
    } else {
      // init the widget with controller values if it is not the croping screen
      WidgetsBinding.instance.addPostFrameCallback((_) => _scaleRect());
    }

    super.initState();
  }

  @override
  void dispose() {
    _controller.removeListener(!widget.showGrid ? _scaleRect : _updateRect);
    _transform.dispose();
    _rect.dispose();
    super.dispose();
  }

  /// Update crop [Rect] after change in [_controller] such as change of aspect ratio
  void _updateRect() {
    _transform.value = TransformData.fromController(_controller);
    _calculatePreferedCrop();
  }

  /// Compute new [Rect] crop area depending of [_controller] data and layout size
  void _calculatePreferedCrop() {
    // set cached crop values to adjust it later
    _rect.value = _calculateCropRect(
      _controller.cacheMinCrop,
      _controller.cacheMaxCrop,
    );

    setState(() {
      if (_controller.preferredCropAspectRatio != null) {
        _rect.value = resizeCropToRatio(
          _layout,
          _rect.value,
          _controller.preferredCropAspectRatio!,
        );
      }
      _controller.cacheMinCrop = Offset(
        _rect.value.left / _layout.width,
        _rect.value.top / _layout.height,
      );
      _controller.cacheMaxCrop = Offset(
        _rect.value.right / _layout.width,
        _rect.value.bottom / _layout.height,
      );
      _controller.isCropping = false;
    });
  }

  void _scaleRect() {
    _rect.value = _calculateCropRect();
    _transform.value = TransformData.fromRect(
      _rect.value,
      _layout,
      _viewerSize,
      _controller,
    );
  }

  //-----------//
  //RECT CHANGE//
  //-----------//

  /// Calculate crop [Rect] area
  /// depending of [_controller] min and max crop values and the size of the layout
  Rect _calculateCropRect([Offset? min, Offset? max]) {
    final Offset minCrop = min ?? _controller.minCrop;
    final Offset maxCrop = max ?? _controller.maxCrop;

    return Rect.fromPoints(
      Offset(minCrop.dx * _layout.width, minCrop.dy * _layout.height),
      Offset(maxCrop.dx * _layout.width, maxCrop.dy * _layout.height),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      _viewerSize = constraints.biggest;

      return ValueListenableBuilder(
        valueListenable: _transform,
        builder: (_, TransformData transform, __) => Center(
          child: CropTransform(
            transform: transform,
            child: widget.showGrid
                ? _buildLayout(transform)
                : VideoViewer(
                    controller: _controller,
                    child: _buildLayout(transform),
                  ),
          ),
        ),
      );
    });
  }

  Widget _buildLayout(TransformData transform) {
    return LayoutBuilder(builder: (_, constraints) {
      // final size = (widget.controller.rotation == 90 ||
      //         widget.controller.rotation == 270)
      //     ? constraints.biggest.flipped
      //     : constraints.biggest;
      final size = constraints.biggest;
      final didLayoutSizeChanged = _layout != size;
      _layout = size;

      print('_buildLayout ${widget.controller.rotation}, $size');

      if (widget.showGrid) {
        if (didLayoutSizeChanged) {
          // need to recompute crop if layout size changed, (i.e after rotation)
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _calculatePreferedCrop());
        }

        return ValueListenableBuilder(
          valueListenable: _rect,
          builder: (_, Rect value, __) => AnimatedCropViewer(
            controller: _controller,
            rect: _rect.value,
            layout: _layout,
            scaleAfter: widget.scaleAfter,
            onChangeRect: (rect) => _rect.value = rect,
            child: _buildPaint(value),
          ),
        );
      } else {
        if (didLayoutSizeChanged) {
          _rect.value = _calculateCropRect();
        }

        return ValueListenableBuilder(
          valueListenable: _rect,
          builder: (_, Rect value, __) => _buildPaint(value),
        );
      }
    });
  }

  /// Build [Widget] that hides the cropped area and show the crop grid if widget.showGris is true
  Widget _buildPaint(Rect value) {
    return CustomPaint(
      size: Size.infinite,
      painter: CropGridPainter(
        value,
        style: _controller.cropStyle,
        showGrid: widget.showGrid,
        showCenterRects: _controller.preferredCropAspectRatio == null,
      ),
    );
  }
}
