import 'dart:io';
import 'package:helpers/helpers.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_editor/video_editor.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: VideoPickerPage(),
    );
  }
}

//-------------------//
//PICKUP VIDEO SCREEN//
//-------------------//
class VideoPickerPage extends StatefulWidget {
  @override
  _VideoPickerPageState createState() => _VideoPickerPageState();
}

class _VideoPickerPageState extends State<VideoPickerPage> {
  final ImagePicker _picker = ImagePicker();

  void _pickVideo() async {
    final PickedFile file = await _picker.getVideo(source: ImageSource.gallery);
    if (file != null) context.to(VideoEditor(file: File(file.path)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Image / Video Picker")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextDesigned(
              "Click on Pick Video to select video",
              color: Colors.black,
              size: 18.0,
            ),
            ElevatedButton(
              onPressed: _pickVideo,
              child: Text("Pick Video From Gallery"),
            ),
          ],
        ),
      ),
    );
  }
}

//-------------------//
//VIDEO EDITOR SCREEN//
//-------------------//
class VideoEditor extends StatefulWidget {
  VideoEditor({Key key, this.file}) : super(key: key);

  final File file;

  @override
  _VideoEditorState createState() => _VideoEditorState();
}

class _VideoEditorState extends State<VideoEditor> {
  final _exportingProgress = ValueNotifier<double>(0.0);
  final _isExporting = ValueNotifier<bool>(false);
  final double height = 60;

  bool _exported = false;
  String _exportText = "";
  VideoEditorController _controller;

  @override
  void initState() {
    _controller = VideoEditorController.file(widget.file)
      ..initialize().then((_) => setState(() {}));
    super.initState();
  }

  @override
  void dispose() {
    _exportingProgress.dispose();
    _isExporting.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _openCropScreen() => context.to(CropScreen(controller: _controller));

  void _exportVideo() async {
    Misc.delayed(1000, () => _isExporting.value = true);
    //NOTE: To use [-crf 17] and [VideoExportPreset] you need ["min-gpl-lts"] package
    final File file = await _controller.exportVideo(
      preset: VideoExportPreset.medium,
      customInstruction: "-crf 17",
      onProgress: (statics) {
        if (_controller.video != null)
          _exportingProgress.value =
              statics.time / _controller.video.value.duration.inMilliseconds;
      },
    );
    _isExporting.value = false;

    if (file != null) {
      await ImageGallerySaver.saveFile(file.path);
      _exportText = "Video success export!";
    } else {
      _exportText = "Error on export video :(";
    }

    setState(() => _exported = true);
    Misc.delayed(2000, () => setState(() => _exported = false));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _controller.initialized
          ? AnimatedBuilder(
              animation: _controller.video,
              builder: (_, __) {
                return Stack(children: [
                  Column(children: [
                    _topNavBar(),
                    Expanded(
                      child: ClipRRect(
                        child: CropGridViewer(
                          controller: _controller,
                          showGrid: false,
                        ),
                      ),
                    ),
                    ..._trimSlider(),
                  ]),
                  Center(
                    child: OpacityTransition(
                      visible: !_controller.isPlaying,
                      child: GestureDetector(
                        onTap: _controller.video.play,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.play_arrow),
                        ),
                      ),
                    ),
                  ),
                  _customSnackBar(),
                  ValueListenableBuilder(
                    valueListenable: _isExporting,
                    builder: (_, bool export, __) => OpacityTransition(
                      visible: export,
                      child: AlertDialog(
                        title: ValueListenableBuilder(
                          valueListenable: _exportingProgress,
                          builder: (_, double value, __) => TextDesigned(
                            "Exporting video ${(value * 100).ceil()}%",
                            color: Colors.black,
                            bold: true,
                          ),
                        ),
                      ),
                    ),
                  )
                ]);
              })
          : Center(child: CircularProgressIndicator()),
    );
  }

  Widget _topNavBar() {
    return SafeArea(
      child: Container(
        height: height,
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _controller.rotate90Degrees(RotateDirection.left),
                child: Icon(Icons.rotate_left, color: Colors.white),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => _controller.rotate90Degrees(RotateDirection.right),
                child: Icon(Icons.rotate_right, color: Colors.white),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: _openCropScreen,
                child: Icon(Icons.crop, color: Colors.white),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: _exportVideo,
                child: Icon(Icons.save, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _trimSlider() {
    final duration = _controller.videoDuration.inSeconds;
    final pos = _controller.trimPosition * duration;
    final start = _controller.minTrim * duration;
    final end = _controller.maxTrim * duration;

    String formatter(Duration duration) =>
        duration.inMinutes.remainder(60).toString().padLeft(2, '0') +
        ":" +
        (duration.inSeconds.remainder(60)).toString().padLeft(2, '0');

    return [
      Padding(
        padding: Margin.horizontal(height / 4),
        child: Row(children: [
          TextDesigned(
            formatter(Duration(seconds: pos.toInt())),
            color: Colors.white,
          ),
          Expanded(child: SizedBox()),
          OpacityTransition(
            visible: _controller.isTrimming,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              TextDesigned(
                formatter(Duration(seconds: start.toInt())),
                color: Colors.white,
              ),
              SizedBox(width: 10),
              TextDesigned(
                formatter(Duration(seconds: end.toInt())),
                color: Colors.white,
              ),
            ]),
          )
        ]),
      ),
      Container(
        height: height,
        margin: Margin.all(height / 4),
        child: TrimSlider(
          controller: _controller,
          height: height,
        ),
      )
    ];
  }

  Widget _customSnackBar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SwipeTransition(
        visible: _exported,
        direction: SwipeDirection.fromBottom,
        child: Container(
          height: height,
          width: double.infinity,
          color: Colors.black.withOpacity(0.8),
          child: Center(
            child: TextDesigned(
              _exportText,
              color: Colors.white,
              bold: true,
            ),
          ),
        ),
      ),
    );
  }
}

