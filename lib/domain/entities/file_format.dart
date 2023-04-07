abstract class FileFormat {
  const FileFormat(this.extension, {required this.mimeType});

  /// Extension of the file without the dot `.`.
  final String extension;

  /// The MIME type of the file format.
  final String mimeType;

  factory FileFormat.fromMimeType(String? mimeType) {
    switch (mimeType) {
      case 'image/jpeg':
        return CoverExportFormat.jpg;
      case 'image/png':
        return CoverExportFormat.png;
      case 'image/webp':
        return CoverExportFormat.webp;
      case 'video/mp4':
        return VideoExportFormat.mp4;
      case 'video/quicktime':
        return VideoExportFormat.mov;
      case 'video/x-msvideo':
        return VideoExportFormat.avi;
      case 'image/gif':
        return const GifExportFormat();
      default:
        return const UnknownFileFormat();
    }
  }
}

/// Specify the file format to use when exporting the video
/// some common formats such as `avi`, `gif`, `mov` and `mp4` has a default constructor.
///
/// If you need another file format you can specify it like
/// ```dart
/// VideoExportFormat('mkv');
/// ```
class VideoExportFormat extends FileFormat {
  const VideoExportFormat(String extension, {required String mimeType})
      : super(extension, mimeType: mimeType);

  static const avi = VideoExportFormat('avi', mimeType: 'video/x-msvideo');
  static const gif = GifExportFormat();
  static const mov = VideoExportFormat('mov', mimeType: 'video/quicktime');
  static const mp4 = VideoExportFormat('mp4', mimeType: 'video/mp4');
}

/// To export the video as a GIF file
/// You can use this class to custom the [fps] of the exported GIF file.
class GifExportFormat extends VideoExportFormat {
  const GifExportFormat({this.fps = 10}) : super('gif', mimeType: 'image/gif');

  /// The frame rate of the GIF file.
  ///
  /// Defaults to `10`.
  final int fps;
}

/// Specify the file format to use when exporting the video cover
/// some common formats such as `jpg`, `png` and `webp` has a default constructor.
///
/// If you need another file format you can specify it like
/// ```dart
/// CoverExportFormat('jpeg');
/// ```
class CoverExportFormat extends FileFormat {
  const CoverExportFormat(String extension, {required String mimeType})
      : super(extension, mimeType: mimeType);

  static const jpg = CoverExportFormat('jpg', mimeType: 'image/jpeg');
  static const png = CoverExportFormat('png', mimeType: 'image/png');
  static const webp = CoverExportFormat('webp', mimeType: 'image/webp');
}

class UnknownFileFormat extends FileFormat {
  const UnknownFileFormat() : super('', mimeType: 'application/octet-stream');
}
