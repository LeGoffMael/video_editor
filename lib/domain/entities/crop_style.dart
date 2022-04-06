import 'package:flutter/material.dart';

class CropGridStyle {
  ///Style for [CropGridViewer]. It's use on VideoEditorController
  CropGridStyle({
    Color? croppingBackground,
    this.background = Colors.black,
    this.gridLineColor = Colors.white,
    this.gridLineWidth = 1,
    this.gridSize = 3,
    this.boundariesColor = Colors.white,
    this.boundariesLength = 20,
    this.boundariesWidth = 5,
  }) : croppingBackground =
            croppingBackground ?? Colors.black.withOpacity(0.48);

  /// The [croppingBackground] param specifies the color of the paint area outside the crop area when copping
  /// The default value of this property is `Colors.black.withOpacity(0.48)`
  final Color croppingBackground;

  /// The [background] param specifies the color of the paint area outside the crop area when not copping
  final Color background;

  /// The [gridLineWidth] param specifies the width of the crop lines
  final double gridLineWidth;

  /// The [gridLineColor] param specifies the color of the crop lines
  final Color gridLineColor;

  /// The [gridSize] param specifies the quantity of columns and rows in the crop view
  final int gridSize;

  /// The [boundariesColor] param specifies the color of the crop area's corner
  final Color boundariesColor;

  /// The [boundariesLength] param specifies the length of the crop area's corner
  final double boundariesLength;

  /// The [boundariesWidth] param specifies the width of the crop area's corner
  final double boundariesWidth;
}
