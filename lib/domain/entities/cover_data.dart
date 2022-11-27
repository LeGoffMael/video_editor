import 'dart:typed_data';

class CoverData {
  const CoverData({
    this.thumbData,
    required this.timeMs,
  });
  final Uint8List? thumbData;
  final int timeMs;

  bool sameTime(CoverData cover2) => timeMs == cover2.timeMs;
}
