import 'package:flutter/material.dart';

class TrimSliderStyle {
  ///Style for [TrimSlider]. It's use on VideoEditorController
  TrimSliderStyle(
      {Color? background,
      this.positionLineColor = Colors.red,
      this.positionlineWidth = 2,
      this.sideTrimmerColor = Colors.white,
      this.sideTrimmerWidth = 10,
      this.innerSideTrimmerColor = Colors.black,
      this.innerSideTrimmerWidth = 5,
      this.outsideLines = true})
      : this.background = background ?? Colors.black.withOpacity(0.6);

  ///It is the color line that indicate the video position
  final Color positionLineColor;
  final double positionlineWidth;

  ///It is the deactive color. Default `Colors.black.withOpacity(0.6)
  final Color background;

  final Color sideTrimmerColor;
  final double sideTrimmerWidth;

  final Color innerSideTrimmerColor;
  final double innerSideTrimmerWidth;

  final bool outsideLines;
}
