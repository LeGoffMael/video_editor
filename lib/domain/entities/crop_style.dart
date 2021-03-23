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
  }) : this.croppingBackground =
            croppingBackground ?? Colors.black.withOpacity(0.48);

  ///It is the deactive color background when is cropping. Default `Colors.black.withOpacity(0.48)`
  final Color croppingBackground;

  ///It is the background color when is not cropping.
  final Color background;

  final double gridLineWidth;

  final Color gridLineColor;

  ///The amount columns and rows
  final int gridSize;

  final Color boundariesColor;
  final double boundariesLength;
  final double boundariesWidth;
}
