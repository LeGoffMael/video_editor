import 'package:flutter/material.dart';

class CoverSelectionStyle {
  ///Style for [CoverSelection]. It's use on VideoEditorController
  CoverSelectionStyle({
    Color? selectedBorderColor,
    this.selectedBorderWidth = 2,
  }) : this.selectedBorderColor = selectedBorderColor ?? Colors.white;

  ///The border color displayed around the selected frame. Default `Colors.white`
  final Color selectedBorderColor;

  final double selectedBorderWidth;
}
