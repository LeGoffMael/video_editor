import 'dart:async';
import 'dart:convert';

import 'package:ffmpeg_kit_flutter_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/return_code.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/statistics.dart';
import 'package:ffmpeg_wasm/ffmpeg_wasm.dart';
import 'package:flutter/foundation.dart';
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
          builder: (BuildContext context) => VideoEditor(file: file),
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

  final XFile file;

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
    // TODO(maRci002): transparent needed on the web?
    cropStyle: const CropGridStyle(background: Colors.transparent),
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
    try {
      final video = await exportVideo(
        // outputFormat: VideoExportFormat.gif,
        // preset: VideoExportPreset.medium,
        // customInstruction: "-crf 17",
        onProgress: (stats, value) => _exportingProgress.value = value,
      );

      _isExporting.value = false;

      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => VideoResultPopup(video: video),
        );
      }
    } catch (e) {
      _showErrorSnackBar("Error on export video :(");
    }
  }

  Future<void> _exportCover() async {
    try {
      final cover = await extractCover();

      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => CoverResultPopup(cover: cover),
        );
      }
    } catch (e) {
      _showErrorSnackBar("Error on cover exportation :(");
    }
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
    if (kIsWeb) {
      // Default FFMPEG lib throws: Requested output format 'json' is not a suitable output format
      final format = FileFormat.fromMimeType(_controller.file.mimeType);
      final inputPath = webInputPath(format);
      const outputPath = 'output.json';

      final outputFile = await executeFFmpegWeb(
        execute: '-i $inputPath -f ffmetadata -f json $outputPath',
        inputData: await _controller.file.readAsBytes(),
        outputMimeType: 'application/json',
        inputPath: inputPath,
        outputPath: outputPath,
      );

      onCompleted(json.decode(await outputFile.readAsString()));
    } else {
      await FFprobeKit.getMediaInformationAsync(
        _controller.file.path,
        (session) async {
          final information = session.getMediaInformation();
          onCompleted(information?.getAllProperties());
        },
      );
    }
  }

  //--------//
  // EXPORT //
  //--------//

  Future<XFile> executeFFmpegIO({
    required String execute,
    required String outputPath,
    int totalVideoDurationMs = 0,
    void Function(FFmpegStatistics, double)? onProgress,
  }) {
    final completer = Completer<XFile>();

    FFmpegKit.executeAsync(
      execute,
      (session) async {
        final state =
            FFmpegKitConfig.sessionStateToString(await session.getState());
        final code = await session.getReturnCode();

        if (ReturnCode.isSuccess(code)) {
          completer.complete(XFile(outputPath));
        } else {
          completer.completeError(
            Exception(
              'FFmpeg process exited with state $state and return code $code.'
              '${await session.getOutput()}',
            ),
          );
        }
      },
      null,
      onProgress != null
          ? (s) {
              final progress = totalVideoDurationMs <= 0
                  ? 0.0
                  : s.getTime() / totalVideoDurationMs;

              final statistics = FFmpegStatistics.fromStatistics(s);
              onProgress(statistics, progress.clamp(0.0, 1.0));
            }
          : null,
    );

    return completer.future;
  }

  Future<XFile> executeFFmpegWeb({
    required String execute,
    required Uint8List inputData,
    required String inputPath,
    required String outputPath,
    String? outputMimeType,
    int totalVideoDurationMs = 0,
    void Function(FFmpegStatistics, double)? onProgress,
  }) async {
    FFmpeg? ffmpeg;
    final logs = <String>[];
    try {
      ffmpeg = createFFmpeg(CreateFFmpegParam(log: false));
      ffmpeg.setLogger((LoggerParam logger) {
        logs.add('[${logger.type}] ${logger.message}');

        if (onProgress != null && logger.type == 'fferr') {
          final statistics = FFmpegStatistics.fromMessage(logger.message);
          if (statistics != null) {
            final progress = totalVideoDurationMs <= 0
                ? 0.0
                : statistics.time / totalVideoDurationMs;
            onProgress(statistics, progress);
          }
        }
      });

      await ffmpeg.load();

      ffmpeg.writeFile(inputPath, inputData);
      await ffmpeg.runCommand(execute);

      final data = ffmpeg.readFile(outputPath);
      return XFile.fromData(data, mimeType: outputMimeType);
    } catch (e, s) {
      Error.throwWithStackTrace(
        Exception('Exception:\n$e\n\nLogs:${logs.join('\n')}}'),
        s,
      );
    } finally {
      ffmpeg?.exit();
    }
  }

  Future<String> ioOutputPath(String filePath, FileFormat format) async {
    final tempPath = (await getTemporaryDirectory()).path;
    final name = path.basenameWithoutExtension(filePath);
    final epoch = DateTime.now().millisecondsSinceEpoch;
    return "$tempPath/${name}_$epoch.${format.extension}";
  }

  String _webPath(String prePath, FileFormat format) {
    final epoch = DateTime.now().millisecondsSinceEpoch;
    return '${prePath}_$epoch.${format.extension}';
  }

  String webInputPath(FileFormat format) => _webPath('input', format);

  String webOutputPath(FileFormat format) => _webPath('output', format);

  Future<XFile> exportVideo({
    void Function(FFmpegStatistics, double)? onProgress,
    VideoExportFormat outputFormat = VideoExportFormat.mp4,
    double scale = 1.0,
    String customInstruction = '',
    VideoExportPreset preset = VideoExportPreset.none,
    bool isFiltersEnabled = true,
  }) async {
    final inputPath = kIsWeb
        ? webInputPath(FileFormat.fromMimeType(_controller.file.mimeType))
        : _controller.file.path;
    final outputPath = kIsWeb
        ? webOutputPath(outputFormat)
        : await ioOutputPath(inputPath, outputFormat);

    final config = _controller.createVideoFFmpegConfig();
    final execute = config.createExportCommand(
      inputPath: inputPath,
      outputPath: outputPath,
      outputFormat: outputFormat,
      scale: scale,
      customInstruction: customInstruction,
      preset: preset,
      isFiltersEnabled: isFiltersEnabled,
    );

    debugPrint('run export video command : [$execute]');

    if (kIsWeb) {
      return executeFFmpegWeb(
        execute: execute,
        inputData: await _controller.file.readAsBytes(),
        inputPath: inputPath,
        outputPath: outputPath,
        outputMimeType: outputFormat.mimeType,
        totalVideoDurationMs: _controller.trimmedDuration.inMilliseconds,
        onProgress: onProgress,
      );
    } else {
      return executeFFmpegIO(
        execute: execute,
        outputPath: outputPath,
        totalVideoDurationMs: _controller.trimmedDuration.inMilliseconds,
        onProgress: onProgress,
      );
    }
  }

  Future<XFile> extractCover({
    void Function(Statistics)? onProgress,
    CoverExportFormat outputFormat = CoverExportFormat.jpg,
    double scale = 1.0,
    int quality = 100,
    bool isFiltersEnabled = true,
  }) async {
    // file generated from the thumbnail library or video source
    final coverFile = await VideoThumbnail.thumbnailFile(
      imageFormat: ImageFormat.JPEG,
      thumbnailPath: kIsWeb ? null : (await getTemporaryDirectory()).path,
      video: _controller.file.path,
      timeMs: _controller.selectedCoverVal?.timeMs ??
          _controller.startTrim.inMilliseconds,
      quality: quality,
    );

    final inputPath = kIsWeb
        ? webInputPath(FileFormat.fromMimeType(_controller.file.mimeType))
        : coverFile.path;
    final outputPath = kIsWeb
        ? webOutputPath(outputFormat)
        : await ioOutputPath(coverFile.path, outputFormat);

    var config = _controller.createCoverFFmpegConfig();
    final execute = config.createCoverExportCommand(
      inputPath: inputPath,
      outputPath: outputPath,
      scale: scale,
      quality: quality,
      isFiltersEnabled: isFiltersEnabled,
    );

    debugPrint('VideoEditor - run export cover command : [$execute]');

    if (kIsWeb) {
      return executeFFmpegWeb(
        execute: execute,
        inputData: await _controller.file.readAsBytes(),
        inputPath: inputPath,
        outputPath: outputPath,
        outputMimeType: outputFormat.mimeType,
        totalVideoDurationMs: 0,
        onProgress: null,
      );
    } else {
      return executeFFmpegIO(
        execute: execute,
        outputPath: outputPath,
        totalVideoDurationMs: 0,
        onProgress: null,
      );
    }
  }
}

