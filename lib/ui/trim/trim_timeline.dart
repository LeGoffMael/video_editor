import 'package:flutter/material.dart';
import 'package:video_editor/domain/bloc/controller.dart';

class TrimTimeline extends StatelessWidget {
  /// Show the timeline corresponding to the [TrimSlider]
  const TrimTimeline({
    Key? key,
    required this.controller,
    this.secondGap = 5,
    this.margin = EdgeInsets.zero,
  }) : super(key: key);

  /// The [controller] param is mandatory so depending on the [controller.maxDuration], the generated timeline will be different
  final VideoEditorController controller;

  /// The [secondGap] param specifies time gap in second between every points of the timeline
  /// The default value of this property is 5 seconds
  final double secondGap;

  /// The [margin] param specifies the space surrounding the timeline
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    final Duration duration = controller.maxDuration < controller.videoDuration
        ? controller.maxDuration
        : controller.videoDuration;
    final timeGap = (duration.inSeconds / (secondGap + 1)).ceil();

    return Padding(
      padding: margin,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (int i = 0;
              i <= (controller.videoDuration.inSeconds / timeGap).ceil();
              i++)
            Text(
              (i * timeGap <= controller.videoDuration.inSeconds
                      ? i * timeGap
                      : '')
                  .toString(),
            ),
        ],
      ),
    );
  }
}
