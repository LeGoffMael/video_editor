import 'package:flutter/material.dart';
import 'package:fraction/fraction.dart';
import 'package:video_editor/video_editor.dart';
import 'package:video_editor_example/main.dart';

class CropPage extends StatelessWidget {
  const CropPage({super.key, required this.controller});

  final VideoEditorController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: IconButton(
                      onPressed: () =>
                          controller.rotate90Degrees(RotateDirection.left),
                      icon: const Icon(Icons.rotate_left),
                    ),
                  ),
                  Expanded(
                    child: IconButton(
                      onPressed: () =>
                          controller.rotate90Degrees(RotateDirection.right),
                      icon: const Icon(Icons.rotate_right),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 15),
              Expanded(
                child: CropGridViewer.edit(
                  controller: controller,
                  rotateCropArea: false,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                ),
              ),
              const SizedBox(height: 15),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "cancel",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: AnimatedBuilder(
                      animation: controller,
                      builder: (_, __) => Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: () =>
                                    controller.preferredCropAspectRatio =
                                        controller.preferredCropAspectRatio
                                            ?.toFraction()
                                            .inverse()
                                            .toDouble(),
                                icon: controller.preferredCropAspectRatio !=
                                            null &&
                                        controller.preferredCropAspectRatio! < 1
                                    ? const Icon(
                                        Icons.panorama_vertical_select_rounded)
                                    : const Icon(
                                        Icons.panorama_vertical_rounded),
                              ),
                              IconButton(
                                onPressed: () =>
                                    controller.preferredCropAspectRatio =
                                        controller.preferredCropAspectRatio
                                            ?.toFraction()
                                            .inverse()
                                            .toDouble(),
                                icon: controller.preferredCropAspectRatio !=
                                            null &&
                                        controller.preferredCropAspectRatio! > 1
                                    ? const Icon(Icons
                                        .panorama_horizontal_select_rounded)
                                    : const Icon(
                                        Icons.panorama_horizontal_rounded),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildCropButton(context, null),
                              _buildCropButton(context, 1.toFraction()),
                              _buildCropButton(
                                  context, Fraction.fromString("9/16")),
                              _buildCropButton(
                                  context, Fraction.fromString("3/4")),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: TextButton(
                      onPressed: () {
                        // WAY 1: validate crop parameters set in the crop view
                        controller.applyCacheCrop();
                        // WAY 2: update manually with Offset values
                        // controller.updateCrop(const Offset(0.2, 0.2), const Offset(0.8, 0.8));
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "done",
                        style: TextStyle(
                          color: kPrimaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCropButton(BuildContext context, Fraction? f) {
    if (controller.preferredCropAspectRatio != null &&
        controller.preferredCropAspectRatio! > 1) f = f?.inverse();

    return Flexible(
      child: TextButton(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: controller.preferredCropAspectRatio == f?.toDouble()
              ? Colors.grey.shade800
              : null,
          foregroundColor: controller.preferredCropAspectRatio == f?.toDouble()
              ? Colors.white
              : Theme.of(context).colorScheme.onBackground,
          textStyle: Theme.of(context).textTheme.bodySmall,
        ),
        onPressed: () => controller.preferredCropAspectRatio = f?.toDouble(),
        child: FittedBox(
          child: Text(
            f == null ? 'free' : '${f.numerator}:${f.denominator}',
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}
