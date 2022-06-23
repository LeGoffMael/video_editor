import 'package:flutter/material.dart';
import 'package:video_editor/domain/entities/cover_data.dart';
import 'package:video_editor/domain/entities/transform_data.dart';
import 'package:video_editor/domain/bloc/controller.dart';
import 'package:video_editor/ui/crop/crop_grid_painter.dart';
import 'package:video_editor/ui/transform.dart';

class CoverViewer extends StatefulWidget {
  /// It is the viewer that show the selected cover
  const CoverViewer({
    Key? key,
    required this.controller,
    this.noCoverText = 'No selection',
  }) : super(key: key);

  /// The [controller] param is mandatory so every change in the controller settings will propagate the crop parameters in the cover view
  final VideoEditorController controller;

  /// The [noCoverText] param specifies the text to display when selectedCover is `null`
  final String noCoverText;

  @override
  State<CoverViewer> createState() => _CoverViewerState();
}

class _CoverViewerState extends State<CoverViewer> {
  final ValueNotifier<Rect> _rect = ValueNotifier<Rect>(Rect.zero);
  final ValueNotifier<TransformData> _transform =
      ValueNotifier<TransformData>(TransformData());

  Size _layout = Size.zero;

  late VideoEditorController _controller;

  @override
  void initState() {
    _controller = widget.controller;
    _controller.addListener(_scaleRect);

    _checkIfCoverIsNull();

    super.initState();
  }

  @override
  void dispose() {
    _controller.removeListener(_scaleRect);
    _transform.dispose();
    _rect.dispose();
    super.dispose();
  }

  void _scaleRect() {
    _rect.value = _calculateCropRect();
    _transform.value = TransformData.fromRect(
      _rect.value,
      _layout,
      _controller,
    );

    _checkIfCoverIsNull();
  }

  void _checkIfCoverIsNull() {
    if (widget.controller.selectedCoverVal!.thumbData == null) {
      widget.controller.generateDefaultCoverThumbnail();
    }
  }

  //-----------//
  //RECT CHANGE//
  //-----------//
  Rect _calculateCropRect([Offset? min, Offset? max]) {
    final Offset minCrop = min ?? _controller.minCrop;
    final Offset maxCrop = max ?? _controller.maxCrop;

    return Rect.fromPoints(
      Offset(minCrop.dx * _layout.width, minCrop.dy * _layout.height),
      Offset(maxCrop.dx * _layout.width, maxCrop.dy * _layout.height),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: _transform,
        builder: (_, TransformData transform, __) => ValueListenableBuilder(
            valueListenable: widget.controller.selectedCoverNotifier,
            builder: (context, CoverData? selectedCover, __) => selectedCover
                        ?.thumbData ==
                    null
                ? Center(child: Text(widget.noCoverText))
                : CropTransform(
                    transform: transform,
                    child: Center(
                        child: Stack(children: [
                      AspectRatio(
                        aspectRatio: widget.controller.video.value.aspectRatio,
                        child: Image(
                          image: MemoryImage(selectedCover!.thumbData!),
                          alignment: Alignment.center,
                        ),
                      ),
                      AspectRatio(
                          aspectRatio:
                              widget.controller.video.value.aspectRatio,
                          child: LayoutBuilder(
                            builder: (_, constraints) {
                              Size size = Size(
                                  constraints.maxWidth, constraints.maxHeight);
                              if (_layout != size) {
                                _layout = size;
                                // init the widget with controller values
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  _scaleRect();
                                });
                              }

                              return ValueListenableBuilder(
                                valueListenable: _rect,
                                builder: (_, Rect value, __) {
                                  return CustomPaint(
                                    size: Size.infinite,
                                    painter: CropGridPainter(
                                      value,
                                      style: _controller.cropStyle,
                                      showGrid: false,
                                      showCenterRects: _controller
                                              .preferredCropAspectRatio ==
                                          null,
                                    ),
                                  );
                                },
                              );
                            },
                          ))
                    ])))));
  }
}
