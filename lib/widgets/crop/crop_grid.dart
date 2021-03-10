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
  _CropBoundaries boundary = _CropBoundaries.none;

  double _boundariesLenght = 0;
  double _boundariesWidth = 0;

  Size _layout = Size.zero;
  Offset _translate = Offset.zero;
  Offset _maxCrop = Offset(1.0, 1.0), _minCrop = Offset.zero;

  double _rotation = 0.0;
  double _aspect = 1.0;
  double _scale = 1.0;
  VideoEditorController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _boundariesLenght = _controller.cropStyle.boundariesLenght;
    _boundariesWidth = _controller.cropStyle.boundariesWidth;
    _aspect = _controller.video.value.aspectRatio;
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
        boundary = _CropBoundaries.topLeft;
      } else if (pos >= maxMargin[0] && pos <= maxMargin[1]) {
        boundary = _CropBoundaries.bottomRight;
      } else if (pos >= Offset(maxMargin[0].dx, minMargin[0].dy) &&
          pos <= Offset(maxMargin[1].dx, minMargin[1].dy)) {
        boundary = _CropBoundaries.topRight;
      } else if (pos >= Offset(minMargin[0].dx, maxMargin[0].dy) &&
          pos <= Offset(minMargin[1].dx, maxMargin[1].dy)) {
        boundary = _CropBoundaries.bottomLeft;
        //CENTERS
      } else if (_controller.preferredCropAspectRatio == null) {
        if (pos >= topCenter[0] && pos <= topCenter[1]) {
          boundary = _CropBoundaries.topCenter;
        } else if (pos >= bottomCenter[0] && pos <= bottomCenter[1]) {
          boundary = _CropBoundaries.bottomCenter;
        } else if (pos >= centerLeft[0] && pos <= centerLeft[1]) {
          boundary = _CropBoundaries.centerLeft;
        } else if (pos >= centerRight[0] && pos <= centerRight[1]) {
          boundary = _CropBoundaries.centerRight;
        }
        //OTHERS
        else if (pos >= minMargin[1] && pos <= maxMargin[0]) {
          boundary = _CropBoundaries.inside;
        } else {
          boundary = _CropBoundaries.none;
        }
      } else {
        boundary = _CropBoundaries.none;
      }
      _controller.isCropping = true;
    } else {
      boundary = _CropBoundaries.none;
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (boundary != _CropBoundaries.none) {
      final Offset delta = details.delta;
      switch (boundary) {
        case _CropBoundaries.inside:
          final Offset pos = _rect.value.topLeft + delta;
          _changeRect(left: pos.dx, top: pos.dy);
          break;
        case _CropBoundaries.topLeft:
          final Offset pos = _rect.value.topLeft + delta;
          _changeRect(
            top: pos.dy,
            left: pos.dx,
            width: _rect.value.width - delta.dx,
            height: _rect.value.height - delta.dy,
          );
          break;
        case _CropBoundaries.bottomRight:
          _changeRect(
            width: _rect.value.width + delta.dx,
            height: _rect.value.height + delta.dy,
          );
          break;
        case _CropBoundaries.topRight:
          _changeRect(
            top: _rect.value.topRight.dy + delta.dy,
            width: _rect.value.width + delta.dx,
            height: _rect.value.height - delta.dy,
          );
          break;
        case _CropBoundaries.bottomLeft:
          _changeRect(
            left: _rect.value.bottomLeft.dx + delta.dx,
            width: _rect.value.width - delta.dx,
            height: _rect.value.height + delta.dy,
          );
          break;
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
    if (boundary != _CropBoundaries.none) {
      widget.onChangeCrop?.call(_minCrop, _maxCrop);
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
    final double mindx = left / _layout.width;
    final double mindy = top / _layout.height;
    final double maxdy = bottom / _layout.height;
    final double maxdx = right / _layout.width;

    final minCrop = Offset(mindx, mindy);
    final maxCrop = Offset(maxdx, maxdy);
    final minCropLimit = _controller.minCropLimit;
    final maxCropLimit = _controller.maxCropLimit;

    if (height > _boundariesLenght &&
        width > _boundariesLenght &&
        minCrop >= minCropLimit &&
        maxCrop <= maxCropLimit) {
      _minCrop = minCrop;
      _maxCrop = maxCrop;
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
        right <= _layout.width ? width : _rect.value.width,
        bottom <= _layout.height ? height : _rect.value.height,
      );
    }
  }

  Rect _calculateCropRect() {
    final double aspectRatio = _controller.preferredCropAspectRatio;
    _minCrop = _controller.minCrop;
    _maxCrop = _controller.maxCrop;
    if (aspectRatio == null)
      return Rect.fromPoints(
        Offset(_minCrop.dx * _layout.width, _minCrop.dy * _layout.height),
        Offset(_maxCrop.dx * _layout.width, _maxCrop.dy * _layout.height),
      );
    else {
      final width = (_maxCrop.dx - _minCrop.dx) * _layout.width;
      return Rect.fromLTWH(
        _minCrop.dx,
        _minCrop.dy,
        width,
        width * aspectRatio,
      );
    }
  }

  void _scaleRect() {
    _rect.value = _calculateCropRect();
    final int degrees = _controller.rotation;
    final double scaleX = _layout.width / _rect.value.width;
    final double scaleY = _layout.height / _rect.value.height;

    if (_aspect < 1.0) {
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
                _scaleRect();
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
            showGrid: widget.showGrid,
            showCenterRects: _controller.preferredCropAspectRatio == null,
          ),
        );
      },
    );
  }
}
