import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_editor/src/controller.dart';
import 'package:video_editor/src/utils/helpers.dart';
import 'package:video_editor/src/utils/thumbnails.dart';
import 'package:video_editor/src/models/cover_data.dart';
import 'package:video_editor/src/models/cover_style.dart';
import 'package:video_editor/src/models/transform_data.dart';
import 'package:video_editor/src/widgets/crop/crop_grid_painter.dart';
import 'package:video_editor/src/widgets/image_viewer.dart';
import 'package:video_editor/src/widgets/transform.dart';

class CoverSelection extends StatefulWidget {
  /// Slider that allow to select a generated cover
  const CoverSelection({
    super.key,
    required this.controller,
    this.size = 60,
    this.quality = 10,
    this.quantity = 5,
    this.wrap,
    this.selectedCoverBuilder,
  });

  /// The [controller] param is mandatory so every change in the controller settings will propagate in the cover selection view
  final VideoEditorController controller;

  /// The [size] param specifies the size to display the generated thumbnails
  ///
  /// Defaults to `60`
  final double size;

  /// The [quality] param specifies the quality of the generated thumbnails, from 0 to 100 ([more info](https://pub.dev/packages/video_thumbnail))
  ///
  /// Defaults to `10`
  final int quality;

  /// The [quantity] param specifies the quantity of thumbnails to generate
  ///
  /// Default to `5`
  final int quantity;

  /// Specifies a [wrap] param to change how should be displayed the covers thumbnails
  /// the `children` param will be ommited
  final Wrap? wrap;

  /// Returns how the selected cover should be displayed
  final Widget Function(Widget selectedCover, Size)? selectedCoverBuilder;

  @override
  State<CoverSelection> createState() => _CoverSelectionState();
}

class _CoverSelectionState extends State<CoverSelection>
    with AutomaticKeepAliveClientMixin {
  Duration? _startTrim, _endTrim;

  Size _layout = Size.zero;
  final ValueNotifier<Rect> _rect = ValueNotifier<Rect>(Rect.zero);
  final ValueNotifier<TransformData> _transform =
      ValueNotifier<TransformData>(const TransformData());

  late Stream<List<CoverData>> _stream = (() => _generateCoverThumbnails())();

  @override
  void initState() {
    super.initState();
    _startTrim = widget.controller.startTrim;
    _endTrim = widget.controller.endTrim;
    widget.controller.addListener(_scaleRect);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_scaleRect);
    _transform.dispose();
    _rect.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  void _scaleRect() {
    _rect.value = calculateCroppedRect(widget.controller, _layout);

    _transform.value = TransformData.fromRect(
      _rect.value,
      _layout,
      Size.square(widget.size), // the maximum size to show the thumb
      null, // controller rotation should not affect this widget
    );

    // if trim values changed generate new thumbnails
    if (!widget.controller.isTrimming &&
        (_startTrim != widget.controller.startTrim ||
            _endTrim != widget.controller.endTrim)) {
      _startTrim = widget.controller.startTrim;
      _endTrim = widget.controller.endTrim;
      setState(() => _stream = _generateCoverThumbnails());
    }
  }

  Stream<List<CoverData>> _generateCoverThumbnails() => generateCoverThumbnails(
        widget.controller,
        quantity: widget.quantity,
        quality: widget.quality,
      );

  /// Returns the max size the layout should take with the rect value
  Size _calculateMaxLayout() {
    final ratio = _rect.value == Rect.zero
        ? widget.controller.video.value.aspectRatio
        : _rect.value.size.aspectRatio;
    return ratio < 1.0
        ? Size(widget.size * ratio, widget.size)
        : Size(widget.size, widget.size / ratio);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final wrap = widget.wrap ?? Wrap();

    return StreamBuilder<List<CoverData>>(
        stream: _stream,
        builder: (_, snapshot) {
          return snapshot.hasData
              ? ValueListenableBuilder<TransformData>(
                  valueListenable: _transform,
                  builder: (_, transform, __) => Wrap(
                    direction: wrap.direction,
                    alignment: wrap.alignment,
                    spacing: widget.wrap?.spacing ?? 10.0,
                    runSpacing: widget.wrap?.runSpacing ?? 10.0,
                    runAlignment: wrap.runAlignment,
                    crossAxisAlignment: wrap.crossAxisAlignment,
                    textDirection: wrap.textDirection,
                    verticalDirection: wrap.verticalDirection,
                    clipBehavior: wrap.clipBehavior,
                    children: snapshot.data!
                        .map(
                          (coverData) => ValueListenableBuilder<CoverData?>(
                              valueListenable:
                                  widget.controller.selectedCoverNotifier,
                              builder: (context, selectedCover, __) {
                                final isSelected = coverData.sameTime(
                                    widget.controller.selectedCoverVal!);
                                final coverThumbnail = _buildSingleCover(
                                  coverData,
                                  transform,
                                  widget.controller.coverStyle,
                                  isSelected: isSelected,
                                );

                                if (isSelected &&
                                    widget.selectedCoverBuilder != null) {
                                  final size = _calculateMaxLayout();
                                  return widget.selectedCoverBuilder!(
                                    coverThumbnail,
                                    widget.controller.isRotated
                                        ? size.flipped
                                        : size,
                                  );
                                }

                                return coverThumbnail;
                              }),
                        )
                        .toList()
                        .cast<Widget>(),
                  ),
                )
              : const SizedBox();
        });
  }

  Widget _buildSingleCover(
    CoverData cover,
    TransformData transform,
    CoverSelectionStyle coverStyle, {
    required bool isSelected,
  }) {
    // here the rotation should affect the dimension of the widget
    // it is better to use [RotatedBox] instead of [Tranform.rotate]
    return RotatedBox(
      quarterTurns: widget.controller.rotation ~/ -90,
      child: InkWell(
        borderRadius: BorderRadius.circular(coverStyle.borderRadius),
        onTap: () => widget.controller.updateSelectedCover(cover),
        child: SizedBox.fromSize(
          size: _calculateMaxLayout(),
          child: Stack(
            children: [
              CropTransform(
                transform: transform,
                child: ImageViewer(
                  controller: widget.controller,
                  bytes: cover.thumbData!,
                  child: LayoutBuilder(builder: (_, constraints) {
                    Size size = constraints.biggest;
                    if (_layout != size) {
                      _layout = size;
                      // init the widget with controller values
                      WidgetsBinding.instance
                          .addPostFrameCallback((_) => _scaleRect());
                    }

                    return RepaintBoundary(
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: CropGridPainter(
                          _rect.value,
                          radius: coverStyle.borderRadius / 2,
                          showGrid: false,
                          style: widget.controller.cropStyle,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(coverStyle.borderRadius),
                    border: Border.all(
                      color: isSelected
                          ? coverStyle.selectedBorderColor
                          : Colors.transparent,
                      width: coverStyle.borderWidth,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
