import 'dart:io';

import 'package:flutter/material.dart';
import 'package:helpers/helpers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_editor/video_editor.dart';
import 'package:video_player/video_player.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        textTheme: TextTheme(
          bodyText1: TextStyle(),
          bodyText2: TextStyle(),
        ).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
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
    final XFile? file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file != null) context.to(VideoEditor(file: File(file.path)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          backgroundColor: Colors.blue, title: Text("Image / Video Picker")),
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
  VideoEditor({Key? key, required this.file}) : super(key: key);

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
  late VideoEditorController _controller;

  @override
  void initState() {
    _controller = VideoEditorController.file(widget.file,
        maxDuration: Duration(seconds: 30))
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
    _isExporting.value = true;
    bool _firstStat = true;
    //NOTE: To use [-crf 17] and [VideoExportPreset] you need ["min-gpl-lts"] package
    await _controller.exportVideo(
      // preset: VideoExportPreset.medium,
      // customInstruction: "-crf 17",
      onProgress: (statics) {
        // First statistics is always wrong so if first one skip it
        if (_firstStat) {
          _firstStat = false;
        } else {
          _exportingProgress.value = statics.getTime() /
              _controller.video.value.duration.inMilliseconds;
        }
      },
      onCompleted: (file) {
        _isExporting.value = false;
        if (!mounted) return;
        if (file != null) {
          final VideoPlayerController _videoController =
              VideoPlayerController.file(file);
          _videoController.initialize().then((value) async {
            setState(() {});
            _videoController.play();
            _videoController.setLooping(true);
            await showModalBottomSheet(
              context: context,
              backgroundColor: Colors.black54,
              builder: (_) => AspectRatio(
                aspectRatio: _videoController.value.aspectRatio,
                child: VideoPlayer(_videoController),
              ),
            );
            await _videoController.pause();
            _videoController.dispose();
          });
          _exportText = "Video success export!";
        } else {
          _exportText = "Error on export video :(";
        }

        setState(() => _exported = true);
        Misc.delayed(2000, () => setState(() => _exported = false));
      },
    );
  }

  void _exportCover() async {
    setState(() => _exported = false);
    await _controller.extractCover(
      onCompleted: (cover) {
        if (!mounted) return;

        if (cover != null) {
          _exportText = "Cover exported! ${cover.path}";
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.black54,
            builder: (BuildContext context) =>
                Image.memory(cover.readAsBytesSync()),
          );
        } else
          _exportText = "Error on cover exportation :(";

        setState(() => _exported = true);
        Misc.delayed(2000, () => setState(() => _exported = false));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _controller.initialized
          ? SafeArea(
              child: Stack(children: [
              Column(children: [
                _topNavBar(),
                Expanded(
                    child: DefaultTabController(
                        length: 2,
                        child: Column(children: [
                          Expanded(
                              child: TabBarView(
                            physics: NeverScrollableScrollPhysics(),
                            children: [
                              Stack(alignment: Alignment.center, children: [
                                CropGridViewer(
                                  controller: _controller,
                                  showGrid: false,
                                ),
                                AnimatedBuilder(
                                  animation: _controller.video,
                                  builder: (_, __) => OpacityTransition(
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
                                        child: Icon(Icons.play_arrow,
                                            color: Colors.black),
                                      ),
                                    ),
                                  ),
                                ),
                              ]),
                              CoverViewer(controller: _controller)
                            ],
                          )),
                          Container(
                              height: 200,
                              margin: Margin.top(10),
                              child: Column(children: [
                                TabBar(
                                  indicatorColor: Colors.white,
                                  tabs: [
                                    Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Padding(
                                              padding: Margin.all(5),
                                              child: Icon(Icons.content_cut)),
                                          Text('Trim')
                                        ]),
                                    Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Padding(
                                              padding: Margin.all(5),
                                              child: Icon(Icons.video_label)),
                                          Text('Cover')
                                        ]),
                                  ],
                                ),
                                Expanded(
                                  child: TabBarView(
                                    children: [
                                      Container(
                                          child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: _trimSlider())),
                                      Container(
                                        child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [_coverSelection()]),
                                      ),
                                    ],
                                  ),
                                )
                              ])),
                          _customSnackBar(),
                          ValueListenableBuilder(
                            valueListenable: _isExporting,
                            builder: (_, bool export, __) => OpacityTransition(
                              visible: export,
                              child: AlertDialog(
                                backgroundColor: Colors.white,
                                title: ValueListenableBuilder(
                                  valueListenable: _exportingProgress,
                                  builder: (_, double value, __) =>
                                      TextDesigned(
                                    "Exporting video ${(value * 100).ceil()}%",
                                    color: Colors.black,
                                    bold: true,
                                  ),
                                ),
                              ),
                            ),
                          )
                        ])))
              ])
            ]))
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
                child: Icon(Icons.rotate_left),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => _controller.rotate90Degrees(RotateDirection.right),
                child: Icon(Icons.rotate_right),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: _openCropScreen,
                child: Icon(Icons.crop),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: _exportCover,
                child: Icon(Icons.save_alt, color: Colors.white),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: _exportVideo,
                child: Icon(Icons.save),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String formatter(Duration duration) => [
        duration.inMinutes.remainder(60).toString().padLeft(2, '0'),
        duration.inSeconds.remainder(60).toString().padLeft(2, '0')
      ].join(":");

  List<Widget> _trimSlider() {
    return [
      AnimatedBuilder(
        animation: _controller.video,
        builder: (_, __) {
          final duration = _controller.video.value.duration.inSeconds;
          final pos = _controller.trimPosition * duration;
          final start = _controller.minTrim * duration;
          final end = _controller.maxTrim * duration;

          return Padding(
            padding: Margin.horizontal(height / 4),
            child: Row(children: [
              TextDesigned(formatter(Duration(seconds: pos.toInt()))),
              Expanded(child: SizedBox()),
              OpacityTransition(
                visible: _controller.isTrimming,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  TextDesigned(formatter(Duration(seconds: start.toInt()))),
                  SizedBox(width: 10),
                  TextDesigned(formatter(Duration(seconds: end.toInt()))),
                ]),
              )
            ]),
          );
        },
      ),
      Container(
        width: MediaQuery.of(context).size.width,
        margin: Margin.vertical(height / 4),
        child: TrimSlider(
            child: TrimTimeline(
                controller: _controller, margin: EdgeInsets.only(top: 10)),
            controller: _controller,
            height: height,
            horizontalMargin: height / 4),
      )
    ];
  }

  Widget _coverSelection() {
    return Container(
        margin: Margin.horizontal(height / 4),
        child: CoverSelection(
          controller: _controller,
          height: height,
          nbSelection: 8,
        ));
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
  CropScreen({Key? key, required this.controller}) : super(key: key);

  final VideoEditorController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: Margin.all(30),
          child: Column(children: [
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => controller.rotate90Degrees(RotateDirection.left),
                  child: Icon(Icons.rotate_left),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () =>
                      controller.rotate90Degrees(RotateDirection.right),
                  child: Icon(Icons.rotate_right),
                ),
              )
            ]),
            SizedBox(height: 15),
            Expanded(
              child: AnimatedInteractiveViewer(
                maxScale: 2.4,
                child: CropGridViewer(
                  controller: controller,
                  horizontalMargin: 60,
                  enableGestureResizeCrop: true,
                ),
              ),
            ),
            SizedBox(height: 15),
            Row(children: [
              Expanded(
                child: SplashTap(
                  onTap: context.goBack,
                  child: Center(
                    child: TextDesigned(
                      "CANCEL",
                      bold: true,
                    ),
                  ),
                ),
              ),
              buildSplashTap("16:9", 16 / 9, padding: Margin.horizontal(10)),
              buildSplashTap("1:1", 1 / 1),
              buildSplashTap("4:5", 3 / 2, padding: Margin.horizontal(10)),
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
                    child: TextDesigned("OK", bold: true),
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
    double? aspectRatio, {
    EdgeInsetsGeometry? padding,
  }) {
    return SplashTap(
      onTap: () => controller.preferredCropAspectRatio = aspectRatio,
      child: Padding(
        padding: padding ?? Margin.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.aspect_ratio, color: Colors.white),
            TextDesigned(title, bold: true),
          ],
        ),
      ),
    );
  }
}
