import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:video_editor/domain/bloc/controller.dart';
import 'package:video_editor/domain/entities/transform_data.dart';
import 'package:video_editor/domain/helpers.dart';
import 'package:video_editor/domain/thumbnails.dart';
import 'package:video_editor/ui/crop/crop_grid_painter.dart';
import 'package:video_editor/ui/image_viewer.dart';
import 'package:video_editor/ui/transform.dart';

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
  late Size _maxLayout = _calculateMaxLayout();

  /// The quantity of thumbnails to generate
  int _thumbnailsCount = 8;
  late int _neededThumbnails = _thumbnailsCount;

  late Stream<List<Uint8List>> _stream = (() => _generateThumbnails())();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_scaleRect);
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
    _maxLayout = _calculateMaxLayout();

    _transform.value = TransformData.fromRect(
      _rect.value,
      _layout,
      _maxLayout, // the maximum size to show the thumb
      widget.controller,
    );

    // regenerate thumbnails if need more to fit the slider
    _neededThumbnails = (_sliderWidth ~/ _maxLayout.width) + 1;
    if (_neededThumbnails > _thumbnailsCount) {
      _thumbnailsCount = _neededThumbnails;
      setState(() => _stream = _generateThumbnails());
    }
  }

  Stream<List<Uint8List>> _generateThumbnails() => generateTrimThumbnails(
        widget.controller,
        quantity: _thumbnailsCount,
        quality: widget.quality,
      );

  /// Returns the max size the layout should take with the rect value
  Size _calculateMaxLayout() {
    final ratio = _rect.value == Rect.zero
        ? widget.controller.video.value.aspectRatio
        : _rect.value.size.aspectRatio;

    // check if the ratio is almost 1
    if (isNumberAlmost(ratio, 1)) return Size.square(widget.height);

    final size = Size(widget.height * ratio, widget.height);

    if (widget.controller.isRotated) {
      return Size(widget.height / ratio, widget.height);
    }
    return size;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, box) {
      _sliderWidth = box.maxWidth;

      return StreamBuilder<List<Uint8List>>(
        stream: _stream,
        builder: (_, snapshot) {
          final data = snapshot.data;
          return snapshot.hasData
              ? ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _neededThumbnails,
                  itemBuilder: (_, i) => ValueListenableBuilder<TransformData>(
                    valueListenable: _transform,
                    builder: (_, transform, __) {
                      final index =
                          getBestIndex(_neededThumbnails, data!.length, i);

                      return Stack(
                        children: [
                          Opacity(
                            opacity: 0.2,
                            child: _buildSingleThumbnail(
                              data[0],
                              transform,
                              isPlaceholder: true,
                            ),
                          ),
                          if (index < data.length)
                            _buildSingleThumbnail(
                              data[index],
                              transform,
                              isPlaceholder: false,
                            ),
                        ],
                      );
                    },
                  ),
                )
              : const SizedBox();
        },
      );
    });
  }

  Widget _buildSingleThumbnail(
    Uint8List bytes,
    TransformData transform, {
    required bool isPlaceholder,
  }) {
    return Container(
      constraints: BoxConstraints.tight(_maxLayout),
      child: CropTransform(
        transform: transform,
        child: ImageViewer(
          controller: widget.controller,
          bytes: bytes,
          fadeIn: !isPlaceholder,
          child: LayoutBuilder(builder: (_, constraints) {
            Size size = constraints.biggest;
            if (!isPlaceholder && _layout != size) {
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
