import 'package:flutter/material.dart';
import 'package:video_editor/domain/entities/transform_data.dart';
import 'package:video_editor/domain/helpers.dart';
import 'package:video_editor/ui/crop/crop_grid_painter.dart';
import 'package:video_editor/domain/bloc/controller.dart';
import 'package:video_editor/ui/video_viewer.dart';
import 'package:video_editor/ui/transform.dart';

enum _CropBoundaries {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  inside,
  topCenter,
  centerRight,
  centerLeft,
  bottomCenter,
  scale,
  none
}

class CropGridViewer extends StatefulWidget {
  /// It is the viewer that allows you to crop the video
  const CropGridViewer({
    super.key,
    required this.controller,
    this.showGrid = true,
    this.horizontalMargin = 0.0,
  });

  /// The [controller] param is mandatory so every change in the controller settings will propagate in the crop view
  final VideoEditorController controller;

  /// The [showGrid] param specifies whether the crop action can be triggered and if the crop grid is shown.
  /// Set this param to `false` to display the preview of the cropped video
  final bool showGrid;

  /// The [horizontalMargin] param need to be specify when there is a margin outside the crop view,
  /// so in case of a change the new layout can be computed properly (i.e after a rotation)
  final double horizontalMargin;

  @override
  State<CropGridViewer> createState() => _CropGridViewerState();
}

class _CropGridViewerState extends State<CropGridViewer> {
  final ValueNotifier<Rect> _rect = ValueNotifier<Rect>(Rect.zero);
  final ValueNotifier<TransformData> _transform =
      ValueNotifier<TransformData>(TransformData());

  Size _viewerSize = Size.zero;
  Size _layout = Size.zero;
  _CropBoundaries _boundary = _CropBoundaries.none;

  double? _preferredCropAspectRatio;
  late VideoEditorController _controller;

  /// Minimum size of the cropped area
  late final double minRectSize = _controller.cropStyle.boundariesLength * 2;

