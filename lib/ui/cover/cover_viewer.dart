import 'package:flutter/material.dart';
import 'package:video_editor/domain/entities/cover_data.dart';
import 'package:video_editor/domain/entities/transform_data.dart';
import 'package:video_editor/domain/bloc/controller.dart';
import 'package:video_editor/domain/helpers.dart';
import 'package:video_editor/ui/crop/crop_grid_painter.dart';
import 'package:video_editor/ui/image_viewer.dart';
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
      ValueNotifier<TransformData>(const TransformData());

  Size _viewerSize = Size.zero;
  Size _layout = Size.zero;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_scaleRect);
    _checkIfCoverIsNull();
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
    _transform.value = TransformData.fromRect(
      _rect.value,
      _layout,
      _viewerSize,
      widget.controller,
    );

    _checkIfCoverIsNull();
  }

  void _checkIfCoverIsNull() {
    if (widget.controller.selectedCoverVal!.thumbData == null) {
      widget.controller.generateDefaultCoverThumbnail();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      _viewerSize = constraints.biggest;

      return ValueListenableBuilder(
        valueListenable: _transform,
        builder: (_, TransformData transform, __) => ValueListenableBuilder(
          valueListenable: widget.controller.selectedCoverNotifier,
          builder: (context, CoverData? selectedCover, __) =>
              selectedCover?.thumbData == null
                  ? Center(child: Text(widget.noCoverText))
                  : CropTransform(
                      transform: transform,
                      child: ImageViewer(
                        controller: widget.controller,
                        bytes: selectedCover!.thumbData!,
                        child: LayoutBuilder(
                          builder: (_, constraints) {
                            Size size = constraints.biggest;
                            if (_layout != size) {
                              _layout = size;
                              // init the widget with controller values
                              WidgetsBinding.instance
                                  .addPostFrameCallback((_) => _scaleRect());
                            }

                            return ValueListenableBuilder(
                              valueListenable: _rect,
                              builder: (_, Rect value, __) {
                                return CustomPaint(
                                  size: Size.infinite,
                                  painter: CropGridPainter(
                                    value,
                                    style: widget.controller.cropStyle,
                                    showGrid: false,
                                    showCenterRects: false,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
        ),
      );
    });
  }
}
