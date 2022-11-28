import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoResultPopup extends StatefulWidget {
  const VideoResultPopup({super.key, required this.video});

  final File video;

  @override
  State<VideoResultPopup> createState() => _VideoResultPopupState();
}

class _VideoResultPopupState extends State<VideoResultPopup> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.video);
    _controller.initialize().then((_) {
      setState(() {});
      _controller.play();
      _controller.setLooping(true);
    });
  }

  @override
  void dispose() {
    _controller.pause();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Center(
        child: Stack(
          alignment: Alignment.bottomLeft,
          children: [
            AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
            Positioned(
              bottom: 0,
              child: FileDescription(
                description: {
                  'Video path': widget.video.path,
                  'Video duration':
                      '${(_controller.value.duration.inMilliseconds / 1000).toStringAsFixed(2)}s',
                  'Video ratio': _controller.value.aspectRatio.toString(),
                  'Video size': _controller.value.size.toString(),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CoverResultPopup extends StatefulWidget {
  const CoverResultPopup({super.key, required this.cover});

  final File cover;

  @override
  State<CoverResultPopup> createState() => _CoverResultPopupState();
}

class _CoverResultPopupState extends State<CoverResultPopup> {
  late final Uint8List _imagebytes = widget.cover.readAsBytesSync();
  Size? _fileSize;

  @override
  void initState() {
    super.initState();
    _readFileData();
  }

  Future<void> _readFileData() async {
    var decodedImage = await decodeImageFromList(_imagebytes);
    setState(() {
      _fileSize =
          Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Center(
        child: Stack(
          children: [
            Image.memory(_imagebytes),
            Positioned(
              bottom: 0,
              child: FileDescription(
                description: {
                  'Cover path': widget.cover.path,
                  'Cover size': _fileSize.toString(),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FileDescription extends StatelessWidget {
  const FileDescription({super.key, required this.description});

  final Map<String, String> description;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(fontSize: 11),
      child: Container(
        width: MediaQuery.of(context).size.width - 60,
        padding: const EdgeInsets.all(10),
        color: Colors.black.withOpacity(0.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: description.entries
              .map(
                (entry) => Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${entry.key}: ',
                        style: const TextStyle(fontSize: 11),
                      ),
                      TextSpan(
                        text: entry.value,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
