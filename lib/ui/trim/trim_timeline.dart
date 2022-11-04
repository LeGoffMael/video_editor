import 'package:flutter/material.dart';
import 'package:video_editor/domain/bloc/controller.dart';

class TrimTimeline extends StatefulWidget {
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
  State<TrimTimeline> createState() => _TrimTimelineState();
}

class _TrimTimelineState extends State<TrimTimeline> {
  int _timeGap = 0;

  @override
  void initState() {
    final Duration duration =
        widget.controller.maxDuration < widget.controller.videoDuration
            ? widget.controller.maxDuration
            : widget.controller.videoDuration;
    _timeGap = (duration.inSeconds / (widget.secondGap + 1)).ceil();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: widget.margin,
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (int i = 0;
                  i <=
                      (widget.controller.videoDuration.inSeconds / _timeGap)
                          .ceil();
                  i++)
                Text(
                  (i * _timeGap <= widget.controller.videoDuration.inSeconds
                          ? i * _timeGap
                          : '')
                      .toString(),
                ),
            ]));
  }
}
