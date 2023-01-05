import 'dart:math';

import 'package:flutter/material.dart';
import 'package:video_editor/domain/entities/transform_data.dart';
import 'package:video_editor/domain/helpers.dart';
import 'package:video_editor/ui/crop/crop_grid_painter.dart';
import 'package:video_editor/domain/bloc/controller.dart';
import 'package:video_editor/ui/video_viewer.dart';
import 'package:video_editor/ui/transform.dart';

@protected
enum CropBoundaries {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  inside,
  topCenter,
  centerRight,
  centerLeft,
  bottomCenter,
  none
}

class CropGridViewer extends StatefulWidget {
  /// It is the viewer that allows you to crop the video
  const CropGridViewer.preview({
    super.key,
    required this.controller,
  })  : showGrid = false,
        rotateCropArea = true,
        margin = EdgeInsets.zero;

  const CropGridViewer.edit({
    super.key,
    required this.controller,
    this.margin = const EdgeInsets.symmetric(horizontal: 20),
    this.rotateCropArea = true,
  }) : showGrid = true;

  /// The [controller] param is mandatory so every change in the controller settings will propagate in the crop view
  final VideoEditorController controller;

  /// The [showGrid] param specifies whether the crop action can be triggered and if the crop grid is shown.
  /// Set this param to `false` to display the preview of the cropped video
  final bool showGrid;

  /// The amount of space by which to inset the crop view, not used in preview mode
  /// so in case of a change the new layout can be computed properly (i.e after a rotation)
  final EdgeInsets margin;

  /// The [rotateCropArea] parameters specifies if the crop should be rotated along
  /// with the video
  /// Set it to `false` to preserve `_controller.preferredAspectRatio` on rotation
  ///
  /// Defaults to `true` (like iOS Photos app crop)
  final bool rotateCropArea;

  @override
  State<CropGridViewer> createState() => _CropGridViewerState();
}

class _CropGridViewerState extends State<CropGridViewer> {
  final ValueNotifier<Rect> _rect = ValueNotifier<Rect>(Rect.zero);
  final ValueNotifier<TransformData> _transform =
      ValueNotifier<TransformData>(const TransformData());

  Size _viewerSize = Size.zero;
  Size _layout = Size.zero;
  CropBoundaries _boundary = CropBoundaries.none;

  late VideoEditorController _controller;

  /// Minimum size of the cropped area
  late final double minRectSize = _controller.cropStyle.boundariesLength * 2;

  @override
  void initState() {
    _controller = widget.controller;
    _controller.addListener(widget.showGrid ? _updateRect : _scaleRect);
    if (widget.showGrid) {
      _controller.cacheMaxCrop = _controller.maxCrop;
      _controller.cacheMinCrop = _controller.minCrop;
    }

    super.initState();
  }

  @override
  void dispose() {
    _controller.removeListener(widget.showGrid ? _updateRect : _scaleRect);
    _transform.dispose();
    _rect.dispose();
    super.dispose();
  }

  /// Returns the proper aspect ratio to apply depending on view rotation
  double? get aspectRatio => widget.rotateCropArea == false &&
          _controller.isRotated &&
          _controller.preferredCropAspectRatio != null
      ? getOppositeRatio(_controller.preferredCropAspectRatio!)
      : _controller.preferredCropAspectRatio;

  /// Returns the size of the max crop dimension based on available space and
  /// original video aspect ratio
  Size computeLayout() {
    if (_viewerSize == Size.zero) return Size.zero;
    final videoRatio = _controller.video.value.aspectRatio;
    final size = Size(_viewerSize.width - widget.margin.horizontal,
        _viewerSize.height - widget.margin.vertical);
    if (_controller.isRotated && widget.showGrid) {
      return computeSizeWithRatio(size, getOppositeRatio(videoRatio)).flipped;
    }
    return computeSizeWithRatio(size, videoRatio);
  }

  /// Update crop [Rect] after change in [_controller] such as change of aspect ratio
  void _updateRect() {
    _layout = computeLayout();
    _transform.value = TransformData.fromController(_controller);
    _calculatePreferedCrop();
  }

  /// Compute new [Rect] crop area depending of [_controller] data and layout size
  void _calculatePreferedCrop() {
    // set cached crop values to adjust it later
    Rect newRect = calculateCroppedRect(
      _controller,
      _layout,
      min: _controller.cacheMinCrop,
      max: _controller.cacheMaxCrop,
    );
    if (_controller.preferredCropAspectRatio != null) {
      newRect = resizeCropToRatio(
        _layout,
        newRect,
        widget.rotateCropArea == false && _controller.isRotated
            ? getOppositeRatio(_controller.preferredCropAspectRatio!)
            : _controller.preferredCropAspectRatio!,
      );
    }

    setState(() {
      _rect.value = newRect;
      _onPanEnd(force: true);
    });
  }

