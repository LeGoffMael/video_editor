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
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.lineWidth;
    final circle = Paint()..color = trimColor;

    final double halfLineWidth = style.lineWidth / 2;
    final double halfHeight = rect.height / 2;

    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(style.borderRadius),
    );

    // DRAW LEFT AND RIGHT BACKGROUNDS
    // extract [rect] trimmed area from the canvas
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()
          ..addRRect(rrect)
          ..close(),
      ),
      background,
    );

    // DRAW RECT BORDERS
    canvas.drawRRect(rrect, line);

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
      // LEFT CIRCLE
      canvas.drawCircle(centerLeft, style.edgesSize, circle);
      // RIGHT CIRCLE
      canvas.drawCircle(centerRight, style.edgesSize, circle);
    } else if (style.edgesType == TrimSliderEdgesType.bar) {
      // LEFT RECT
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromCenter(
            center: centerLeft - Offset(halfLineWidth, 0),
            width: style.edgesSize,
            height: size.height + style.lineWidth,
          ),
          topLeft: Radius.circular(style.borderRadius),
          bottomLeft: Radius.circular(style.borderRadius),
        ),
        circle,
      );
      // RIGHT RECT
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromCenter(
            center: centerRight + Offset(halfLineWidth, 0),
            width: style.edgesSize,
            height: size.height + style.lineWidth,
          ),
          topRight: Radius.circular(style.borderRadius),
          bottomRight: Radius.circular(style.borderRadius),
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
