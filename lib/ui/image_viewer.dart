import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:video_editor/domain/bloc/controller.dart';

class ImageViewer extends StatelessWidget {
  const ImageViewer({
    Key? key,
    required this.controller,
    required this.bytes,
    this.child,
  }) : super(key: key);

  final VideoEditorController controller;
  final Uint8List bytes;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: controller.video.value.aspectRatio,
            child: Image(image: MemoryImage(bytes)),
          ),
          if (child != null)
            AspectRatio(
              aspectRatio: controller.video.value.aspectRatio,
              child: child,
            ),
        ],
      ),
    );
  }
}