class FFmpegStatistics {
  final int videoFrameNumber;
  final double videoFps;
  final double videoQuality;
  final int size;
  final int time;
  final double bitrate;
  final double speed;

  static final statisticsRegex = RegExp(
    r'frame\s*=\s*(\d+)\s+fps\s*=\s*(\d+(?:\.\d+)?)\s+q\s*=\s*([\d.-]+)\s+L?size\s*=\s*(\d+)\w*\s+time\s*=\s*([\d:.]+)\s+bitrate\s*=\s*([\d.]+)\s*(\w+)/s\s+speed\s*=\s*([\d.]+)x',
  );

  const FFmpegStatistics({
    required this.videoFrameNumber,
    required this.videoFps,
    required this.videoQuality,
    required this.size,
    required this.time,
    required this.bitrate,
    required this.speed,
  });

  FFmpegStatistics.fromStatistics(Statistics s)
      : this(
          videoFrameNumber: s.getVideoFrameNumber(),
          videoFps: s.getVideoFps(),
          videoQuality: s.getVideoQuality(),
          size: s.getSize(),
          time: s.getTime(),
          bitrate: s.getBitrate(),
          speed: s.getSpeed(),
        );

  static FFmpegStatistics? fromMessage(String message) {
    final match = statisticsRegex.firstMatch(message);
    if (match != null) {
      try {
        return FFmpegStatistics(
          videoFrameNumber: int.parse(match.group(1)!),
          videoFps: double.parse(match.group(2)!),
          videoQuality: double.parse(match.group(3)!),
          size: int.parse(match.group(4)!),
          time: timeToMs(match.group(5)!),
          bitrate: double.parse(match.group(6)!),
          // final bitrateUnit = match.group(7);
          speed: double.parse(match.group(8)!),
        );
      } catch (e) {
        debugPrint(e.toString());
      }
    }

    return null;
  }

  static int timeToMs(String timeString) {
    final parts = timeString.split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    final secondsParts = parts[2].split('.');
    final seconds = int.parse(secondsParts[0]);
    final milliseconds = int.parse(secondsParts[1]);
    return ((hours * 60 * 60 + minutes * 60 + seconds) * 1000 + milliseconds);
  }
}
