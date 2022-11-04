import 'package:flutter/material.dart';
import 'package:video_editor/domain/entities/crop_style.dart';

class CropGridPainter extends CustomPainter {
  CropGridPainter(
    this.rect, {
    this.style,
    this.showGrid = false,
    this.showCenterRects = true,
  });

  final Rect rect;
  final CropGridStyle? style;
  final bool showGrid, showCenterRects;

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    if (showGrid) {
      _drawGrid(canvas, size);
      _drawBoundaries(canvas, size);
    }
  }

  void _drawBackground(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = showGrid ? style!.croppingBackground : style!.background;

    // when scaling, the positions might not be exactly accurates
    // so add an extra margin to be sure to overlay all video
    final margin = showGrid ? 0.0 : 1.0;

    // extract [rect] area from the canvas
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()
          ..addRect(Rect.fromLTWH(-margin, -margin, size.width + margin * 2,
              size.height + margin * 2)),
        Path()
          ..addRect(rect)
          ..close(),
      ),
      paint,
    );
  }

  void _drawGrid(Canvas canvas, Size size) {
    final int gridSize = style!.gridSize;
    final Paint paint = Paint()
      ..strokeWidth = style!.gridLineWidth
      ..color = style!.gridLineColor;

    for (int i = 1; i < gridSize; i++) {
      double rowDy = rect.topLeft.dy + (rect.height / gridSize) * i;
      double columnDx = rect.topLeft.dx + (rect.width / gridSize) * i;
      canvas.drawLine(
        Offset(columnDx, rect.topLeft.dy),
        Offset(columnDx, rect.bottomLeft.dy),
        paint,
      );
      canvas.drawLine(
        Offset(rect.topLeft.dx, rowDy),
        Offset(rect.topRight.dx, rowDy),
        paint,
      );
    }
  }

  void _drawBoundaries(Canvas canvas, Size size) {
    final double width = style!.boundariesWidth;
    final double length = style!.boundariesLength;
    final Paint paint = Paint()..color = style!.boundariesColor;

    //----//
    //EDGE//
    //----//
    // TOP LEFT |-
    canvas.drawRect(
      Rect.fromPoints(
        rect.topLeft,
        rect.topLeft + Offset(width, length),
      ),
      paint,
    );
    canvas.drawRect(
      Rect.fromPoints(
        rect.topLeft,
        rect.topLeft + Offset(length, width),
      ),
      paint,
    );

    // TOP RIGHT -|
    canvas.drawRect(
      Rect.fromPoints(
        rect.topRight - Offset(length, 0.0),
        rect.topRight + Offset(0.0, width),
      ),
      paint,
    );
    canvas.drawRect(
      Rect.fromPoints(
        rect.topRight,
        rect.topRight - Offset(width, -length),
      ),
      paint,
    );

    // BOTTOM RIGHT _|
    canvas.drawRect(
      Rect.fromPoints(
        rect.bottomRight - Offset(width, length),
        rect.bottomRight,
      ),
      paint,
    );
    canvas.drawRect(
      Rect.fromPoints(
        rect.bottomRight,
        rect.bottomRight - Offset(length, width),
      ),
      paint,
    );

    // BOTTOM LEFT |_
    canvas.drawRect(
      Rect.fromPoints(
        rect.bottomLeft - Offset(-width, length),
        rect.bottomLeft,
      ),
      paint,
    );
    canvas.drawRect(
      Rect.fromPoints(
        rect.bottomLeft,
        rect.bottomLeft + Offset(length, -width),
      ),
      paint,
    );

    //------//
    //CENTER//
    //------//
    if (showCenterRects) {
      //TOPCENTER
      canvas.drawRect(
        Rect.fromPoints(
          rect.topCenter + Offset(-length / 2, 0.0),
          rect.topCenter + Offset(length / 2, width),
        ),
        paint,
      );

      //BOTTOMCENTER
      canvas.drawRect(
        Rect.fromPoints(
          rect.bottomCenter + Offset(-length / 2, 0.0),
          rect.bottomCenter + Offset(length / 2, -width),
        ),
        paint,
      );

      //CENTERLEFT
      canvas.drawRect(
        Rect.fromPoints(
          rect.centerLeft + Offset(0.0, -length / 2),
          rect.centerLeft + Offset(width, length / 2),
        ),
        paint,
      );

      //CENTERRIGHT
      canvas.drawRect(
        Rect.fromPoints(
          rect.centerRight + Offset(-width, -length / 2),
          rect.centerRight + Offset(0.0, length / 2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CropGridPainter oldDelegate) => true;

  @override
  bool shouldRebuildSemantics(CropGridPainter oldDelegate) => false;
}
