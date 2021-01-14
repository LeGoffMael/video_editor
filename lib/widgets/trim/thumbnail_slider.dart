import 'dart:typed_data';
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

  ///MAX QUALITY IS 100 - MIN QUALITY IS 0
  final int quality;

  ///THUMBNAIL HEIGHT
  final double height;

  final VideoEditorController controller;

  @override
  _ThumbnailSliderState createState() => _ThumbnailSliderState();
}

class _ThumbnailSliderState extends State<ThumbnailSlider> {
  double _aspect = 1.0, _scale = 1.0, _width = 1.0;
  int _thumbnails = 8;

  Rect _rect;
  Size _thumbnailSize = Size.zero;
  Offset _translate = Offset.zero;
  Stream<List<Uint8List>> _stream;

  @override
  void initState() {
    super.initState();
    _aspect = widget.controller.videoController.value.aspectRatio;
    _thumbnailSize = Size(widget.height, widget.height);
  }

  @override
  void didUpdateWidget(ThumbnailSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.controller.isPlaying && _aspect <= 1.0)
      setState(() {
        _rect = _calculateTrimRect();
        final double _scaleX = _thumbnailSize.width / _rect.width;
        final double _scaleY = _thumbnailSize.height / _rect.height;

        _scale = _scaleX > _scaleY ? _scaleY : _scaleX;
        _translate = Offset(
              (_thumbnailSize.width - _rect.width) / 2,
              (_thumbnailSize.height - _rect.height) / 2,
            ) -
            _rect.topLeft;
      });
  }

  Stream<List<Uint8List>> _generateThumbnails() async* {
    final String path = widget.controller.file.path;
    final int duration = widget.controller.videoDuration.inMilliseconds;
    final double eachPart = duration / _thumbnails;

    List<Uint8List> _byteList = [];

    for (int i = 1; i <= _thumbnails; i++) {
      Uint8List _bytes = await VideoThumbnail.thumbnailData(
        imageFormat: ImageFormat.JPEG,
        video: path,
        timeMs: (eachPart * i).toInt(),
        quality: widget.quality,
      );
      _byteList.add(_bytes);

      yield _byteList;
    }
  }

  Rect _calculateTrimRect() {
    final Offset min = widget.controller.minCrop;
    final Offset max = widget.controller.maxCrop;
    return Rect.fromPoints(
      Offset(
        min.dx * _thumbnailSize.width * (_aspect <= 1.0 ? _aspect : 1.0),
        min.dy * _thumbnailSize.height,
      ),
      Offset(
        max.dx * _thumbnailSize.width * (_aspect <= 1.0 ? _aspect : 1.0),
        max.dy * _thumbnailSize.height,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, box) {
      final double width = box.maxWidth;
      if (_width != width) {
        _width = width;
        _rect = _calculateTrimRect();
        _thumbnails = (_width ~/ _thumbnailSize.width) + 1;
        _stream = _generateThumbnails();
      }

      return StreamBuilder(
        stream: _stream,
        builder: (_, AsyncSnapshot<List<Uint8List>> snapshot) {
          final data = snapshot.data;
          return snapshot.hasData
              ? ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: data.length,
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
                                image: MemoryImage(data[index]),
                                alignment: _aspect <= 1.0
                                    ? Alignment.topLeft
                                    : Alignment.center,
                                fit: _aspect <= 1.0 ? null : BoxFit.fitWidth,
                              ),
                              if (_aspect <= 1.0)
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
                )
              : SizedBox();
        },
      );
    });
  }
}
