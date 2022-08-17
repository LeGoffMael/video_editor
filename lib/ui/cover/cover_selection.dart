import 'package:flutter/material.dart';
import 'package:video_editor/domain/entities/cover_data.dart';
import 'package:video_editor/domain/entities/transform_data.dart';
import 'package:video_editor/ui/crop/crop_grid_painter.dart';
import 'package:video_editor/ui/transform.dart';
import 'package:video_editor/domain/bloc/controller.dart';

class CoverSelection extends StatefulWidget {
  ///Slider that trim video length.
  CoverSelection({
    Key? key,
    required this.controller,
    this.height = 60,
    this.quality = 10,
    this.nbSelection = 5,
  }) : super(key: key);

  ///Essential argument for the functioning of the Widget
  final VideoEditorController controller;

  ///It is the height of the thumbnails
  final double height;

  ///Number of cover selectable
  final int nbSelection;

  ///**Quality of thumbnails:** 0 is the worst quality and 100 is the highest quality.
  final int quality;

  @override
  _CoverSelectionState createState() => _CoverSelectionState();
}

class _CoverSelectionState extends State<CoverSelection>
    with AutomaticKeepAliveClientMixin {
  double _aspect = 1.0, _width = 1.0;
  Duration? _startTrim, _endTrim;
  Size _layout = Size.zero;
  ValueNotifier<Rect> _rect = ValueNotifier<Rect>(Rect.zero);
  Stream<List<CoverData>>? _stream;
  ValueNotifier<TransformData> _transform = ValueNotifier<TransformData>(
    TransformData(rotation: 0.0, scale: 1.0, translate: Offset.zero),
  );

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
    _aspect = widget.controller.preferredCropAspectRatio ??
        widget.controller.video.value.aspectRatio;
    _startTrim = widget.controller.startTrim;
    _endTrim = widget.controller.endTrim;
    widget.controller.addListener(_scaleRect);

    // init the widget with controller values
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scaleRect();
    });
  }

  @override
  bool get wantKeepAlive => true;

  void _scaleRect() {
    _rect.value = _calculateCoverRect();
    _transform.value = TransformData.fromRect(
      _rect.value,
      _layout,
      widget.controller,
    );

    if (widget.controller.preferredCropAspectRatio != null &&
        _aspect != widget.controller.preferredCropAspectRatio) {
      _aspect = widget.controller.preferredCropAspectRatio!;
      _layout = _calculateLayout();
    }

    // if trim values changed generate new thumbnails
    if (!widget.controller.isTrimming &&
        (_startTrim != widget.controller.startTrim ||
            _endTrim != widget.controller.endTrim)) {
      _startTrim = widget.controller.startTrim;
      _endTrim = widget.controller.endTrim;
      setState(() {
        _stream = _generateThumbnails();
      });
    }
  }

  Stream<List<CoverData>> _generateThumbnails() async* {
    final int duration = widget.controller.isTrimmmed
        ? (widget.controller.endTrim - widget.controller.startTrim)
            .inMilliseconds
        : widget.controller.videoDuration.inMilliseconds;
    final double eachPart = duration / widget.nbSelection;
    List<CoverData> _byteList = [];
    for (int i = 0; i < widget.nbSelection; i++) {
      CoverData _bytes = await widget.controller.generateCoverThumbnail(
          timeMs: (widget.controller.isTrimmmed
                  ? (eachPart * i) + widget.controller.startTrim.inMilliseconds
                  : (eachPart * i))
              .toInt(),
          quality: widget.quality);

      if (_bytes.thumbData != null) {
        _byteList.add(_bytes);
      }

      yield _byteList;
    }
  }

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

  Size _calculateLayout() {
    return _aspect < 1.0
        ? Size(widget.height * _aspect, widget.height)
        : Size(widget.height, widget.height / _aspect);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return LayoutBuilder(builder: (_, box) {
      final double width = box.maxWidth;
      if (_width != width) {
        _width = width;
        _layout = _calculateLayout();
        _stream = _generateThumbnails();
        _rect.value = _calculateCoverRect();
      }

      return StreamBuilder(
          stream: _stream,
          builder: (_, AsyncSnapshot<List<CoverData>> snapshot) {
            final data = snapshot.data;
            return snapshot.hasData
                ? Wrap(
                    runSpacing: 10.0,
                    spacing: 10.0,
                    children: data!
                        .map((coverData) => ValueListenableBuilder(
                            valueListenable: _transform,
                            builder: (_, TransformData transform, __) {
                              return ValueListenableBuilder(
                                  valueListenable:
                                      widget.controller.selectedCoverNotifier,
                                  builder:
                                      (context, CoverData? selectedCover, __) {
                                    return InkWell(
                                        onTap: () => widget.controller
                                            .updateSelectedCover(coverData),
                                        child: Container(
                                            decoration: BoxDecoration(
                                                border: Border.all(
                                                    color: coverData.sameTime(
                                                            widget.controller
                                                                .selectedCoverVal!)
                                                        ? widget
                                                            .controller
                                                            .coverStyle
                                                            .selectedBorderColor
                                                        : Colors.transparent,
                                                    width: widget
                                                        .controller
                                                        .coverStyle
                                                        .selectedBorderWidth)),
                                            child: CropTransform(
                                              transform: transform,
                                              child: Container(
                                                alignment: Alignment.center,
                                                height: _layout.height,
                                                width: _layout.width,
                                                child: Stack(children: [
                                                  Image(
                                                      image: MemoryImage(
                                                          coverData.thumbData!),
                                                      width: _layout.width,
                                                      height: _layout.height),
                                                  CustomPaint(
                                                    size: _layout,
                                                    painter: CropGridPainter(
                                                        _rect.value,
                                                        showGrid: false,
                                                        style: widget.controller
                                                            .cropStyle),
                                                  )
                                                ]),
                                              ),
                                            )));
                                  });
                            }))
                        .toList()
                        .cast<Widget>(),
                  )
                : SizedBox();
          });
    });
  }
}
