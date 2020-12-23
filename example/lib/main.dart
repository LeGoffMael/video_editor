import 'dart:io';
import 'package:helpers/helpers.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_editor/video_editor.dart';
import 'package:gallery_saver/gallery_saver.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ImagePicker _picker = ImagePicker();

  void _pickVideo() async {
    final PickedFile file = await _picker.getVideo(source: ImageSource.gallery);
    if (file != null)
      PushRoute.page(context, VideoEditor(file: File(file.path)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Image / Video Picker")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Click on Pick Video to select video",
              style: TextStyle(fontSize: 18.0),
            ),
            RaisedButton(
              onPressed: _pickVideo,
              child: Text("Pick Video From Gallery"),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoEditor extends StatefulWidget {
  VideoEditor({Key key, this.file}) : super(key: key);

  final File file;

  @override
  _VideoEditorState createState() => _VideoEditorState();
}

class _VideoEditorState extends State<VideoEditor> {
  VideoEditorController _controller;
  final double height = 60;
  bool _exported = false;

  @override
  void initState() {
    _controller = VideoEditorController.file(widget.file)
      ..initialize().then((_) => setState(() {}));
    _controller.addListener(() => setState(() {}));
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _exportVideo() async {
    final File file = await _controller.exportVideo();
    await GallerySaver.saveVideo(file.path, albumName: "Video Editor");
    setState(() => _exported = true);
    Misc.delayed(2000, () => setState(() => _exported = false));
  }

  void _openCropScreen() {
    PushRoute.page(context, CropScreen(controller: _controller));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _controller.initialized
          ? Stack(children: [
              Column(children: [
                _topNavBar(),
                Expanded(
                  child: ClipRRect(
                    child: CropGridView(
                      controller: _controller,
                      showGrid: false,
                    ),
                  ),
                ),
                _bottomNavBar(),
              ]),
              Center(
                child: OpacityTransition(
                  visible: !_controller.isPlaying,
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
              _customSnackBar(),
            ])
          : Center(child: CircularProgressIndicator()),
    );
  }

  Widget _topNavBar() {
    return Align(
      alignment: Alignment.topCenter,
      child: SafeArea(
        child: Container(
          height: height,
          child: Row(
            children: [
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
      ),
    );
  }

  Widget _bottomNavBar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: height,
        margin: Margin.all(height / 4),
        child: TrimSlider(
          controller: _controller,
          height: height,
        ),
      ),
    );
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
              "Video success export!",
              color: Colors.white,
              bold: true,
            ),
          ),
        ),
      ),
    );
  }
}

class CropScreen extends StatefulWidget {
  CropScreen({
    Key key,
    @required this.controller,
  }) : super(key: key);

  final VideoEditorController controller;

  @override
  _CropScreenState createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  Offset _minCrop;
  Offset _maxCrop;

  @override
  void initState() {
    _minCrop = widget.controller.minCrop;
    _maxCrop = widget.controller.maxCrop;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: Margin.all(30),
          child: Column(children: [
            Expanded(
              child: CropGridView(
                controller: widget.controller,
                onChangeCrop: (min, max) => setState(() {
                  _minCrop = min;
                  _maxCrop = max;
                }),
              ),
            ),
            SizedBox(height: 15),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Center(
                    child: TextDesigned("CANCELAR",
                        color: Colors.white, bold: true),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    widget.controller.updateCrop(_minCrop, _maxCrop);
                    Navigator.of(context).pop();
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
}
