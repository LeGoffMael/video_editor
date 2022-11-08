import 'package:flutter/material.dart';
import 'package:video_editor/domain/bloc/controller.dart';
import 'package:video_player/video_player.dart';

class VideoViewer extends StatelessWidget {
  const VideoViewer({
    Key? key,
    required this.controller,
    this.child,
  }) : super(key: key);

  final VideoEditorController controller;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (controller.video.value.isPlaying) {
          controller.video.pause();
        } else {
          controller.video.play();
        }
      },
      child: Center(
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: controller.video.value.aspectRatio,
              child: VideoPlayer(controller.video),
            ),
            if (child != null)
              AspectRatio(
                aspectRatio: controller.video.value.aspectRatio,
                child: child,
              ),
          ],
        ),
      ),
    );
  }
}
