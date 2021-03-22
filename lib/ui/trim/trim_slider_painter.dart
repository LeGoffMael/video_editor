import 'package:flutter/material.dart';
import 'package:video_editor/domain/entities/trim_style.dart';

class TrimSliderPainter extends CustomPainter {
  TrimSliderPainter(this.rect, this.position, {this.style});

  final Rect rect;
  final double position;
  final TrimSliderStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final double width = style.lineWidth;
    final double radius = style.dotRadius;
    final double halfWidth = width / 2;
    final double halfHeight = rect.height / 2;
    final Paint dotPaint = Paint()..color = style.dotColor;
    final Paint linePaint = Paint()..color = style.lineColor;
    final Paint progressPaint = Paint()..color = style.positionLineColor;
    final Paint background = Paint()..color = Colors.black.withOpacity(0.6);

    canvas.drawRect(
      Rect.fromPoints(
        Offset(position - halfWidth, 0.0),
        Offset(position + halfWidth, size.height),
      ),
      progressPaint,
    );

    //BACKGROUND LEFT
    canvas.drawRect(
      Rect.fromPoints(
        Offset.zero,
        rect.bottomLeft,
      ),
      background,
    );

    //BACKGROUND RIGHT
    canvas.drawRect(
      Rect.fromPoints(
        rect.topRight,
        Offset(size.width, size.height),
      ),
      background,
    );

    //TOP RECT
    canvas.drawRect(
      Rect.fromPoints(
        rect.topLeft,
        rect.topRight + Offset(0.0, width),
      ),
      linePaint,
    );

    //RIGHT RECT
    canvas.drawRect(
      Rect.fromPoints(
        rect.topRight - Offset(width, -width),
        rect.bottomRight,
      ),
      linePaint,
    );

    //BOTTOM RECT
    canvas.drawRect(
      Rect.fromPoints(
        rect.bottomRight - Offset(width, width),
        rect.bottomLeft,
      ),
      linePaint,
    );

    //LEFT RECT
    canvas.drawRect(
      Rect.fromPoints(
        rect.bottomLeft - Offset(-width, width),
        rect.topLeft,
      ),
      linePaint,
    );

    //LECT CIRCLE
    canvas.drawCircle(
      Offset(rect.left + halfWidth, halfHeight),
      radius,
      dotPaint,
    );

    //RIGHT CIRCLE
    canvas.drawCircle(
      Offset(rect.right - halfWidth, halfHeight),
      radius,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(TrimSliderPainter oldDelegate) => true;

  @override
  bool shouldRebuildSemantics(TrimSliderPainter oldDelegate) => false;
}
