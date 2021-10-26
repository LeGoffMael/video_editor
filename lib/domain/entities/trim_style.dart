import 'package:flutter/material.dart';

class TrimSliderStyle {
  ///Style for [TrimSlider]. It's use on VideoEditorController
  TrimSliderStyle(
      {Color? background,
      this.positionLineColor = Colors.red,
      this.positionlineWidth = 2,
      this.lineColor = Colors.white,
      this.lineWidth = 2,
      this.iconColor = Colors.black,
      this.circleSize = 8,
      this.iconSize = 25,
      this.leftIcon = Icons.arrow_left,
      this.rightIcon = Icons.arrow_right})
      : this.background = background ?? Colors.black.withOpacity(0.6);

  ///It is the color line that indicate the video position
  final Color positionLineColor;
  final double positionlineWidth;

  ///It is the deactive color. Default `Colors.black.withOpacity(0.6)
  final Color background;

  final Color lineColor;
  final double lineWidth;

  final Color iconColor;
  final double iconSize, circleSize;
  final IconData? leftIcon, rightIcon;
}
