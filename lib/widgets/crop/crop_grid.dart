import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:video_editor/utils/controller.dart';
import 'package:video_editor/widgets/crop/crop_grid_painter.dart';
import 'package:video_editor/widgets/video/video_viewer.dart';

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
  none
}

class CropGridViewer extends StatefulWidget {
  //It is the viewer that allows you to crop the video
  CropGridViewer({
    Key key,
    @required this.controller,
    this.onChangeCrop,
    this.showGrid = true,
  }) : super(key: key);

  /// If it is true, it shows the grid and allows cropping the video, if it is false
  /// does not show the grid and cannot be cropped
  final bool showGrid;

  ///Essential argument for the functioning of the Widget
  final VideoEditorController controller;

  ///When the pan gesture ended and the cropRect was updated, then it will execute the callback
  final void Function(Offset min, Offset max) onChangeCrop;

  @override
  _CropGridViewerState createState() => _CropGridViewerState();
}

class _CropGridViewerState extends State<CropGridViewer> {
  ValueNotifier<Rect> _rect = ValueNotifier<Rect>(null);
  _CropBoundaries _boundary = _CropBoundaries.none;

  double _boundariesLenght = 0;
  double _boundariesWidth = 0;

  Size _layout = Size.zero;
  Offset _translate = Offset.zero;

  double _rotation = 0.0;
  double _videoAspectRatio = 1.0;
  double _scale = 1.0;
  VideoEditorController _controller;

  @override
  void initState() {
    _controller = widget.controller;
    _boundariesLenght = _controller.cropStyle.boundariesLenght;
    _boundariesWidth = _controller.cropStyle.boundariesWidth;
    _videoAspectRatio = _controller.video.value.aspectRatio;
    super.initState();
  }

