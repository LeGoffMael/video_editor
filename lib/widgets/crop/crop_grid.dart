import 'package:flutter/material.dart';
import 'package:video_editor/utils/controller.dart';
import 'package:video_editor/widgets/crop/crop_grid_painter.dart';
import 'package:video_editor/widgets/video/video_viewer.dart';

enum CropBoundaries {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  inside,
  topCenter,
  centerRight,
  centerLeft,
  bottomCenter
}

class CropGridView extends StatefulWidget {
  CropGridView({
    Key key,
    @required this.controller,
    this.onChangeCrop,
    this.showGrid = true,
  }) : super(key: key);

  final bool showGrid;
  final VideoEditorController controller;
  final void Function(Offset mixCrop, Offset maxCrop) onChangeCrop;

  @override
  _CropGridViewState createState() => _CropGridViewState();
}

class _CropGridViewState extends State<CropGridView> {
  double _boundariesLenght = 0;
  double _boundariesWidth = 0;
  Offset _translate = Offset.zero;
  double _aspect = 1.0;
  double _scale = 1.0;
  Size _layout = Size.zero;
  CropBoundaries boundary;
  Orientation _orientation;
  Rect _rect;

  @override
  void initState() {
    super.initState();
    _boundariesWidth = widget.controller.cropStyle.boundariesWidth;
    _boundariesLenght = widget.controller.cropStyle.boundariesLenght;
    _aspect = widget.controller.videoController.value.aspectRatio;
  }

