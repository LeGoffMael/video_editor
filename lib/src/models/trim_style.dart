import 'package:flutter/material.dart';
import 'package:video_editor/src/utils/helpers.dart';

enum TrimSliderEdgesType { bar, circle }

class TrimSliderStyle {
  ///Style for [TrimSlider]. It's use on VideoEditorController
  const TrimSliderStyle({
    this.background = Colors.black54,
    this.positionLineColor = Colors.white,
    this.positionLineWidth = 4,
    this.lineColor = Colors.white60,
    this.onTrimmingColor = kDefaultSelectedColor,
    this.onTrimmedColor = kDefaultSelectedColor,
    this.lineWidth = 2,
    this.borderRadius = 5.0,
    // edges
    this.edgesType = TrimSliderEdgesType.bar,
    double? edgesSize,
    // icons
    this.iconColor = Colors.black,
    this.iconSize = 16,
    this.leftIcon = Icons.arrow_back_ios_rounded,
    this.rightIcon = Icons.arrow_forward_ios_rounded,
  }) : edgesSize = edgesSize ?? (edgesType == TrimSliderEdgesType.bar ? 10 : 8);

  /// The [background] param specifies the color of the paint area outside the trimmed area
  ///
  /// Defaults to [Colors.black54]
  final Color background;

  /// The [positionLineColor] param specifies the color of the line showing the video position
  ///
  /// Defaults to [Colors.white]
  final Color positionLineColor;

  /// The [positionLineWidth] param specifies the width  of the line showing the video position
  ///
  /// Defaults to `4`
  final double positionLineWidth;

  /// The [lineColor] param specifies the color of the borders around the trimmed area
  ///
  /// Defaults to [Colors.white70]
  final Color lineColor;

  /// The [onTrimmingColor] param specifies the color of the borders around the trimmed area while it is getting trimmed
  ///
  /// Defaults to [kDefaultSelectedColor]
  final Color onTrimmingColor;

  /// The [onTrimmedColor] param specifies the color of the borders around the trimmed area when the trimmed parameters are not default values
  ///
  /// Defaults to [kDefaultSelectedColor]
  final Color onTrimmedColor;

  /// The [lineWidth] param specifies the width of the borders around the trimmed area
  ///
  /// Defaults to `2`
  final double lineWidth;

  /// The [borderRadius] param specifies the border radius around the trimmer
  ///
  /// Defaults to `5`
  final double borderRadius;

  /// The [edgesType] param specifies the style to apply to the edges (left & right) of the trimmer
  ///
  /// Defaults to [TrimSliderEdgesType.bar]
  final TrimSliderEdgesType edgesType;

  /// The [edgesSize] param specifies the size of the edges behind the icons
  ///
  /// If [edgesType] equals [TrimSliderEdgesType.bar] defaults to `10`
  /// If [edgesType] equals [TrimSliderEdgesType.circle] defaults to `8`
  final double edgesSize;

  /// The [iconColor] param specifies the color of the icons on the trimmed area's edges
  ///
  /// Defaults to [Colors.black]
  final Color iconColor;

  /// The [iconSize] param specifies the size of the icon on the trimmed area's edges
  ///
  /// Defaults to `16`
  final double iconSize;

  /// The [leftIcon] param specifies the icon to show on the left edge of the trimmed area
  ///
  /// Defaults to [Icons.arrow_back_ios_rounded]
  final IconData? leftIcon;

  /// The [rightIcon] param specifies the icon to show on the right edge of the trimmed area
  ///
  /// Defaults to [Icons.arrow_forward_ios_rounded]
  final IconData? rightIcon;

  /// Returns left and right line width depending on [edgesType]
  double get edgeWidth =>
      edgesType == TrimSliderEdgesType.bar ? edgesSize : lineWidth;
}
