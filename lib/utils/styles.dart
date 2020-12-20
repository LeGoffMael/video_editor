import 'package:flutter/material.dart';

class CropGridStyle {
  CropGridStyle({
    Color croppingBackground,
    this.background = Colors.black,
    this.gridColor = Colors.white,
    this.gridLineWidth = 1,
    this.gridSize = 3,
    this.boundariesColor = Colors.white,
    this.boundariesLenght = 20,
    this.boundariesWidth = 5,
  }) : this.croppingBackground =
            croppingBackground ?? Colors.black.withOpacity(0.48);

  final Color croppingBackground;
  final Color background;

  final Color gridColor;
  final double gridLineWidth;
  final int gridSize;

  final Color boundariesColor;
  final double boundariesLenght;
  final double boundariesWidth;
}

class TrimSliderStyle {
  TrimSliderStyle({
    Color background,
    this.dotRadius = 5,
    this.lineWidth = 2,
    this.dotColor = Colors.white,
    this.lineColor = Colors.white,
    this.progressLineColor = Colors.red,
  }) : this.background = background ?? Colors.black.withOpacity(0.6);

  final Color dotColor;
  final Color lineColor;
  final Color background;
  final double dotRadius;
  final double lineWidth;
  final Color progressLineColor;
}
