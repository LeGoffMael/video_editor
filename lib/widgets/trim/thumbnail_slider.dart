import 'dart:typed_data';
import 'package:helpers/helpers.dart';
import 'package:flutter/material.dart';
import 'package:video_editor/utils/controller.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class ThumbnailSlider extends StatefulWidget {
  ThumbnailSlider({
    @required this.controller,
    this.height = 60,
    this.quality = 25,
  }) : assert(controller != null);

  final int quality;
  final double height;
  final VideoEditorController controller;

  @override
  _ThumbnailSliderState createState() => _ThumbnailSliderState();
}

class _ThumbnailSliderState extends State<ThumbnailSlider> {
  final List<Uint8List> _imageBytes = [];
  int thumbnails = 8;
  double width = 1;

  @override
  void initState() {
    super.initState();
    generateThumbnail();
    Misc.onLayoutRendered(() {
      setState(() => thumbnails = (width ~/ widget.height) + 1);
    });
  }

  void generateThumbnail() async {
    final String videoPath = widget.controller.file.path;
    final int eachPart =
        widget.controller.videoDuration.inMilliseconds ~/ thumbnails;

    for (int i = 1; i <= thumbnails; i++) {
      final Uint8List _bytes = await VideoThumbnail.thumbnailData(
        imageFormat: ImageFormat.WEBP,
        timeMs: eachPart * i,
        video: videoPath,
        quality: widget.quality,
      );
      _imageBytes.add(_bytes);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, box) {
      width = box.maxWidth;
      return ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: NeverScrollableScrollPhysics(),
        itemCount: _imageBytes.length,
        itemBuilder: (_, int index) {
          return Container(
            height: widget.height,
            width: widget.height,
            child: Image(
              image: MemoryImage(_imageBytes[index]),
              fit: BoxFit.cover,
            ),
          );
        },
      );
    });
  }
}
