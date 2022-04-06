import 'package:flutter/material.dart';

class TrimSliderStyle {
  ///Style for [TrimSlider]. It's use on VideoEditorController
  TrimSliderStyle({
    Color? background,
    this.positionLineColor = Colors.red,
    this.positionLineWidth = 2,
    this.lineColor = Colors.white,
    this.lineWidth = 2,
    this.iconColor = Colors.black,
    this.circleSize = 8,
    this.iconSize = 25,
    this.leftIcon = Icons.arrow_left,
    this.rightIcon = Icons.arrow_right,
  }) : background = background ?? Colors.black.withOpacity(0.6);

  /// The [background] param specifies the color of the paint area outside the trimmed area
  /// The default value of this property `Colors.black.withOpacity(0.6)
  final Color background;

  /// The [positionLineColor] param specifies the color of the line showing the video position
  final Color positionLineColor;

  /// The [positionLineWidth] param specifies the width  of the line showing the video position
  final double positionLineWidth;

  /// The [lineColor] param specifies the color of the borders around the trimmed area
  final Color lineColor;

  /// The [lineWidth] param specifies the width of the borders around the trimmed area
  final double lineWidth;

  /// The [iconColor] param specifies the color of the icons on the trimmed area's edges
  final Color iconColor;

  /// The [circleSize] param specifies the size of the circle behind the icons on the trimmed area's edges
  final double circleSize;

  /// The [iconSize] param specifies the size of the icon on the trimmed area's edges
  final double iconSize;

  /// The [leftIcon] param specifies the icon to show on the left edge of the trimmed area
  final IconData? leftIcon;

  /// The [rightIcon] param specifies the icon to show on the right edge of the trimmed area
  final IconData? rightIcon;
}
