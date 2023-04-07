import 'dart:io';

import 'package:ffmpeg_kit_flutter_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/return_code.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/statistics.dart';
import 'package:flutter/material.dart';
import 'package:helpers/helpers.dart' show OpacityTransition;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:video_editor/domain/entities/file_format.dart';
import 'package:video_editor/video_editor.dart';
import 'package:video_editor_example/crop.dart';
import 'package:video_editor_example/widgets/export_result.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

void main() => runApp(
      MaterialApp(
        title: 'Flutter Video Editor Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.grey,
          brightness: Brightness.dark,
          tabBarTheme: const TabBarTheme(
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
          dividerColor: Colors.white,
        ),
        home: const VideoEditorExample(),
      ),
    );

class VideoEditorExample extends StatefulWidget {
  const VideoEditorExample({super.key});

  @override
  State<VideoEditorExample> createState() => _VideoEditorExampleState();
}

class _VideoEditorExampleState extends State<VideoEditorExample> {
  final ImagePicker _picker = ImagePicker();

  void _pickVideo() async {
    final XFile? file = await _picker.pickVideo(source: ImageSource.gallery);

    if (mounted && file != null) {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (BuildContext context) => VideoEditor(file: File(file.path)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Image / Video Picker")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Click on the button to select video"),
            ElevatedButton(
              onPressed: _pickVideo,
              child: const Text("Pick Video From Gallery"),
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
  const VideoEditor({super.key, required this.file});

  final File file;

  @override
  State<VideoEditor> createState() => _VideoEditorState();
}

class _VideoEditorState extends State<VideoEditor> {
  final _exportingProgress = ValueNotifier<double>(0.0);
  final _isExporting = ValueNotifier<bool>(false);
  final double height = 60;

  late final VideoEditorController _controller = VideoEditorController.file(
    widget.file,
    minDuration: const Duration(seconds: 1),
    maxDuration: const Duration(seconds: 10),
  );

  @override
  void initState() {
    super.initState();
    _controller
        .initialize(aspectRatio: 9 / 16)
        .then((_) => setState(() {}))
        .catchError((error) {
      // handle minumum duration bigger than video duration error
      Navigator.pop(context);
    }, test: (e) => e is VideoMinDurationError);
  }

  @override
  void dispose() {
    _exportingProgress.dispose();
    _isExporting.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 1),
        ),
      );

  Future<void> _exportVideo() async {
    _exportingProgress.value = 0;
    _isExporting.value = true;
    // NOTE: To use `-crf 1` and [VideoExportPreset] you need `ffmpeg_kit_flutter_min_gpl` package (with `ffmpeg_kit` only it won't work)
    await exportVideo(
      // format: VideoExportFormat.gif,
      // preset: VideoExportPreset.medium,
      // customInstruction: "-crf 17",
      onProgress: (stats, value) => _exportingProgress.value = value,
      onError: (e, s) => _showErrorSnackBar("Error on export video :("),
      onCompleted: (file) {
        _isExporting.value = false;
        if (!mounted) return;

        showDialog(
          context: context,
          builder: (_) => VideoResultPopup(video: file),
        );
      },
    );
  }

  Future<void> _exportCover() async {
    await extractCover(
      onError: (e, s) => _showErrorSnackBar("Error on cover exportation :("),
      onCompleted: (cover) {
        if (!mounted) return;

        showDialog(
          context: context,
          builder: (_) => CoverResultPopup(cover: cover),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _controller.initialized
            ? SafeArea(
                child: Stack(
                  children: [
                    Column(
                      children: [
                        _topNavBar(),
                        Expanded(
                          child: DefaultTabController(
                            length: 2,
                            child: Column(
                              children: [
                                Expanded(
                                  child: TabBarView(
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    children: [
                                      Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          CropGridViewer.preview(
                                              controller: _controller),
                                          AnimatedBuilder(
                                            animation: _controller.video,
                                            builder: (_, __) =>
                                                OpacityTransition(
                                              visible: !_controller.isPlaying,
                                              child: GestureDetector(
                                                onTap: _controller.video.play,
                                                child: Container(
                                                  width: 40,
                                                  height: 40,
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: Colors.white,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.play_arrow,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      CoverViewer(controller: _controller)
                                    ],
                                  ),
                                ),
                                Container(
                                  height: 200,
                                  margin: const EdgeInsets.only(top: 10),
                                  child: Column(
                                    children: [
                                      TabBar(
                                        tabs: [
                                          Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: const [
                                                Padding(
                                                    padding: EdgeInsets.all(5),
                                                    child: Icon(
                                                        Icons.content_cut)),
                                                Text('Trim')
                                              ]),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: const [
                                              Padding(
                                                  padding: EdgeInsets.all(5),
                                                  child:
                                                      Icon(Icons.video_label)),
                                              Text('Cover')
                                            ],
                                          ),
                                        ],
                                      ),
                                      Expanded(
                                        child: TabBarView(
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          children: [
                                            Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: _trimSlider(),
                                            ),
                                            _coverSelection(),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ValueListenableBuilder(
                                  valueListenable: _isExporting,
                                  builder: (_, bool export, __) =>
                                      OpacityTransition(
                                    visible: export,
                                    child: AlertDialog(
                                      title: ValueListenableBuilder(
                                        valueListenable: _exportingProgress,
                                        builder: (_, double value, __) => Text(
                                          "Exporting video ${(value * 100).ceil()}%",
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _topNavBar() {
    return SafeArea(
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            Expanded(
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.exit_to_app),
                tooltip: 'Leave editor',
              ),
            ),
            const VerticalDivider(endIndent: 22, indent: 22),
            Expanded(
              child: IconButton(
                onPressed: () =>
                    _controller.rotate90Degrees(RotateDirection.left),
                icon: const Icon(Icons.rotate_left),
                tooltip: 'Rotate unclockwise',
              ),
            ),
            Expanded(
              child: IconButton(
                onPressed: () =>
                    _controller.rotate90Degrees(RotateDirection.right),
                icon: const Icon(Icons.rotate_right),
                tooltip: 'Rotate clockwise',
              ),
            ),
            Expanded(
              child: IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => CropScreen(controller: _controller),
                  ),
                ),
                icon: const Icon(Icons.crop),
                tooltip: 'Open crop screen',
              ),
            ),
            const VerticalDivider(endIndent: 22, indent: 22),
            Expanded(
              child: PopupMenuButton(
                tooltip: 'Open export menu',
                icon: const Icon(Icons.save),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    onTap: _exportCover,
                    child: const Text('Export cover'),
                  ),
                  PopupMenuItem(
                    onTap: _exportVideo,
                    child: const Text('Export video'),
                  ),
                ],
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
        animation: Listenable.merge([
          _controller,
          _controller.video,
        ]),
        builder: (_, __) {
          final duration = _controller.videoDuration.inSeconds;
          final pos = _controller.trimPosition * duration;

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: height / 4),
            child: Row(children: [
              Text(formatter(Duration(seconds: pos.toInt()))),
              const Expanded(child: SizedBox()),
              OpacityTransition(
                visible: _controller.isTrimming,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(formatter(_controller.startTrim)),
                  const SizedBox(width: 10),
                  Text(formatter(_controller.endTrim)),
                ]),
              ),
            ]),
          );
        },
      ),
      Container(
        width: MediaQuery.of(context).size.width,
        margin: EdgeInsets.symmetric(vertical: height / 4),
        child: TrimSlider(
          controller: _controller,
          height: height,
          horizontalMargin: height / 4,
          child: TrimTimeline(
            controller: _controller,
            padding: const EdgeInsets.only(top: 10),
          ),
        ),
      )
    ];
  }

  Widget _coverSelection() {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(15),
          child: CoverSelection(
            controller: _controller,
            size: height + 10,
            quantity: 8,
            selectedCoverBuilder: (cover, size) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  cover,
                  Icon(
                    Icons.check_circle,
                    color: const CoverSelectionStyle().selectedBorderColor,
                  )
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  //--------------//
  //VIDEO METADATA//
  //--------------//

  Future<void> getMetaData(
      {required void Function(Map<dynamic, dynamic>? metadata)
          onCompleted}) async {
    await FFprobeKit.getMediaInformationAsync(
      _controller.file.path,
      (session) async {
        final information = session.getMediaInformation();
        onCompleted(information?.getAllProperties());
      },
    );
  }

  //--------//
  // EXPORT //
  //--------//

  Future<String> _getOutputPath({
    required String filePath,
    required FileFormat format,
  }) async {
    final tempPath = (await getTemporaryDirectory()).path;
    final name = path.basenameWithoutExtension(filePath);
    final epoch = DateTime.now().millisecondsSinceEpoch;
    return "$tempPath/${name}_$epoch.${format.extension}";
  }

  Future<void> exportVideo({
    required void Function(File file) onCompleted,
    void Function(Object, StackTrace)? onError,
    void Function(Statistics, double)? onProgress,
    VideoExportFormat format = VideoExportFormat.mp4,
    double scale = 1.0,
    String customInstruction = '',
    VideoExportPreset preset = VideoExportPreset.none,
    bool isFiltersEnabled = true,
  }) async {
    final config = _controller.createVideoFFmpegConfig();
    final inputPath = _controller.file.path;
    final outputPath = await _getOutputPath(
      filePath: inputPath,
      format: format,
    );

    final execute = config.createExportCommand(
      inputPath: inputPath,
      outputPath: outputPath,
      format: format,
      scale: scale,
      customInstruction: customInstruction,
      preset: preset,
      isFiltersEnabled: isFiltersEnabled,
    );

    debugPrint('VideoEditor - run export video command : [$execute]');

    // PROGRESS CALLBACKS
    FFmpegKit.executeAsync(
      execute,
      (session) async {
        final state =
            FFmpegKitConfig.sessionStateToString(await session.getState());
        final code = await session.getReturnCode();

        if (ReturnCode.isSuccess(code)) {
          onCompleted(File(outputPath));
        } else {
          if (onError != null) {
            onError(
              Exception(
                  'FFmpeg process exited with state $state and return code $code.\n${await session.getOutput()}'),
              StackTrace.current,
            );
          }
          return;
        }
      },
      null,
      onProgress != null
          ? (stats) {
              // Progress value of encoded video
              final progressValue =
                  stats.getTime() / _controller.trimmedDuration.inMilliseconds;
              onProgress(stats, progressValue.clamp(0.0, 1.0));
            }
          : null,
    );
  }

  Future<void> extractCover({
    required void Function(File file) onCompleted,
    void Function(Object, StackTrace)? onError,
    void Function(Statistics)? onProgress,
    CoverExportFormat format = CoverExportFormat.jpg,
    double scale = 1.0,
    int quality = 100,
    bool isFiltersEnabled = true,
  }) async {
    var config = _controller.createCoverFFmpegConfig();

    // file generated from the thumbnail library or video source
    final coverPath = await _generateCoverFile(quality: quality);
    if (coverPath == null) {
      onError?.call(
        Exception('VideoThumbnail library error while exporting the cover'),
        StackTrace.current,
      );
      return;
    }
    final outputPath = await _getOutputPath(
      filePath: coverPath,
      format: format,
    );

    final execute = config.createCoverExportCommand(
      inputPath: coverPath,
      outputPath: outputPath,
      scale: scale,
      quality: quality,
      isFiltersEnabled: isFiltersEnabled,
    );

    debugPrint('VideoEditor - run export cover command : [$execute]');

    // PROGRESS CALLBACKS
    FFmpegKit.executeAsync(
      execute,
      (FFmpegSession session) async {
        final state =
            FFmpegKitConfig.sessionStateToString(await session.getState());
        final code = await session.getReturnCode();

        if (ReturnCode.isSuccess(code)) {
          onCompleted(File(outputPath));
        } else {
          onError?.call(
            Exception(
              'FFmpeg process exited with state $state and return code $code.\n${await session.getOutput()}',
            ),
            StackTrace.current,
          );
          return;
        }
      },
      null,
      onProgress,
    );
  }

  Future<String?> _generateCoverFile({int quality = 100}) async {
    return await VideoThumbnail.thumbnailFile(
      imageFormat: ImageFormat.JPEG,
      thumbnailPath: (await getTemporaryDirectory()).path,
      video: _controller.file.path,
      timeMs: _controller.selectedCoverVal?.timeMs ??
          _controller.startTrim.inMilliseconds,
      quality: quality,
    );
  }
}