  @override
  void didUpdateWidget(CropGridView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.showGrid && !widget.controller.isPlaying)
      setState(() => _scaleRect());
  }

  void onPanStart(details) {
    final Offset margin = Offset(_boundariesWidth * 5, _boundariesWidth * 5);
    final Offset pos = details.localPosition;
    final Offset max = _rect.bottomRight;
    final Offset min = _rect.topLeft;
    final List<Offset> minMargin = [min - margin, min + margin];
    final List<Offset> maxMargin = [max - margin, max + margin];

    //IS TOUCHING THE GRID
    if (pos >= minMargin[0] && pos <= maxMargin[1]) {
      final List<Offset> topCenter = [
        _rect.topCenter - margin,
        _rect.topCenter + margin,
      ];
      final List<Offset> centerLeft = [
        _rect.centerLeft - margin,
        _rect.centerLeft + margin,
      ];
      final List<Offset> bottomCenter = [
        _rect.bottomCenter - margin,
        _rect.bottomCenter + margin
      ];
      final List<Offset> centerRight = [
        _rect.centerRight - margin,
        _rect.centerRight + margin,
      ];

      //TOUCH BOUNDARIES
      if (pos >= minMargin[0] && pos <= minMargin[1])
        boundary = CropBoundaries.topLeft;
      else if (pos >= maxMargin[0] && pos <= maxMargin[1])
        boundary = CropBoundaries.bottomRight;
      else if (pos >= Offset(maxMargin[0].dx, minMargin[0].dy) &&
          pos <= Offset(maxMargin[1].dx, minMargin[1].dy))
        boundary = CropBoundaries.topRight;
      else if (pos >= Offset(minMargin[0].dx, maxMargin[0].dy) &&
          pos <= Offset(minMargin[1].dx, maxMargin[1].dy))
        boundary = CropBoundaries.bottomLeft;
      else if (pos >= topCenter[0] && pos <= topCenter[1])
        boundary = CropBoundaries.topCenter;
      else if (pos >= bottomCenter[0] && pos <= bottomCenter[1])
        boundary = CropBoundaries.bottomCenter;
      else if (pos >= centerLeft[0] && pos <= centerLeft[1])
        boundary = CropBoundaries.centerLeft;
      else if (pos >= centerRight[0] && pos <= centerRight[1])
        boundary = CropBoundaries.centerRight;
      else if (pos >= minMargin[1] && pos <= maxMargin[0])
        boundary = CropBoundaries.inside;
      else
        boundary = null;
    } else
      boundary = null;

    setState(() {});
  }

  void onPanUpdate(details) {
    if (boundary != null) {
      final Offset delta = details.delta;
      switch (boundary) {
        case CropBoundaries.inside:
          final Offset pos = _rect.topLeft + delta;
          _changeRect(left: pos.dx, top: pos.dy);
          break;
        case CropBoundaries.topLeft:
          final Offset pos = _rect.topLeft + delta;
          _changeRect(
            top: pos.dy,
            left: pos.dx,
            width: _rect.width - delta.dx,
            height: _rect.height - delta.dy,
          );
          break;
        case CropBoundaries.bottomRight:
          _changeRect(
            width: _rect.width + delta.dx,
            height: _rect.height + delta.dy,
          );
          break;
        case CropBoundaries.topRight:
          _changeRect(
            top: _rect.topRight.dy + delta.dy,
            width: _rect.width + delta.dx,
            height: _rect.height - delta.dy,
          );
          break;
        case CropBoundaries.bottomLeft:
          _changeRect(
            left: _rect.bottomLeft.dx + delta.dx,
            width: _rect.width - delta.dx,
            height: _rect.height + delta.dy,
          );
          break;
        case CropBoundaries.topCenter:
          _changeRect(
            top: _rect.top + delta.dy,
            height: _rect.height - delta.dy,
          );
          break;
        case CropBoundaries.bottomCenter:
          _changeRect(height: _rect.height + delta.dy);
          break;
        case CropBoundaries.centerLeft:
          _changeRect(
            left: _rect.left + delta.dx,
            width: _rect.width - delta.dx,
          );
          break;
        case CropBoundaries.centerRight:
          _changeRect(width: _rect.width + delta.dx);
          break;
      }
    }
  }

  void _onPanEnd(_) {
    if (widget.onChangeCrop != null) {
      final double mindx = _rect.left / _layout.width;
      final double mindy = _rect.top / _layout.height;
      final double maxdy = _rect.bottom / _layout.height;
      final double maxdx = _rect.right / _layout.width;
      widget.onChangeCrop(Offset(mindx, mindy), Offset(maxdx, maxdy));
    }
  }

  //-----------//
  //RECT CHANGE//
  //-----------//
  void _changeRect({double left, double top, double width, double height}) {
    top = top ?? _rect.top;
    left = left ?? _rect.left;
    width = width ?? _rect.width;
    height = height ?? _rect.height;
    if (left >= 0.0 &&
        top >= 0.0 &&
        left + width <= _layout.width &&
        top + height <= _layout.height &&
        height > _boundariesLenght &&
        width > _boundariesLenght) {
      _rect = Rect.fromLTWH(left, top, width, height);
      setState(() {});
    }
  }

  Rect _calculateCropRect() {
    final Offset min = widget.controller.minCrop;
    final Offset max = widget.controller.maxCrop;
    return Rect.fromPoints(
      Offset(min.dx * _layout.width, min.dy * _layout.height),
      Offset(max.dx * _layout.width, max.dy * _layout.height),
    );
  }

  void _scaleRect() {
    _rect = _calculateCropRect();
    final double _scaleX = _layout.width / _rect.width;
    final double _scaleY = _layout.height / _rect.height;
    if (_aspect < 1.0)
      _scale = _scaleX > _scaleY ? _scaleY : _scaleX;
    else
      _scale = _scaleX < _scaleY ? _scaleY : _scaleX;
    _translate = Offset(
          (_layout.width - _rect.width) / 2,
          (_layout.height - _rect.height) / 2,
        ) -
        _rect.topLeft;
  }

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: _scale,
      child: Transform.translate(
        offset: _translate,
        child: OrientationBuilder(
          builder: (_, orientation) {
            return VideoViewer(
              controller: widget.controller,
              child: LayoutBuilder(builder: (_, constraints) {
                _layout = Size(constraints.maxWidth, constraints.maxHeight);
                if (orientation != _orientation) {
                  _orientation = orientation;
                  _rect = _calculateCropRect();
                }
                return widget.showGrid
                    ? GestureDetector(
                        onPanUpdate: onPanUpdate,
                        onPanStart: onPanStart,
                        onPanEnd: _onPanEnd,
                        child: _paint(),
                      )
                    : _paint();
              }),
            );
          },
        ),
      ),
    );
  }

  Widget _paint() {
    return CustomPaint(
      size: Size.infinite,
      painter: CropGridPainter(
        _rect,
        showGrid: widget.showGrid,
        style: widget.controller.cropStyle,
      ),
    );
  }
}
