import 'package:flutter/material.dart';
import 'package:video_editor/src/controller.dart';
import 'package:video_editor/src/utils/helpers.dart';
import 'package:video_editor/src/models/cover_data.dart';
import 'package:video_editor/src/models/transform_data.dart';
import 'package:video_editor/src/widgets/crop/crop_mixin.dart';

class CoverViewer extends StatefulWidget {
  /// It is the viewer that show the selected cover
  const CoverViewer({
    super.key,
    required this.controller,
    this.noCoverText = 'No selection',
  });

  /// The [controller] param is mandatory so every change in the controller settings will propagate the crop parameters in the cover view
  final VideoEditorController controller;

  /// The [noCoverText] param specifies the text to display when selectedCover is `null`
  final String noCoverText;

  @override
  State<CoverViewer> createState() => _CoverViewerState();
}

class _CoverViewerState extends State<CoverViewer> with CropPreviewMixin {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_scaleRect);
    _checkIfCoverIsNull();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_scaleRect);
    super.dispose();
  }

  void _scaleRect() {
    layout = computeLayout(widget.controller);
    rect.value = calculateCroppedRect(widget.controller, layout);
    transform.value = TransformData.fromRect(
      rect.value,
      layout,
      viewerSize,
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
  void updateRectFromBuild() => _scaleRect();

  @override
  Widget buildView(BuildContext context, TransformData transform) {
    return ValueListenableBuilder(
      valueListenable: widget.controller.selectedCoverNotifier,
      builder: (_, CoverData? selectedCover, __) {
        if (selectedCover?.thumbData == null) {
          return Center(child: Text(widget.noCoverText));
        }

        return buildImageView(
          widget.controller,
          selectedCover!.thumbData!,
          transform,
        );
      },
    );
  }
}
