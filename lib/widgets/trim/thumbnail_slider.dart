import 'dart:typed_data';
import 'package:helpers/helpers.dart';
import 'package:flutter/material.dart';
import 'package:video_editor/utils/controller.dart';
import 'package:video_editor/widgets/crop/crop_grid_painter.dart';
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
  Offset _translate = Offset.zero;
  int _thumbnails = 8;
  Size _layout = Size.zero;
  double _aspect = 1.0;
  double _scale = 1.0;
  double _width = 1;
  Rect _rect;

  @override
  void initState() {
    super.initState();
    generateThumbnail();
    Misc.onLayoutRendered(() {
      setState(() {
        _thumbnails = (_width ~/ widget.height) + 1;
        _aspect = widget.controller.videoController.value.aspectRatio;
      });
    });
  }

  @override
  void didUpdateWidget(ThumbnailSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.controller.isPlaying)
      setState(() {
        _rect = _calculateCropRect();
        final double _scaleX = _layout.width / _rect.width;
        final double _scaleY = _layout.height / _rect.height;

        if (_aspect < 1.0) {
          _scale = _scaleX > _scaleY ? _scaleY : _scaleX;
          _translate = Offset(
                (_layout.width - _rect.width) / 2,
                (_layout.height - _rect.height) / 2,
              ) -
              _rect.topLeft;
        } else {
          _translate = Offset(0.0, (_layout.height - _rect.height) / 2);
        }
      });
  }

  void generateThumbnail() async {
    final String videoPath = widget.controller.file.path;
    final int eachPart =
        widget.controller.videoDuration.inMilliseconds ~/ _thumbnails;

    for (int i = 1; i <= _thumbnails; i++) {
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

  Rect _calculateCropRect() {
    final Offset min = widget.controller.minCrop;
    final Offset max = widget.controller.maxCrop;
    return Rect.fromPoints(
      Offset(
        min.dx * _layout.width * (_aspect < 1.0 ? _aspect : 1.0),
        min.dy * _layout.height,
      ),
      Offset(
        max.dx * _layout.width * (_aspect < 1.0 ? _aspect : 1.0),
        max.dy * _layout.height,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, box) {
      _width = box.maxWidth;
      _layout = Size(widget.height, widget.height);
      if (_rect == null) _rect = _calculateCropRect();
      return ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: NeverScrollableScrollPhysics(),
        itemCount: _imageBytes.length,
        itemBuilder: (_, int index) {
          return ClipRRect(
            child: Transform.scale(
              scale: _scale,
              child: Transform.translate(
                offset: _translate,
                child: Container(
                  height: widget.height,
                  width: widget.height,
                  child: Stack(children: [
                    Image(
                      height: widget.height,
                      width: widget.height,
                      image: MemoryImage(_imageBytes[index]),
                      alignment: Alignment.topLeft,
                    ),
                    CustomPaint(
                      size: Size.infinite,
                      painter: CropGridPainter(
                        _rect,
                        showGrid: false,
                        style: widget.controller.cropStyle,
                      ),
                    )
                  ]),
                ),
              ),
            ),
          );
        },
      );
    });
  }
}