  void _scaleRect() {
    _layout = computeLayout();
    _rect.value = calculateCroppedRect(_controller, _layout);
    _transform.value = TransformData.fromRect(
      _rect.value,
      _layout,
      _viewerSize,
      _controller,
    );
  }

  /// Return [Rect] expanded position to improve touch detection
  Rect _expandedPosition(Offset position) =>
      Rect.fromCenter(center: position, width: 48, height: 48);

  /// Return expanded [Rect] to includes all corners [_expandedPosition]
  Rect _expandedRect() {
    final expandedPosition = _expandedPosition(_rect.value.center);
    return Rect.fromCenter(
        center: _rect.value.center,
        width: _rect.value.width + expandedPosition.width,
        height: _rect.value.height + expandedPosition.height);
  }

  /// Returns the [Offset] to shift [_rect] with to centered in the view
  Offset get gestureOffset => Offset(
        (_viewerSize.width / 2) - (_layout.width / 2),
        (_viewerSize.height / 2) - (_layout.height / 2),
      );

  void _onPanDown(DragDownDetails details) {
    final Offset pos = details.localPosition - gestureOffset;
    _boundary = CropBoundaries.none;

    if (_expandedRect().contains(pos)) {
      _boundary = CropBoundaries.inside;

      // CORNERS
      if (_expandedPosition(_rect.value.topLeft).contains(pos)) {
        _boundary = CropBoundaries.topLeft;
      } else if (_expandedPosition(_rect.value.topRight).contains(pos)) {
        _boundary = CropBoundaries.topRight;
      } else if (_expandedPosition(_rect.value.bottomRight).contains(pos)) {
        _boundary = CropBoundaries.bottomRight;
      } else if (_expandedPosition(_rect.value.bottomLeft).contains(pos)) {
        _boundary = CropBoundaries.bottomLeft;
      } else if (_controller.preferredCropAspectRatio == null) {
        // CENTERS
        if (_expandedPosition(_rect.value.centerLeft).contains(pos)) {
          _boundary = CropBoundaries.centerLeft;
        } else if (_expandedPosition(_rect.value.topCenter).contains(pos)) {
          _boundary = CropBoundaries.topCenter;
        } else if (_expandedPosition(_rect.value.centerRight).contains(pos)) {
          _boundary = CropBoundaries.centerRight;
        } else if (_expandedPosition(_rect.value.bottomCenter).contains(pos)) {
          _boundary = CropBoundaries.bottomCenter;
        }
      }
      setState(() {}); // to update selected boundary color
      _controller.isCropping = true;
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_boundary == CropBoundaries.none) return;
    final Offset delta = details.delta;

    switch (_boundary) {
      case CropBoundaries.inside:
        final Offset pos = _rect.value.topLeft + delta;
        _rect.value = Rect.fromLTWH(
            pos.dx.clamp(0, _layout.width - _rect.value.width),
            pos.dy.clamp(0, _layout.height - _rect.value.height),
            _rect.value.width,
            _rect.value.height);
        break;
      //CORNERS
      case CropBoundaries.topLeft:
        final Offset pos = _rect.value.topLeft + delta;
        _changeRect(left: pos.dx, top: pos.dy);
        break;
      case CropBoundaries.topRight:
        final Offset pos = _rect.value.topRight + delta;
        _changeRect(right: pos.dx, top: pos.dy);
        break;
      case CropBoundaries.bottomRight:
        final Offset pos = _rect.value.bottomRight + delta;
        _changeRect(right: pos.dx, bottom: pos.dy);
        break;
      case CropBoundaries.bottomLeft:
        final Offset pos = _rect.value.bottomLeft + delta;
        _changeRect(left: pos.dx, bottom: pos.dy);
        break;
      //CENTERS
      case CropBoundaries.topCenter:
        _changeRect(top: _rect.value.top + delta.dy);
        break;
      case CropBoundaries.bottomCenter:
        _changeRect(bottom: _rect.value.bottom + delta.dy);
        break;
      case CropBoundaries.centerLeft:
        _changeRect(left: _rect.value.left + delta.dx);
        break;
      case CropBoundaries.centerRight:
        _changeRect(right: _rect.value.right + delta.dx);
        break;
      case CropBoundaries.none:
        break;
    }
  }

