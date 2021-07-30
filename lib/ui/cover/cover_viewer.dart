import 'package:flutter/material.dart';
import 'package:video_editor/domain/entities/transform_data.dart';
import 'package:video_editor/domain/bloc/controller.dart';
import 'package:video_editor/ui/crop/crop_grid_painter.dart';
import 'package:video_editor/ui/transform.dart';

class CoverViewer extends StatefulWidget {
  ///It is the viewer that allows you to crop the video
  CoverViewer({
    Key? key,
    required this.controller,
  }) : super(key: key);

  ///Essential argument for the functioning of the Widget
  final VideoEditorController controller;

  @override
  _CoverViewerState createState() => _CoverViewerState();
}

class _CoverViewerState extends State<CoverViewer> {
  final ValueNotifier<Rect> _rect = ValueNotifier<Rect>(Rect.zero);
  final ValueNotifier<TransformData> _transform = ValueNotifier<TransformData>(
    TransformData(rotation: 0.0, scale: 1.0, translate: Offset.zero),
  );

  Size _layout = Size.zero;

  late VideoEditorController _controller;

  @override
  void initState() {
    _controller = widget.controller;
    _controller.addListener(_scaleRect);

    _transform.value.initWithController(_controller);

    checkIfCoverIsNull();

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
    _rect.value = _calculateCoverRect();
    _transform.value = TransformData.fromRect(
      _rect.value,
      _layout,
      _controller,
    );

    checkIfCoverIsNull();
  }

  void checkIfCoverIsNull() {
    if (widget.controller.selectedCoverVal!.thumbData == null)
      widget.controller.generateDefaultCoverThumnail();
  }

  //-----------//
  //RECT CHANGE//
  //-----------//
  Rect _calculateCoverRect() {
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
    return LayoutBuilder(builder: (_, constraints) {
      Size size = Size(constraints.maxWidth, constraints.maxHeight);
      if (_layout != size) {
        _layout = size;
        _rect.value = _calculateCoverRect();
      }

      return AnimatedBuilder(
        animation: Listenable.merge(
            [_transform, widget.controller.selectedCoverNotifier]),
        builder: (_, __) {
          return (widget.controller.selectedCoverVal!.thumbData != null)
              ? CropTransform(
                  transform: _transform.value,
                  child: Container(
                    alignment: Alignment.center,
                    height: _layout.height,
                    width: _layout.width,
                    child: Stack(children: [
                      Image(
                        image: MemoryImage(
                            widget.controller.selectedCoverVal!.thumbData!),
                        width: _layout.width,
                        height: _layout.height,
                        alignment: Alignment.center,
                      ),
                      CustomPaint(
                        size: _layout,
                        painter: CropGridPainter(
                          _rect.value,
                          showGrid: false,
                          style: widget.controller.cropStyle,
                        ),
                      )
                    ]),
                  ),
                )
              : Text('No selection');
        },
      );
    });
  }
}
