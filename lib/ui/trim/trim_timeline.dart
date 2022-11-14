import 'dart:math';

import 'package:flutter/material.dart';
import 'package:video_editor/domain/bloc/controller.dart';

class TrimTimeline extends StatelessWidget {
  /// Show the timeline corresponding to the [TrimSlider]
  const TrimTimeline({
    Key? key,
    required this.controller,
    this.quantity = 8,
    this.padding = EdgeInsets.zero,
  }) : super(key: key);

  /// The [controller] param is mandatory so depending on the video's duration,
  /// the size of the generated timeline will be different
  final VideoEditorController controller;

  /// Expected [quantity] of elements shown in the timeline, is not fixed,
  /// will be determine by the max width available and the video duration
  final int quantity;

  /// The [padding] param specifies the space surrounding the timeline
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, contrainst) {
      int count =
          max(1, (contrainst.maxWidth ~/ MediaQuery.of(context).size.width)) *
              min(quantity, controller.videoDuration.inMilliseconds ~/ 100);
      final gap = controller.videoDuration.inMilliseconds ~/ (count - 1);

      return Padding(
        padding: padding,
        child: IntrinsicWidth(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(count, (i) {
              final t = Duration(milliseconds: i * gap);
              final String text;

              if (gap < 1000) {
                text =
                    '${(t.inMilliseconds / 1000).toStringAsFixed(1).padLeft(2, '0')}s';
              } else {
                text = '${t.inSeconds}s';
              }

              return Text(text, style: Theme.of(context).textTheme.bodySmall);
            }),
          ),
        ),
      );
    });
  }
}