  @override
  void initState() {
    _controller = widget.controller;
    _controller.addListener(!widget.showGrid ? _scaleRect : _updateRect);
    if (widget.showGrid) {
      _controller.cacheMaxCrop = _controller.maxCrop;
      _controller.cacheMinCrop = _controller.minCrop;

      // init the crop area with preferredCropAspectRatio
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateRect();
      });
    } else {
      // init the widget with controller values if it is not the croping screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scaleRect();
      });
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
    _preferredCropAspectRatio = _controller.preferredCropAspectRatio;

    // set cached crop values to adjust it later
    _rect.value = _calculateCropRect(
      _controller.cacheMinCrop,
      _controller.cacheMaxCrop,
    );

    setState(() {
      if (_preferredCropAspectRatio != null) {
        _rect.value = resizeCropToRatio(
          _layout,
          _rect.value,
          _preferredCropAspectRatio!,
        );
      }
      _onScaleEnd(force: true);
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

  /// Return [Rect] expanded position to improve grab facility, the size will be equal to a single grid square
  Rect _expandedPosition(Offset position) => Rect.fromCenter(
        center: position,
        // the width of one grid square
        width: (_rect.value.width / _controller.cropStyle.gridSize),
        // the height of one grid square
        height: (_rect.value.height / _controller.cropStyle.gridSize),
      );

  /// Return expanded [Rect] to includes all corners [_expandedPosition]
  Rect _expandedRect() {
    Rect expandedPosition = _expandedPosition(_rect.value.center);
    return Rect.fromCenter(
        center: _rect.value.center,
        width: _rect.value.width + expandedPosition.width,
        height: _rect.value.height + expandedPosition.height);
  }

  void _onScaleStart(ScaleStartDetails details) {
    final Offset pos = details.localFocalPoint;
    _boundary = _CropBoundaries.none;

    if (details.pointerCount > 1) {
      _boundary = _CropBoundaries.scale;
    } else if (_expandedRect().contains(pos)) {
      if (_rect.value.contains(pos)) {
        _boundary = _CropBoundaries.inside;
      }

      // CORNERS
      if (_expandedPosition(_rect.value.topLeft).contains(pos)) {
        _boundary = _CropBoundaries.topLeft;
      } else if (_expandedPosition(_rect.value.topRight).contains(pos)) {
        _boundary = _CropBoundaries.topRight;
      } else if (_expandedPosition(_rect.value.bottomRight).contains(pos)) {
        _boundary = _CropBoundaries.bottomRight;
      } else if (_expandedPosition(_rect.value.bottomLeft).contains(pos)) {
        _boundary = _CropBoundaries.bottomLeft;
      } else if (_controller.preferredCropAspectRatio == null) {
        // CENTERS
        if (_expandedPosition(_rect.value.centerLeft).contains(pos)) {
          _boundary = _CropBoundaries.centerLeft;
        } else if (_expandedPosition(_rect.value.topCenter).contains(pos)) {
          _boundary = _CropBoundaries.topCenter;
        } else if (_expandedPosition(_rect.value.centerRight).contains(pos)) {
          _boundary = _CropBoundaries.centerRight;
        } else if (_expandedPosition(_rect.value.bottomCenter).contains(pos)) {
          _boundary = _CropBoundaries.bottomCenter;
        }
      }
    }
    _controller.isCropping = true;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_boundary == _CropBoundaries.none) return;

    final Offset delta = details.focalPointDelta;

    switch (_boundary) {
      case _CropBoundaries.inside:
        final Offset pos = _rect.value.topLeft + delta;
        _rect.value = Rect.fromLTWH(
            pos.dx.clamp(0, _layout.width - _rect.value.width),
            pos.dy.clamp(0, _layout.height - _rect.value.height),
            _rect.value.width,
            _rect.value.height);
        break;
      //CORNERS
      case _CropBoundaries.topLeft:
        final Offset pos = _rect.value.topLeft + delta;
        _changeRect(left: pos.dx, top: pos.dy);
        break;
      case _CropBoundaries.topRight:
        final Offset pos = _rect.value.topRight + delta;
        _changeRect(right: pos.dx, top: pos.dy);
        break;
      case _CropBoundaries.bottomRight:
        final Offset pos = _rect.value.bottomRight + delta;
        _changeRect(right: pos.dx, bottom: pos.dy);
        break;
      case _CropBoundaries.bottomLeft:
        final Offset pos = _rect.value.bottomLeft + delta;
        _changeRect(left: pos.dx, bottom: pos.dy);
        break;
      //CENTERS
      case _CropBoundaries.topCenter:
        _changeRect(top: _rect.value.top + delta.dy);
        break;
      case _CropBoundaries.bottomCenter:
        _changeRect(bottom: _rect.value.bottom + delta.dy);
        break;
      case _CropBoundaries.centerLeft:
        _changeRect(left: _rect.value.left + delta.dx);
        break;
      case _CropBoundaries.centerRight:
        _changeRect(right: _rect.value.right + delta.dx);
        break;
      case _CropBoundaries.scale:
        final scale = details.scale.clamp(
            0.975,
            minOf3(
              _layout.height / _rect.value.size.height,
              _layout.width / _rect.value.size.width,
              1.025,
            ));
        _changeRectFromRect(scaleRectInSize(_rect.value, scale, _layout));
        break;
      case _CropBoundaries.none:
        break;
    }
  }

  void _onScaleEnd({bool force = false}) {
    if (_boundary != _CropBoundaries.none || force) {
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
    }
    _boundary = _CropBoundaries.none;
  }

  //-----------//
  //RECT CHANGE//
  //-----------//

  void _changeRectFromRect(Rect rect) => _changeRect(
      left: rect.left, top: rect.top, right: rect.right, bottom: rect.bottom);

  /// Update [Rect] crop from incoming values, while respecting [_preferredCropAspectRatio]
  void _changeRect({double? left, double? top, double? right, double? bottom}) {
    top = top ?? _rect.value.top;
    left = left ?? _rect.value.left;
    right = right ?? _rect.value.right;
    bottom = bottom ?? _rect.value.bottom;

    // update crop height or width to adjust to the selected aspect ratio
    if (_preferredCropAspectRatio != null) {
      final width = right - left;
      final height = bottom - top;

      if (width / height > _preferredCropAspectRatio!) {
        switch (_boundary) {
          case _CropBoundaries.topLeft:
          case _CropBoundaries.bottomLeft:
            left = right - height * _preferredCropAspectRatio!;
            break;
          case _CropBoundaries.topRight:
          case _CropBoundaries.bottomRight:
            right = left + height * _preferredCropAspectRatio!;
            break;
          default:
            break;
        }
      } else {
        switch (_boundary) {
          case _CropBoundaries.topLeft:
          case _CropBoundaries.topRight:
            top = bottom - width / _preferredCropAspectRatio!;
            break;
          case _CropBoundaries.bottomLeft:
          case _CropBoundaries.bottomRight:
            bottom = top + width / _preferredCropAspectRatio!;
            break;
          default:
            break;
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
            child: Container(
                // when widget.showGrid is true, the layout size should never be bigger than the screen size
                constraints: BoxConstraints(
                    maxHeight: ((_controller.rotation == 90 ||
                                _controller.rotation == 270)) &&
                            widget.showGrid
                        ? MediaQuery.of(context).size.width -
                            widget.horizontalMargin
                        : Size.infinite.height),
                child: CropTransform(
                    transform: transform,
                    child: VideoViewer(
                      controller: _controller,
                      child: LayoutBuilder(builder: (_, constraints) {
                        Size size = constraints.biggest;
                        if (_layout != size) {
                          _layout = size;
                          if (widget.showGrid) {
                            // need to recompute crop if layout size changed, (i.e after rotation)
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _calculatePreferedCrop();
                            });
                          } else {
                            _rect.value = _calculateCropRect();
                          }
                        }
                        return ValueListenableBuilder(
                            valueListenable: _rect,
                            builder: (_, Rect value, __) {
                              return widget.showGrid
                                  ? GestureDetector(
                                      onScaleStart: _onScaleStart,
                                      onScaleUpdate: _onScaleUpdate,
                                      onScaleEnd: (_) => _onScaleEnd(),
                                      child: _paint(value),
                                    )
                                  : _paint(value);
                            });
                      }),
                    )))),
      );
    });
  }

  /// Build [Widget] that hides the cropped area and show the crop grid if widget.showGris is true
  Widget _paint(Rect value) {
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
