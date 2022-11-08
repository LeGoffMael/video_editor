import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_editor/domain/entities/cover_data.dart';
import 'package:video_editor/domain/entities/cover_style.dart';
import 'package:video_editor/domain/entities/transform_data.dart';
import 'package:video_editor/domain/helpers.dart';
import 'package:video_editor/ui/crop/crop_grid_painter.dart';
import 'package:video_editor/ui/image_viewer.dart';
import 'package:video_editor/ui/transform.dart';
import 'package:video_editor/domain/bloc/controller.dart';

class CoverSelection extends StatefulWidget {
  /// Slider that allow to select a generated cover
  const CoverSelection({
    Key? key,
    required this.controller,
    this.size = 60,
    this.quality = 10,
    this.quantity = 5,
  }) : super(key: key);

  /// The [controller] param is mandatory so every change in the controller settings will propagate in the cover selection view
  final VideoEditorController controller;

  /// The [size] param specifies the size to display the generated thumbnails
  final double size;

  /// The [quality] param specifies the quality of the generated thumbnails, from 0 to 100 ([more info](https://pub.dev/packages/video_thumbnail))
  final int quality;

  /// The [quantity] param specifies the quantity of thumbnails to generate
  final int quantity;

  @override
  State<CoverSelection> createState() => _CoverSelectionState();
}

class _CoverSelectionState extends State<CoverSelection>
    with AutomaticKeepAliveClientMixin {
  Duration? _startTrim, _endTrim;

  Size _layout = Size.zero;
  final ValueNotifier<Rect> _rect = ValueNotifier<Rect>(Rect.zero);
  final ValueNotifier<TransformData> _transform =
      ValueNotifier<TransformData>(TransformData());

  late Stream<List<CoverData>> _stream = (() => _generateThumbnails())();

  @override
  void dispose() {
    widget.controller.removeListener(_scaleRect);
    _transform.dispose();
    _rect.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _startTrim = widget.controller.startTrim;
    _endTrim = widget.controller.endTrim;
    widget.controller.addListener(_scaleRect);
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
      setState(() => _stream = _generateThumbnails());
    }
  }

  Stream<List<CoverData>> _generateThumbnails() async* {
    final int duration = widget.controller.isTrimmmed
        ? (widget.controller.endTrim - widget.controller.startTrim)
            .inMilliseconds
        : widget.controller.videoDuration.inMilliseconds;
    final double eachPart = duration / widget.quantity;
    List<CoverData> byteList = [];
    for (int i = 0; i < widget.quantity; i++) {
      try {
        final CoverData bytes = await widget.controller.generateCoverThumbnail(
            timeMs: (widget.controller.isTrimmmed
                    ? (eachPart * i) +
                        widget.controller.startTrim.inMilliseconds
                    : (eachPart * i))
                .toInt(),
            quality: widget.quality);

        if (bytes.thumbData != null) {
          byteList.add(bytes);
        }
      } catch (e) {
        debugPrint(e.toString());
      }

      yield byteList;
    }
  }

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

    return StreamBuilder(
        stream: _stream,
        builder: (_, AsyncSnapshot<List<CoverData>> snapshot) {
          return snapshot.hasData
              ? ValueListenableBuilder(
                  valueListenable: _transform,
                  builder: (_, TransformData transform, __) => Wrap(
                    runSpacing: 10.0,
                    spacing: 10.0,
                    children: snapshot.data!
                        .map(
                          (coverData) => ValueListenableBuilder(
                            valueListenable:
                                widget.controller.selectedCoverNotifier,
                            builder: (context, CoverData? selectedCover, __) =>
                                _buildSingleCover(
                              coverData,
                              transform,
                              widget.controller.coverStyle,
                              isSelected: coverData.sameTime(
                                  widget.controller.selectedCoverVal!),
                            ),
                          ),
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
        onTap: () => widget.controller.updateSelectedCover(cover),
        child: Stack(
          alignment: coverStyle.selectedIndicatorAlign,
          children: [
            Container(
              constraints: BoxConstraints.tight(_calculateMaxLayout()),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected
                      ? coverStyle.selectedBorderColor
                      : Colors.transparent,
                  width: coverStyle.selectedBorderWidth,
                ),
              ),
              child: CropTransform(
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
            ),
            isSelected && coverStyle.selectedIndicator != null
                ? coverStyle.selectedIndicator!
                : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
