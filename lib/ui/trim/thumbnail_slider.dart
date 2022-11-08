import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:video_editor/domain/bloc/controller.dart';
import 'package:video_editor/domain/entities/transform_data.dart';
import 'package:video_editor/domain/helpers.dart';
import 'package:video_editor/ui/crop/crop_grid_painter.dart';
import 'package:video_editor/ui/image_viewer.dart';
import 'package:video_editor/ui/transform.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class ThumbnailSlider extends StatefulWidget {
  const ThumbnailSlider({
    Key? key,
    required this.controller,
    this.height = 60,
    this.quality = 10,
  }) : super(key: key);

  /// The [quality] param specifies the quality of the generated thumbnails, from 0 to 100, (([more info](https://pub.dev/packages/video_thumbnail)))
  final int quality;

  /// The [height] param specifies the height of the generated thumbnails
  final double height;

  final VideoEditorController controller;

  @override
  State<ThumbnailSlider> createState() => _ThumbnailSliderState();
}

class _ThumbnailSliderState extends State<ThumbnailSlider> {
  final ValueNotifier<Rect> _rect = ValueNotifier<Rect>(Rect.zero);
  final ValueNotifier<TransformData> _transform =
      ValueNotifier<TransformData>(TransformData());

  /// The max width of [ThumbnailSlider]
  double _sliderWidth = 1.0;

  Size _layout = Size.zero;
  late Size _maxLayout =
      _calculateMaxLayout(widget.controller.video.value.aspectRatio);

  /// The quantity of thumbnails to generate
  final int _thumbnailsCount = 8;
  late final Stream<List<Uint8List>> _stream = (() => _generateThumbnails())();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_scaleRect);
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
    _rect.value = calculateCroppedRect(widget.controller, _layout);

    final ratio = _rect.value == Rect.zero
        ? widget.controller.video.value.aspectRatio
        : _rect.value.size.aspectRatio;
    _maxLayout = _calculateMaxLayout(ratio);

    _transform.value = TransformData.fromRect(
      _rect.value,
      _layout,
      _maxLayout, // the maximum size to show the thumb
      widget.controller,
    );
    // crop area ratio is < 1, increase scale to fit all `ThumbnailSlider` space
    if (ratio <= 1 || widget.controller.isRotated) {
      _transform.value = _transform.value
          .copyWith(scale: scaleToSizeMax(_maxLayout, _rect.value));
    }
  }

  Stream<List<Uint8List>> _generateThumbnails() async* {
    final String path = widget.controller.file.path;
    final int duration = widget.controller.video.value.duration.inMilliseconds;
    final double eachPart = duration / _thumbnailsCount;
    List<Uint8List> byteList = [];
    for (int i = 1; i <= _thumbnailsCount; i++) {
      try {
        final Uint8List? bytes = await VideoThumbnail.thumbnailData(
          imageFormat: ImageFormat.JPEG,
          video: path,
          timeMs: (eachPart * i).toInt(),
          quality: widget.quality,
        );
        if (bytes != null) {
          byteList.add(bytes);
        }
      } catch (e) {
        debugPrint(e.toString());
      }

      yield byteList;
    }
  }

  /// Returns the max size the layout should take with the rect value
  Size _calculateMaxLayout(double ratio) {
    // check if the ratio is almost 1
    if (isNumberAlmost(ratio, 1)) return Size.square(widget.height);

    final verticalLayout = Size(_sliderWidth / _thumbnailsCount, widget.height);

    if (ratio >= 1) {
      if (widget.controller.isRotated) {
        return verticalLayout;
      }
      // if crop is horizontal, fit with ratio, max height is [widget.height]
      return Size(widget.height * ratio, widget.height);
    } else if (widget.controller.isRotated) {
      return Size(widget.height, widget.height * ratio);
    }
    // otherwise max height is [widget.height], and max width is [ThumbnailSlider] / [_thumbnailsCount]
    return verticalLayout;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, box) {
      _sliderWidth = box.maxWidth;

      return StreamBuilder(
        stream: _stream,
        builder: (_, AsyncSnapshot<List<Uint8List>> snapshot) {
          final data = snapshot.data;
          return snapshot.hasData
              ? ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: data!.length,
                  itemBuilder: (_, index) =>
                      ValueListenableBuilder<TransformData>(
                    valueListenable: _transform,
                    builder: (_, transform, __) =>
                        _buildSingleThumbnail(data[index], transform),
                  ),
                )
              : const SizedBox();
        },
      );
    });
  }

  Widget _buildSingleThumbnail(Uint8List bytes, TransformData transform) {
    return Container(
      constraints: BoxConstraints.tight(_maxLayout),
      child: CropTransform(
        transform: transform,
        child: ImageViewer(
          controller: widget.controller,
          bytes: bytes,
          child: LayoutBuilder(builder: (_, constraints) {
            Size size = constraints.biggest;
            if (_layout != size) {
              _layout = size;
              // init the widget with controller values
              WidgetsBinding.instance.addPostFrameCallback((_) => _scaleRect());
            }

            return CustomPaint(
              size: Size.infinite,
              painter: CropGridPainter(
                _rect.value,
                showGrid: false,
                style: widget.controller.cropStyle,
              ),
            );
          }),
        ),
      ),
    );
  }
}