//-----------------//
//CROP VIDEO SCREEN//
//-----------------//
class CropScreen extends StatelessWidget {
  CropScreen({Key key, @required this.controller}) : super(key: key);

  final VideoEditorController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: Margin.all(30),
          child: Column(children: [
            Expanded(
              child: CropGridViewer(controller: controller),
            ),
            SizedBox(height: 15),
            Row(children: [
              Expanded(
                child: SplashTap(
                  onTap: context.goBack,
                  child: Center(
                    child: TextDesigned(
                      "CANCELAR",
                      color: Colors.white,
                      bold: true,
                    ),
                  ),
                ),
              ),
              buildSplashTap("16:9", 16 / 9, padding: Margin.horizontal(10)),
              buildSplashTap("1:1", 1 / 1),
              buildSplashTap("4:5", 4 / 5, padding: Margin.horizontal(10)),
              buildSplashTap("NO", null, padding: Margin.right(10)),
              Expanded(
                child: SplashTap(
                  onTap: () {
                    //2 WAYS TO UPDATE CROP

                    //WAY 1:
                    controller.updateCrop();

                    /*WAY 2:
                    controller.minCrop = controller.cacheMinCrop;
                    controller.maxCrop = controller.cacheMaxCrop;
                    */

                    context.goBack();
                  },
                  child: Center(
                    child: TextDesigned("OK", color: Colors.white, bold: true),
                  ),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget buildSplashTap(
    String title,
    double aspectRatio, {
    EdgeInsetsGeometry padding,
  }) {
    return SplashTap(
      onTap: () => controller.preferredCropAspectRatio = aspectRatio,
      child: Padding(
        padding: padding ?? Margin.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.aspect_ratio, color: Colors.white),
            TextDesigned(title, color: Colors.white, bold: true),
          ],
        ),
      ),
    );
  }
}