  @override
  void didUpdateWidget(CropGridViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.showGrid && !widget.controller.isPlaying) setState(_scaleRect);
  }

  void _onPanStart(DragStartDetails details) {
    final Offset margin = Offset(_boundariesWidth * 5, _boundariesWidth * 5);
    final Offset pos = details.localPosition;
    final Offset max = _rect.value.bottomRight;
    final Offset min = _rect.value.topLeft;

    final List<Offset> minMargin = [min - margin, min + margin];
    final List<Offset> maxMargin = [max - margin, max + margin];

    //IS TOUCHING THE GRID
    if (pos >= minMargin[0] && pos <= maxMargin[1]) {
      final List<Offset> topCenter = [
        _rect.value.topCenter - margin,
        _rect.value.topCenter + margin,
      ];
      final List<Offset> centerLeft = [
        _rect.value.centerLeft - margin,
        _rect.value.centerLeft + margin,
      ];
      final List<Offset> bottomCenter = [
        _rect.value.bottomCenter - margin,
        _rect.value.bottomCenter + margin
      ];
      final List<Offset> centerRight = [
        _rect.value.centerRight - margin,
        _rect.value.centerRight + margin,
      ];

      //CORNERS
      if (pos >= minMargin[0] && pos <= minMargin[1]) {
        _boundary = _CropBoundaries.topLeft;
      } else if (pos >= maxMargin[0] && pos <= maxMargin[1]) {
        _boundary = _CropBoundaries.bottomRight;
      } else if (pos >= Offset(maxMargin[0].dx, minMargin[0].dy) &&
          pos <= Offset(maxMargin[1].dx, minMargin[1].dy)) {
        _boundary = _CropBoundaries.topRight;
      } else if (pos >= Offset(minMargin[0].dx, maxMargin[0].dy) &&
          pos <= Offset(minMargin[1].dx, maxMargin[1].dy)) {
        _boundary = _CropBoundaries.bottomLeft;
        //CENTERS
      } else if (_controller.preferredCropAspectRatio == null) {
        if (pos >= topCenter[0] && pos <= topCenter[1]) {
          _boundary = _CropBoundaries.topCenter;
        } else if (pos >= bottomCenter[0] && pos <= bottomCenter[1]) {
          _boundary = _CropBoundaries.bottomCenter;
        } else if (pos >= centerLeft[0] && pos <= centerLeft[1]) {
          _boundary = _CropBoundaries.centerLeft;
        } else if (pos >= centerRight[0] && pos <= centerRight[1]) {
          _boundary = _CropBoundaries.centerRight;
        }
        //OTHERS
        else if (pos >= minMargin[1] && pos <= maxMargin[0]) {
          _boundary = _CropBoundaries.inside;
        } else {
          _boundary = _CropBoundaries.none;
        }
      } else if (pos >= minMargin[1] && pos <= maxMargin[0]) {
        _boundary = _CropBoundaries.inside;
      } else {
        _boundary = _CropBoundaries.none;
      }
      _controller.isCropping = true;
    } else {
      _boundary = _CropBoundaries.none;
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_boundary != _CropBoundaries.none) {
      final Offset delta = details.delta;

      switch (_boundary) {
        case _CropBoundaries.inside:
          final Offset pos = _rect.value.topLeft + delta;
          _changeRect(left: pos.dx, top: pos.dy);
          break;
        //CORNERS
        case _CropBoundaries.topLeft:
          final Offset pos = _rect.value.topLeft + delta;
          _changeRect(
            top: pos.dy,
            left: pos.dx,
            width: _rect.value.width - delta.dx,
            height: _rect.value.height - delta.dy,
          );
          break;
        case _CropBoundaries.topRight:
          _changeRect(
            top: _rect.value.topRight.dy + delta.dy,
            width: _rect.value.width + delta.dx,
            height: _rect.value.height - delta.dy,
          );
          break;
        case _CropBoundaries.bottomRight:
          _changeRect(
            width: _rect.value.width + delta.dx,
            height: _rect.value.height + delta.dy,
          );
          break;
        case _CropBoundaries.bottomLeft:
          _changeRect(
            left: _rect.value.bottomLeft.dx + delta.dx,
            width: _rect.value.width - delta.dx,
            height: _rect.value.height + delta.dy,
          );
          break;
        //CENTERS
        case _CropBoundaries.topCenter:
          _changeRect(
            top: _rect.value.top + delta.dy,
            height: _rect.value.height - delta.dy,
          );
          break;
        case _CropBoundaries.bottomCenter:
          _changeRect(height: _rect.value.height + delta.dy);
          break;
        case _CropBoundaries.centerLeft:
          _changeRect(
            left: _rect.value.left + delta.dx,
            width: _rect.value.width - delta.dx,
          );
          break;
        case _CropBoundaries.centerRight:
          _changeRect(width: _rect.value.width + delta.dx);
          break;
        case _CropBoundaries.none:
          break;
      }
    }
  }

  void _onPanEnd(_) {
    if (_boundary != _CropBoundaries.none) {
      final Rect rect = _rect.value;
      final double mindx = rect.left / _layout.width;
      final double mindy = rect.top / _layout.height;
      final double maxdx = rect.right / _layout.width;
      final double maxdy = rect.bottom / _layout.height;

      widget.onChangeCrop?.call(Offset(mindx, mindy), Offset(maxdx, maxdy));
      _controller.isCropping = false;
    }
  }

  //-----------//
  //RECT CHANGE//
  //-----------//
  void _changeRect({double left, double top, double width, double height}) {
    top = top ?? _rect.value.top;
    left = left ?? _rect.value.left;
    width = width ?? _rect.value.width;
    height = height ?? _rect.value.height;

    final double right = left + width;
    final double bottom = top + height;
    final double aspect = _controller.preferredCropAspectRatio;

    if (height > _boundariesLenght && width > _boundariesLenght) {
      width = right <= _layout.width ? width : _rect.value.width;

      _rect.value = Rect.fromLTWH(
        left >= 0.0
            ? right <= _layout.width
                ? left
                : _rect.value.left
            : 0.0,
        top >= 0.0
            ? bottom <= _layout.height
                ? top
                : _rect.value.top
            : 0.0,
        width,
        bottom <= _layout.height
            ? aspect == null
                ? height
                : width / aspect
            : _rect.value.height,
      );
    }
  }

  Rect _calculateCropRect() {
    final Offset minCrop = _controller.minCrop;
    final Offset maxCrop = _controller.maxCrop;

    return Rect.fromPoints(
      Offset(minCrop.dx * _layout.width, minCrop.dy * _layout.height),
      Offset(maxCrop.dx * _layout.width, maxCrop.dy * _layout.height),
    );
  }

  void _scaleRect() {
    _rect.value = _calculateCropRect();
    final int degrees = _controller.rotation;
    final double scaleX = _layout.width / _rect.value.width;
    final double scaleY = _layout.height / _rect.value.height;

    if (_videoAspectRatio < 1.0) {
      if (degrees == 90 || degrees == 270)
        _scale = _layout.width / _rect.value.height;
      else
        _scale = scaleX > scaleY ? scaleY : scaleX;
    } else {
      _scale = scaleX < scaleY ? scaleY : scaleX;
    }

    _rotation = -degrees * (math.pi / 180.0);
    _translate = Offset(
          (_layout.width - _rect.value.width) / 2,
          (_layout.height - _rect.value.height) / 2,
        ) -
        _rect.value.topLeft;
  }

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: _rotation,
      child: Transform.scale(
        scale: _scale,
        child: Transform.translate(
          offset: _translate,
          child: VideoViewer(
            controller: _controller,
            child: LayoutBuilder(builder: (_, constraints) {
              Size size = Size(constraints.maxWidth, constraints.maxHeight);
              if (_layout != size) {
                _layout = size;
                _rect.value = _calculateCropRect();
              }

              return widget.showGrid
                  ? GestureDetector(
                      onPanUpdate: _onPanUpdate,
                      onPanStart: _onPanStart,
                      onPanEnd: _onPanEnd,
                      child: _paint(),
                    )
                  : _paint();
            }),
          ),
        ),
      ),
    );
  }

  Widget _paint() {
    return ValueListenableBuilder(
      valueListenable: _rect,
      builder: (_, Rect value, __) {
        return CustomPaint(
          size: Size.infinite,
          painter: CropGridPainter(
            _rect.value,
            style: _controller.cropStyle,
            repaint: widget.showGrid,
            showGrid: widget.showGrid,
            showCenterRects: _controller.preferredCropAspectRatio == null,
          ),
        );
      },
    );
  }
}
