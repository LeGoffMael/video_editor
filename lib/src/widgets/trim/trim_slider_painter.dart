import 'package:flutter/material.dart';
import 'package:video_editor/src/models/trim_style.dart';

class TrimSliderPainter extends CustomPainter {
  const TrimSliderPainter(
    this.rect,
    this.position,
    this.style, {
    this.isTrimming = false,
    this.isTrimmed = false,
  });

  final Rect rect;
  final bool isTrimming, isTrimmed;
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

    final trimColor = isTrimming
        ? style.onTrimmingColor
        : isTrimmed
            ? style.onTrimmedColor
            : style.lineColor;
    final line = Paint()
      ..color = trimColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.lineWidth;
    final edges = Paint()..color = trimColor;

    final double halfLineWidth = style.edgeWidth / 2;
    final double halfHeight = rect.height / 2;

    final centerLeft = Offset(rect.left - halfLineWidth, halfHeight);
    final centerRight = Offset(rect.right + halfLineWidth, halfHeight);

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
            rect.topRight - Offset(0.0, style.lineWidth),
          ))
          ..addRect(
            Rect.fromPoints(
              rect.bottomRight + Offset(0.0, style.lineWidth),
              rect.bottomLeft,
            ),
          ),
        // DRAW EDGES
        getEdgesBarPath(
          size,
          centerLeft: centerLeft,
          centerRight: centerRight,
          halfLineWidth: halfLineWidth,
        ),
      ),
      edges,
    );

    paintIcons(canvas, centerLeft: centerLeft, centerRight: centerRight);

    paintIndicator(canvas, size);
  }

  Path getEdgesBarPath(
    Size size, {
    required Offset centerLeft,
    required Offset centerRight,
    required double halfLineWidth,
  }) {
    if (style.borderRadius == 0) {
      return Path()
        // LEFT EDGE
        ..addRect(
          Rect.fromCenter(
            center: centerLeft,
            width: style.edgesSize,
            height: size.height + style.lineWidth * 2,
          ),
        )
        // RIGTH EDGE
        ..addRect(
          Rect.fromCenter(
            center: centerRight,
            width: style.edgesSize,
            height: size.height + style.lineWidth * 2,
          ),
        );
    }

    final borderRadius = Radius.circular(style.borderRadius);

    /// Return left and right edges, with a reversed border radius on the inside of the rect
    return Path()
      // LEFT EDGE
      ..addPath(
        Path.combine(
          PathOperation.difference,
          Path()
            ..addRRect(
              RRect.fromRectAndCorners(
                Rect.fromLTWH(
                  centerLeft.dx - halfLineWidth,
                  -style.lineWidth,
                  style.edgeWidth + style.borderRadius,
                  size.height + style.lineWidth * 2,
                ),
                topLeft: borderRadius,
                bottomLeft: borderRadius,
              ),
            ),
          Path()
            ..addRRect(
              RRect.fromRectAndCorners(
                Rect.fromLTWH(
                  centerLeft.dx + halfLineWidth,
                  0.0,
                  style.borderRadius,
                  size.height,
                ),
                topLeft: borderRadius,
                bottomLeft: borderRadius,
              ),
            ),
        ),
        Offset.zero,
      )
      // RIGHT EDGE
      ..addPath(
        Path.combine(
          PathOperation.difference,
          Path()
            ..addRRect(
              RRect.fromRectAndCorners(
                Rect.fromLTWH(
                  centerRight.dx - halfLineWidth - style.borderRadius,
                  -style.lineWidth,
                  style.edgeWidth + style.borderRadius,
                  size.height + style.lineWidth * 2,
                ),
                topRight: borderRadius,
                bottomRight: borderRadius,
              ),
            ),
          Path()
            ..addRRect(
              RRect.fromRectAndCorners(
                Rect.fromLTWH(
                  centerRight.dx - halfLineWidth - style.borderRadius,
                  0.0,
                  style.borderRadius,
                  size.height,
                ),
                topRight: borderRadius,
                bottomRight: borderRadius,
              ),
            ),
        ),
        Offset.zero,
      );
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
    canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: rect.center,
            width: rect.width + style.edgeWidth,
            height: rect.height + style.edgeWidth,
          ),
          Radius.circular(style.borderRadius),
        ),
        line);

    paintIndicator(canvas, size);

    // LEFT CIRCLE
    canvas.drawCircle(centerLeft, style.edgesSize, edges);
    // RIGHT CIRCLE
    canvas.drawCircle(centerRight, style.edgesSize, edges);

    paintIcons(canvas, centerLeft: centerLeft, centerRight: centerRight);
  }

  void paintIndicator(Canvas canvas, Size size) {
    final progress = Paint()
      ..color = style.positionLineColor
      ..strokeWidth = style.positionLineWidth;

    // DRAW VIDEO INDICATOR
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(position - style.positionLineWidth / 2, -style.lineWidth * 2),
          Offset(
            position + style.positionLineWidth / 2,
            size.height + style.lineWidth * 2,
          ),
        ),
        Radius.circular(style.positionLineWidth),
      ),
      progress,
    );
  }

  void paintIcons(
    Canvas canvas, {
    required Offset centerLeft,
    required Offset centerRight,
  }) {
    final halfIconSize = Offset(style.iconSize / 2, style.iconSize / 2);

    // LEFT ICON
    if (style.leftIcon != null) {
      TextPainter leftArrow = TextPainter(textDirection: TextDirection.rtl);
      leftArrow.text = TextSpan(
        text: String.fromCharCode(style.leftIcon!.codePoint),
        style: TextStyle(
          fontSize: style.iconSize,
          fontFamily: style.leftIcon!.fontFamily,
          color: style.iconColor,
        ),
      );
      leftArrow.layout();
      leftArrow.paint(canvas, centerLeft - halfIconSize);
    }

    // RIGHT ICON
    if (style.rightIcon != null) {
      TextPainter rightArrow = TextPainter(textDirection: TextDirection.rtl);
      rightArrow.text = TextSpan(
        text: String.fromCharCode(style.rightIcon!.codePoint),
        style: TextStyle(
          fontSize: style.iconSize,
          fontFamily: style.rightIcon!.fontFamily,
          color: style.iconColor,
        ),
      );
      rightArrow.layout();
      rightArrow.paint(canvas, centerRight - halfIconSize);
    }
  }

  @override
  bool shouldRepaint(TrimSliderPainter oldDelegate) =>
      oldDelegate.rect != rect ||
      oldDelegate.position != position ||
      oldDelegate.style != style ||
      oldDelegate.isTrimming != isTrimming ||
      oldDelegate.isTrimmed != isTrimmed;

  @override
  bool shouldRebuildSemantics(TrimSliderPainter oldDelegate) => false;
}