  void _onPanEnd({bool force = false}) {
    if (_boundary != CropBoundaries.none || force) {
      final Rect rect = _rect.value;
      _controller.cacheMinCrop = Offset(
        rect.left / _layout.width,
        rect.top / _layout.height,
      );
      _controller.cacheMaxCrop = Offset(
        rect.right / _layout.width,
        rect.bottom / _layout.height,
      );
      _controller.isCropping = false;
      // to update selected boundary color
      setState(() => _boundary = CropBoundaries.none);
    }
  }

  //-----------//
  //RECT CHANGE//
  //-----------//

  /// Update [Rect] crop from incoming values, while respecting [_preferredCropAspectRatio]
  void _changeRect({double? left, double? top, double? right, double? bottom}) {
    top = max(0, top ?? _rect.value.top);
    left = max(0, left ?? _rect.value.left);
    right = min(_layout.width, right ?? _rect.value.right);
    bottom = min(_layout.height, bottom ?? _rect.value.bottom);

    // update crop height or width to adjust to the selected aspect ratio
    if (aspectRatio != null) {
      final width = right - left;
      final height = bottom - top;

      if (width / height > aspectRatio!) {
        switch (_boundary) {
          case CropBoundaries.topLeft:
          case CropBoundaries.bottomLeft:
            left = right - height * aspectRatio!;
            break;
          case CropBoundaries.topRight:
          case CropBoundaries.bottomRight:
            right = left + height * aspectRatio!;
            break;
          default:
            assert(false);
        }
      } else {
        switch (_boundary) {
          case CropBoundaries.topLeft:
          case CropBoundaries.topRight:
            top = bottom - width / aspectRatio!;
            break;
          case CropBoundaries.bottomLeft:
          case CropBoundaries.bottomRight:
            bottom = top + width / aspectRatio!;
            break;
          default:
            assert(false);
        }
      }
    }

    final newRect = Rect.fromLTRB(left, top, right, bottom);

    // don't apply changes if out of bounds
    if (newRect.width < minRectSize ||
        newRect.height < minRectSize ||
        !isRectContained(_layout, newRect)) return;

    _rect.value = newRect;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      final size = constraints.biggest;
      if (size != _viewerSize) {
        _viewerSize = constraints.biggest;
        if (widget.showGrid) {
          // init the crop area with preferredCropAspectRatio
          WidgetsBinding.instance.addPostFrameCallback((_) => _updateRect());
        } else {
          // init the widget with controller values if it is not the croping screen
          _scaleRect();
        }
      }

      return ValueListenableBuilder(
          valueListenable: _transform,
          builder: (_, TransformData transform, __) {
            // return crop view without the grid
            if (widget.showGrid == false) {
              return _buildCropView(constraints, transform);
            }

            // return the crop view with a [GestureDetector] on top to be able to edit the crop parameters
            return Stack(
              alignment: Alignment.center,
              children: [
                _buildCropView(constraints, transform),
                // for development only (rotation not applied)
                // Positioned.fromRect(
                //   rect: _expandedRect().shift(gestureOffset),
                //   child: DecoratedBox(
                //     decoration: BoxDecoration(
                //       color: Colors.greenAccent.withOpacity(0.4),
                //     ),
                //   ),
                // ),
                Transform.rotate(
                  angle: transform.rotation,
                  child: GestureDetector(
                    onPanDown: _onPanDown,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: (_) => _onPanEnd(),
                    onTapUp: (_) => _onPanEnd(),
                    child: const SizedBox.expand(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                            // color: Colors.redAccent.withOpacity(0.4), // dev only
                            ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          });
    });
  }

  /// Returns the [VideoViewer] tranformed with editing view
  /// Paint rect on top of the video area outside of the crop rect
  Widget _buildCropView(BoxConstraints constraints, TransformData transform) {
    return Padding(
      padding: widget.margin,
      child: ConstrainedBox(
        // when widget.showGrid is true, the layout size should never be bigger than the screen size
        constraints: BoxConstraints(
          maxHeight: _controller.isRotated && widget.showGrid
              ? constraints.maxWidth - widget.margin.horizontal
              : Size.infinite.height,
        ),
        child: CropTransformWithAnimation(
          shouldAnimate: _layout != Size.zero,
          transform: transform,
          child: VideoViewer(
            controller: _controller,
            child: ValueListenableBuilder(
              valueListenable: _rect,
              builder: (_, Rect value, __) => _paint(value),
            ),
          ),
        ),
      ),
    );
  }

  /// Build [Widget] that hides the cropped area and show the crop grid if widget.showGris is true
  Widget _paint(Rect value) {
    return CustomPaint(
      size: Size.infinite,
      painter: CropGridPainter(
        value,
        style: _controller.cropStyle,
        boundary: _boundary,
        showGrid: widget.showGrid,
        showCenterRects: _controller.preferredCropAspectRatio == null,
      ),
    );
  }
}
