import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:video_editor/domain/bloc/controller.dart';
import 'package:video_editor/domain/entities/transform_data.dart';
import 'package:video_editor/ui/crop/crop_grid_painter.dart';
import 'package:video_editor/ui/transform.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class ThumbnailSlider extends StatefulWidget {
  ThumbnailSlider({
    required this.controller,
    this.height = 60,
    this.quality = 10,
  });

  ///MAX QUALITY IS 100 - MIN QUALITY IS 0
  final int quality;

  ///THUMBNAIL HEIGHT
  final double height;

  final VideoEditorController controller;

  @override
  _ThumbnailSliderState createState() => _ThumbnailSliderState();
}

class _ThumbnailSliderState extends State<ThumbnailSlider> {
  ValueNotifier<Rect> _rect = ValueNotifier<Rect>(Rect.zero);
  ValueNotifier<TransformData> _transform = ValueNotifier<TransformData>(
    TransformData(rotation: 0.0, scale: 1.0, translate: Offset.zero),
  );

  double _aspect = 1.0, _width = 1.0;
  int _thumbnails = 8;

  Size _layout = Size.zero;
  Stream<List<Uint8List>>? _stream;

  @override
  void initState() {
    super.initState();
    _aspect = widget.controller.video.value.aspectRatio;
    widget.controller.addListener(_scaleRect);

    // init the widget with controller values
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scaleRect();
    });

    super.initState();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_scaleRect);
    _transform.dispose();
    _rect.dispose();
    super.dispose();
  }

  void _scaleRect() {
    _rect.value = _calculateTrimRect();
    _transform.value = TransformData.fromRect(
      _rect.value,
      _layout,
      widget.controller,
    );
  }

  Stream<List<Uint8List>> _generateThumbnails() async* {
    final String path = widget.controller.file.path;
    final int duration = widget.controller.video.value.duration.inMilliseconds;
    final double eachPart = duration / _thumbnails;
    List<Uint8List> _byteList = [];
    for (int i = 1; i <= _thumbnails; i++) {
      Uint8List? _bytes = await VideoThumbnail.thumbnailData(
        imageFormat: ImageFormat.JPEG,
        video: path,
        timeMs: (eachPart * i).toInt(),
        quality: widget.quality,
      );
      if (_bytes != null) {
        _byteList.add(_bytes);
      }

      yield _byteList;
    }
  }

  Rect _calculateTrimRect() {
    final Offset min = widget.controller.minCrop;
    final Offset max = widget.controller.maxCrop;
    return Rect.fromPoints(
      Offset(
        min.dx * _layout.width,
        min.dy * _layout.height,
      ),
      Offset(
        max.dx * _layout.width,
        max.dy * _layout.height,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, box) {
      final double width = box.maxWidth;
      if (_width != width) {
        _width = width;
        _layout = _aspect <= 1.0
            ? Size(widget.height * _aspect, widget.height)
            : Size(widget.height, widget.height / _aspect);
        _thumbnails = (_width ~/ _layout.width) + 1;
        _stream = _generateThumbnails();
        _rect.value = _calculateTrimRect();
      }

      return StreamBuilder(
        stream: _stream,
        builder: (_, AsyncSnapshot<List<Uint8List>> snapshot) {
          final data = snapshot.data;
          return snapshot.hasData
              ? ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: data!.length,
                  itemBuilder: (_, int index) {
                    return ValueListenableBuilder(
                      valueListenable: _transform,
                      builder: (_, TransformData transform, __) {
                        return CropTransform(
                          transform: transform,
                          child: Container(
                            alignment: Alignment.center,
                            height: _layout.height,
                            width: _layout.width,
                            child: Stack(children: [
                              Image(
                                image: MemoryImage(data[index]),
                                width: _layout.width,
                                height: _layout.height,
                                alignment: Alignment.topLeft,
                              ),
                              CustomPaint(
                                size: _layout,
                                painter: CropGridPainter(
                                  _rect.value,
                                  showGrid: false,
                                  style: widget.controller.cropStyle,
                                ),
                              ),
                            ]),
                          ),
                        );
                      },
                    );
                  },
                )
              : SizedBox();
        },
      );
    });
  }
}
