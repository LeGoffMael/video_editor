import 'package:flutter/material.dart';
import 'package:video_editor/src/utils/helpers.dart';

class CropGridStyle {
  ///Style for [CropGridViewer]. It's use on VideoEditorController
  const CropGridStyle({
    this.croppingBackground = Colors.black45,
    this.background = Colors.black,
    this.gridLineColor = Colors.white,
    this.gridLineWidth = 1,
    this.gridSize = 3,
    this.boundariesColor = Colors.white,
    this.selectedBoundariesColor = kDefaultSelectedColor,
    this.boundariesLength = 20,
    this.boundariesWidth = 5,
  });

  /// The [croppingBackground] param specifies the color of the paint area outside the crop area when copping
  ///
  /// Defaults to [Colors.black45]
  final Color croppingBackground;

  /// The [background] param specifies the color of the paint area outside the crop area when not copping
  ///
  /// Defaults to [Colors.black]
  final Color background;

  /// The [gridLineWidth] param specifies the width of the crop lines
  ///
  /// Defaults to `1`
  final double gridLineWidth;

  /// The [gridLineColor] param specifies the color of the crop lines
  ///
  /// Defaults to [Colors.white]
  final Color gridLineColor;

  /// The [gridSize] param specifies the quantity of columns and rows in the crop view
  ///
  /// Defaults to `3`
  final int gridSize;

  /// The [boundariesColor] param specifies the color of the crop area's corner
  ///
  /// Defaults to [Colors.white]
  final Color boundariesColor;

  /// The [boundariesColor] param specifies the color of the crop area's corner
  /// when is it selected
  ///
  /// Defaults to [kDefaultSelectedColor]
  final Color selectedBoundariesColor;

  /// The [boundariesLength] param specifies the length of the crop area's corner
  ///
  /// Defaults to `20`
  final double boundariesLength;

  /// The [boundariesWidth] param specifies the width of the crop area's corner
  ///
  /// Defaults to `5`
  final double boundariesWidth;
}
