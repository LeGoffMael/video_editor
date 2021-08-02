import 'package:flutter/material.dart';
import 'package:video_editor/domain/bloc/controller.dart';

class TrimTimeline extends StatefulWidget {
  ///Slider that trim video length.
  TrimTimeline({
    Key? key,
    required this.controller,
    required this.width,
    this.secondGap = 5,
  }) : super(key: key);

  ///Essential argument for the functioning of the Widget
  final VideoEditorController controller;

  ///The time in seconds between every point of the timeline
  final double secondGap;
  final double width;

  @override
  _TrimTimelineState createState() => _TrimTimelineState();
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
        margin: EdgeInsets.only(top: 5),
        width: widget.width,
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
