import 'package:flutter/material.dart';
import 'package:video_editor/utils/controller.dart';
import 'package:video_editor/widgets/crop/crop_grid_painter.dart';
import 'package:video_editor/widgets/video/video_viewer.dart';

enum CropBoundaries { topLeft, topRight, bottomLeft, bottomRight, inside }

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
  CropBoundaries boundary;
  Offset _translate = Offset.zero;
  Size _layout = Size.zero;
  double _scale = 1.0;
  Rect _rect;

  @override
  void didUpdateWidget(CropGridView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.showGrid && !widget.controller.isPlaying)
      setState(() {
        _rect = _calculateCropRect();
        final double _scaleX = _layout.width / _rect.width;
        final double _scaleY = _layout.height / _rect.height;
        _scale = _scaleX < _scaleY ? _scaleX : _scaleY;
        _translate = Offset(
              (_layout.width - _rect.width) / 2,
              (_layout.height - _rect.height) / 2,
            ) -
            _rect.topLeft;
      });
  }

  void onPanStart(details) {
    final Offset pos = details.localPosition;
    final Offset margin = Offset(25.0, 25.0);
    Offset max = _rect.bottomRight;
    Offset min = _rect.topLeft;

    //IS TOUCHING THE GRID
    if (pos >= min - margin && pos <= max + margin) {
      max -= margin;
      min += margin;
      //TOUCH BOUNDARIES
      if (pos <= min) {
        boundary = CropBoundaries.topLeft;
      } else if (pos.dx >= max.dx && pos.dy <= min.dy) {
        boundary = CropBoundaries.topRight;
      } else if (pos.dx <= min.dx && pos.dy >= max.dy) {
        boundary = CropBoundaries.bottomLeft;
      } else if (pos >= max) {
        boundary = CropBoundaries.bottomRight;
      } else {
        boundary = CropBoundaries.inside;
      }
    } else {
      boundary = null;
    }
    setState(() {});
  }

  void onPanUpdate(details) {
    if (boundary != null) {
      final Offset delta = details.delta;
      switch (boundary) {
        case CropBoundaries.topLeft:
          final pos = _rect.topLeft + delta;
          _changeRect(
            top: pos.dy,
            left: pos.dx,
            width: _rect.width - delta.dx,
            height: _rect.height - delta.dy,
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
        case CropBoundaries.bottomRight:
          _changeRect(
            width: _rect.width + delta.dx,
            height: _rect.height + delta.dy,
          );
          break;
        case CropBoundaries.inside:
          final pos = _rect.topLeft + delta;
          _changeRect(left: pos.dx, top: pos.dy);
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
        top + height <= _layout.height) {
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

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: _scale,
      child: Transform.translate(
        offset: _translate,
        child: VideoViewer(controller: widget.controller, children: [
          LayoutBuilder(builder: (_, constraints) {
            _layout = Size(constraints.maxWidth, constraints.maxHeight);
            if (_rect == null) _rect = _calculateCropRect();

            return widget.showGrid
                ? GestureDetector(
                    onPanUpdate: onPanUpdate,
                    onPanStart: onPanStart,
                    onPanEnd: _onPanEnd,
                    child: _paint(),
                  )
                : _paint();
          }),
        ]),
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
