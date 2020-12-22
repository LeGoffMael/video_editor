import 'package:flutter/material.dart';
import 'package:video_editor/utils/styles.dart';

class CropGridPainter extends CustomPainter {
  CropGridPainter(this.rect, {this.showGrid = false, this.style});

  final Rect rect;
  final bool showGrid;
  final CropGridStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    if (rect != null) {
      _drawBackground(canvas, size);
      if (showGrid) {
        _drawGrid(canvas, size);
        _drawBoundaries(canvas, size);
      }
    }
  }

  void _drawBackground(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = showGrid ? style.croppingBackground : style.background;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, rect.topRight.dy), paint);
    canvas.drawRect(
        Rect.fromLTWH(0.0, rect.bottomLeft.dy, size.width, size.height), paint);
    canvas.drawRect(
        Rect.fromPoints(Offset(0.0, rect.topLeft.dy), rect.bottomLeft), paint);
    canvas.drawRect(
        Rect.fromPoints(rect.topRight, Offset(size.width, rect.bottomRight.dy)),
        paint);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final int gridSize = style.gridSize;
    final Paint paint = Paint()
      ..strokeWidth = style.gridLineWidth
      ..color = style.gridColor;

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
    final double width = style.boundariesWidth;
    final double lenght = style.boundariesLenght;
    final Paint paint = Paint()..color = style.boundariesColor;

    //----//
    //EDGE//
    //----//
    //TOP LEFT |-
    canvas.drawRect(
      Rect.fromPoints(
        rect.topLeft,
        rect.topLeft + Offset(width, lenght),
      ),
      paint,
    );
    canvas.drawRect(
      Rect.fromPoints(
        rect.topLeft + Offset(width, 0.0),
        rect.topLeft + Offset(lenght, width),
      ),
      paint,
    );

    //TOP RIGHT -|
    canvas.drawRect(
      Rect.fromPoints(
        rect.topRight - Offset(lenght, 0.0),
        rect.topRight + Offset(0.0, width),
      ),
      paint,
    );
    canvas.drawRect(
      Rect.fromPoints(
        rect.topRight + Offset(0.0, width),
        rect.topRight - Offset(width, -lenght),
      ),
      paint,
    );

    //BOTTOM RIGHT _|
    canvas.drawRect(
      Rect.fromPoints(
        rect.bottomRight - Offset(width, lenght),
        rect.bottomRight,
      ),
      paint,
    );
    canvas.drawRect(
      Rect.fromPoints(
        rect.bottomRight - Offset(width, 0.0),
        rect.bottomRight - Offset(lenght, width),
      ),
      paint,
    );

    //BOTOM LEFT |_
    canvas.drawRect(
      Rect.fromPoints(
        rect.bottomLeft - Offset(-width, lenght),
        rect.bottomLeft,
      ),
      paint,
    );
    canvas.drawRect(
      Rect.fromPoints(
        rect.bottomLeft - Offset(-width, 0.0),
        rect.bottomLeft + Offset(lenght, -width),
      ),
      paint,
    );

    //------//
    //CENTER//
    //------//
    //TOPCENTER
    canvas.drawRect(
      Rect.fromPoints(
        rect.topCenter + Offset(-lenght / 2, 0.0),
        rect.topCenter + Offset(lenght / 2, width),
      ),
      paint,
    );

    //BOTTOMCENTER
    canvas.drawRect(
      Rect.fromPoints(
        rect.bottomCenter + Offset(-lenght / 2, 0.0),
        rect.bottomCenter + Offset(lenght / 2, -width),
      ),
      paint,
    );

    //CENTERLEFT
    canvas.drawRect(
      Rect.fromPoints(
        rect.centerLeft + Offset(0.0, -lenght / 2),
        rect.centerLeft + Offset(width, lenght / 2),
      ),
      paint,
    );

    //CENTERRIGHT
    canvas.drawRect(
      Rect.fromPoints(
        rect.centerRight + Offset(-width, -lenght / 2),
        rect.centerRight + Offset(0.0, lenght / 2),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(CropGridPainter oldDelegate) => false;

  @override
  bool shouldRebuildSemantics(CropGridPainter oldDelegate) => false;
}
