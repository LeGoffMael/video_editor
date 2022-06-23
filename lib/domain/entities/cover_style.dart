import 'package:flutter/material.dart';

class CoverSelectionStyle {
  ///Style for [CoverSelection]. It's use on VideoEditorController
  CoverSelectionStyle({
    Color? selectedBorderColor,
    this.selectedBorderWidth = 2,
    this.selectedIndicator,
    this.selectedIndicatorAlign = Alignment.bottomRight,
  }) : selectedBorderColor = selectedBorderColor ?? Colors.white;

  /// The [selectedBorderColor] param specifies the color of the border around the selected cover thumbnail
  /// The default value of this property is `Colors.white`
  final Color selectedBorderColor;

  /// The [selectedBorderWidth] param specifies the width of the border around the selected cover thumbnail
  final double selectedBorderWidth;

  /// The [selectedIndicator] param specifies the [Widget] to show on top of the selected cover
  final Widget? selectedIndicator;

  /// The [selectedIndicatorAlign] param specifies where [selectedIndicator] should be shown in the [Stack]
  final AlignmentGeometry selectedIndicatorAlign;
}
