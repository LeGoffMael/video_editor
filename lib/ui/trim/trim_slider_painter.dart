import 'package:flutter/material.dart';
import 'package:video_editor/domain/entities/trim_style.dart';

class TrimSliderPainter extends CustomPainter {
  TrimSliderPainter(this.rect, this.position, this.style);

  final Rect rect;
  final double position;
  final TrimSliderStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint background = Paint()..color = style.background;
    final progress = Paint()
      ..color = style.positionLineColor
      ..strokeWidth = style.positionLineWidth;
    final line = Paint()
      ..color = style.lineColor
      ..strokeWidth = style.lineWidth
      ..strokeCap = StrokeCap.square;
    final double circleRadius = style.circleSize;
    final circle = Paint()..color = style.lineColor;

    final double halfLineWidth = style.lineWidth / 2;
    final double halfHeight = rect.height / 2;

    canvas.drawRect(
      Rect.fromPoints(
        Offset(position - halfLineWidth, 0.0),
        Offset(position + halfLineWidth, size.height),
      ),
      progress,
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
        rect.topRight + Offset(0.0, line.strokeWidth),
      ),
      line,
    );

    //RIGHT RECT
    canvas.drawRect(
      Rect.fromPoints(
        rect.topRight - Offset(line.strokeWidth, -line.strokeWidth),
        rect.bottomRight,
      ),
      line,
    );

    //BOTTOM RECT
    canvas.drawRect(
      Rect.fromPoints(
        rect.bottomRight - Offset(line.strokeWidth, line.strokeWidth),
        rect.bottomLeft,
      ),
      line,
    );

    //LEFT RECT
    canvas.drawRect(
      Rect.fromPoints(
        rect.bottomLeft - Offset(-line.strokeWidth, line.strokeWidth),
        rect.topLeft,
      ),
      line,
    );

    //LEFT CIRCLE
    canvas.drawCircle(
      Offset(rect.left + halfLineWidth, halfHeight),
      circleRadius,
      circle,
    );

    //LEFT ARROW
    if (style.leftIcon != null) {
      TextPainter leftArrow = TextPainter(textDirection: TextDirection.rtl);
      leftArrow.text = TextSpan(
          text: String.fromCharCode(style.leftIcon!.codePoint),
          style: TextStyle(
              fontSize: style.iconSize,
              fontFamily: style.leftIcon!.fontFamily,
              color: style.iconColor));
      leftArrow.layout();
      leftArrow.paint(
          canvas,
          Offset(
              rect.left - style.iconSize / 2, halfHeight - style.iconSize / 2));
    }

    //RIGHT CIRCLE
    canvas.drawCircle(
      Offset(rect.right - halfLineWidth, halfHeight),
      circleRadius,
      circle,
    );

    //RIGHT ARROW
    if (style.rightIcon != null) {
      TextPainter rightArrow = TextPainter(textDirection: TextDirection.rtl);
      rightArrow.text = TextSpan(
          text: String.fromCharCode(style.rightIcon!.codePoint),
          style: TextStyle(
              fontSize: style.iconSize,
              fontFamily: style.rightIcon!.fontFamily,
              color: style.iconColor));
      rightArrow.layout();
      rightArrow.paint(
          canvas,
          Offset(rect.right - style.iconSize / 2,
              halfHeight - style.iconSize / 2));
    }
  }

  @override
  bool shouldRepaint(TrimSliderPainter oldDelegate) => true;

  @override
  bool shouldRebuildSemantics(TrimSliderPainter oldDelegate) => false;
}
