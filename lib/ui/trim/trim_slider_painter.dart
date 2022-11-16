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
    final Paint background = Paint()..color = style.background;

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

    final trimColor = isTrimming ? style.onTrimmingColor : style.lineColor;
    final line = Paint()
      ..color = trimColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.lineWidth;
    final edges = Paint()..color = trimColor;

    final double halfLineWidth = style.lineWidth / 2;
    final double halfHeight = rect.height / 2;

    final centerLeft = Offset(rect.left + halfLineWidth, halfHeight);
    final centerRight = Offset(rect.right - halfLineWidth, halfHeight);

    switch (style.edgesType) {
      case TrimSliderEdgesType.bar:
        paintBar(
          canvas,
          size,
          rrect: rrect,
          line: line,
          edges: edges,
          centerLeft: centerLeft,
          centerRight: centerRight,
          halfLineWidth: halfLineWidth,
        );
        break;
      case TrimSliderEdgesType.circle:
        paintCircle(
          canvas,
          size,
          rrect: rrect,
          line: line,
          edges: edges,
          centerLeft: centerLeft,
          centerRight: centerRight,
        );
        break;
    }
  }

  void paintBar(
    Canvas canvas,
    Size size, {
    required RRect rrect,
    required Paint line,
    required Paint edges,
    required Offset centerLeft,
    required Offset centerRight,
    required double halfLineWidth,
  }) {
    canvas.drawPath(
      Path.combine(
        PathOperation.union,
        // DRAW TOP AND BOTTOM LINES
        Path()
          ..addRect(Rect.fromPoints(
            rect.topLeft,
            rect.topRight + Offset(0.0, line.strokeWidth),
          ))
          ..addRect(
            Rect.fromPoints(
              rect.bottomRight - Offset(line.strokeWidth, line.strokeWidth),
              rect.bottomLeft,
            ),
          ),
        // DRAW EDGES
        Path()
          ..addRRect(
            RRect.fromRectAndCorners(
              Rect.fromCenter(
                center: centerLeft - Offset(halfLineWidth, 0),
                width: style.edgesSize,
                height: size.height,
              ),
              topLeft: Radius.circular(style.borderRadius),
              bottomLeft: Radius.circular(style.borderRadius),
            ),
          )
          ..addRRect(
            RRect.fromRectAndCorners(
              Rect.fromCenter(
                center: centerRight + Offset(halfLineWidth, 0),
                width: style.edgesSize,
                height: size.height,
              ),
              topRight: Radius.circular(style.borderRadius),
              bottomRight: Radius.circular(style.borderRadius),
            ),
          ),
      ),
      edges,
    );

    paintIcons(canvas);

    paintIndicator(canvas, size);
  }

  void paintCircle(
    Canvas canvas,
    Size size, {
    required RRect rrect,
    required Paint line,
    required Paint edges,
    required Offset centerLeft,
    required Offset centerRight,
  }) {
    // DRAW RECT BORDERS
    canvas.drawRRect(rrect, line);

    paintIndicator(canvas, size);

    // LEFT CIRCLE
    canvas.drawCircle(centerLeft, style.edgesSize, edges);
    // RIGHT CIRCLE
    canvas.drawCircle(centerRight, style.edgesSize, edges);

    paintIcons(canvas);
  }

  void paintIndicator(Canvas canvas, Size size) {
    final progress = Paint()
      ..color = style.positionLineColor
      ..strokeWidth = style.positionLineWidth;

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
  }

  void paintIcons(Canvas canvas) {
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
          rect.left - style.iconSize / 2,
          rect.height / 2 - style.iconSize / 2,
        ),
      );
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
        Offset(
          rect.right - style.iconSize / 2,
          rect.height / 2 - style.iconSize / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(TrimSliderPainter oldDelegate) => true;

  @override
  bool shouldRebuildSemantics(TrimSliderPainter oldDelegate) => false;
}
