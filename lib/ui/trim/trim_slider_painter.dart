import 'package:flutter/material.dart';
import 'package:video_editor/domain/entities/trim_style.dart';

class TrimSliderPainter extends CustomPainter {
  TrimSliderPainter(
    this.rect,
    this.position,
    this.style, {
    this.isTrimming = false,
  });

  final Rect rect;
  final bool isTrimming;
  final double position;
  final TrimSliderStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final trimColor = isTrimming ? style.onTrimmingColor : style.lineColor;

    final Paint background = Paint()..color = style.background;
    final progress = Paint()
      ..color = style.positionLineColor
      ..strokeWidth = style.positionLineWidth;
    final line = Paint()
      ..color = trimColor
      ..strokeWidth = style.lineWidth
      ..strokeCap = StrokeCap.square;
    final double edgesSize = style.edgesSize;
    final circle = Paint()..color = trimColor;

    final double halfLineWidth = style.lineWidth / 2;
    final double halfHeight = rect.height / 2;

    // BACKGROUND LEFT
    canvas.drawRect(
      Rect.fromPoints(
        Offset.zero,
        rect.bottomLeft,
      ),
      background,
    );

    // BACKGROUND RIGHT
    canvas.drawRect(
      Rect.fromPoints(
        rect.topRight,
        Offset(size.width, size.height),
      ),
      background,
    );

    // TOP RECT
    canvas.drawRect(
      Rect.fromPoints(
        rect.topLeft,
        rect.topRight + Offset(0.0, line.strokeWidth),
      ),
      line,
    );

    // BOTTOM RECT
    canvas.drawRect(
      Rect.fromPoints(
        rect.bottomRight - Offset(line.strokeWidth, line.strokeWidth),
        rect.bottomLeft,
      ),
      line,
    );

    // DRAW VIDEO INDICATOR
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(position - style.positionLineWidth / 2, -4),
          Offset(position + style.positionLineWidth / 2, size.height + 4),
        ),
        Radius.circular(style.positionLineWidth),
      ),
      progress,
    );

    final centerLeft = Offset(rect.left + halfLineWidth, halfHeight);
    final centerRight = Offset(rect.right - halfLineWidth, halfHeight);

    if (style.edgesType == TrimSliderEdgesType.circle) {
      // LEFT RECT
      canvas.drawRect(
        Rect.fromPoints(
          rect.bottomLeft - Offset(-line.strokeWidth, line.strokeWidth),
          rect.topLeft,
        ),
        line,
      );
      // LEFT CIRCLE
      canvas.drawCircle(centerLeft, edgesSize, circle);
      // RIGHT RECT
      canvas.drawRect(
        Rect.fromPoints(
          rect.topRight - Offset(line.strokeWidth, -line.strokeWidth),
          rect.bottomRight,
        ),
        line,
      );
      // RIGHT CIRCLE
      canvas.drawCircle(centerRight, edgesSize, circle);
    } else if (style.edgesType == TrimSliderEdgesType.bar) {
      // LEFT RECT
      canvas.drawRect(
        Rect.fromCenter(
          center: centerLeft - Offset(halfLineWidth, 0),
          width: edgesSize,
          height: size.height,
        ),
        circle,
      );
      // RIGHT RECT
      canvas.drawRect(
        Rect.fromCenter(
          center: centerRight + Offset(halfLineWidth, 0),
          width: edgesSize,
          height: size.height,
        ),
        circle,
      );
    }

    // LEFT ICON
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

    // RIGHT ICON
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
