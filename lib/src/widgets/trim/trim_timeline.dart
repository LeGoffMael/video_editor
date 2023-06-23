import 'dart:math';

import 'package:flutter/material.dart';
import 'package:video_editor/src/controller.dart';

class TrimTimeline extends StatelessWidget {
  /// Show the timeline corresponding to the [TrimSlider]
  const TrimTimeline({
    super.key,
    required this.controller,
    this.quantity = 8,
    this.padding = EdgeInsets.zero,
    this.localSeconds = 's',
    this.textStyle,
  });

  /// The [controller] param is mandatory so depending on the video's duration,
  /// the size of the generated timeline will be different
  final VideoEditorController controller;

  /// Expected [quantity] of elements shown in the timeline, is not fixed,
  /// will be determine by the max width available and the video duration
  ///
  /// Defaults to `8`
  final int quantity;

  /// The [padding] param specifies the space surrounding the timeline
  ///
  /// Defaults to `EdgeInsets.zero`
  final EdgeInsets padding;

  /// The [String] to represents the seconds to show next to each timeline element
  ///
  /// Defaults to `s`
  final String localSeconds;

  /// The [TextStyle] to use to style the timeline text
  ///
  /// Defaults to `textTheme.bodySmall`
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, contrainst) {
      final int count =
          (max(1, (contrainst.maxWidth / MediaQuery.of(context).size.width)) *
                  min(quantity, controller.videoDuration.inMilliseconds ~/ 100))
              .toInt();
      final gap = controller.videoDuration.inMilliseconds ~/ (count - 1);

      return Padding(
        padding: padding,
        child: IntrinsicWidth(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(count, (i) {
              final t = Duration(milliseconds: i * gap);
              final text =
                  (t.inMilliseconds / 1000).toStringAsFixed(1).padLeft(2, '0');

              return Text(
                '$text$localSeconds',
                style: textStyle ?? Theme.of(context).textTheme.bodySmall,
              );
            }),
          ),
        ),
      );
    });
  }
}
