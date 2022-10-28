import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor/domain/helpers.dart';

void main() {
  group('computeSizeWithRatio', () {
    const layoutHorizontal = Size(1280, 720);
    const layoutVertical = Size(720, 1280);
    const layoutSquare = Size(720, 720);

    test('16:9', () {
      expect(computeSizeWithRatio(layoutHorizontal, 16/9), const Size(1280,720));
      expect(computeSizeWithRatio(layoutVertical, 16/9), const Size(720,405));
      expect(computeSizeWithRatio(layoutSquare, 16/9), const Size(720,405));
    });

     test('9:16', () {
      expect(computeSizeWithRatio(layoutHorizontal, 9/16), const Size(405,720));
      expect(computeSizeWithRatio(layoutVertical, 9/16), const Size(720,1280));
      expect(computeSizeWithRatio(layoutSquare, 9/16), const Size(405,720));
    });

    test('1:1', () {
      expect(computeSizeWithRatio(layoutHorizontal, 1), const Size(720,720));
      expect(computeSizeWithRatio(layoutVertical, 1), const Size(720,720));
      expect(computeSizeWithRatio(layoutSquare, 1), const Size(720,720));
    });

    test('4:3', () {
      expect(computeSizeWithRatio(layoutHorizontal, 4/3), const Size(960,720));
      expect(computeSizeWithRatio(layoutVertical, 4/3), const Size(720,540));
      expect(computeSizeWithRatio(layoutSquare, 4/3), const Size(720,540));
    });

    test('3:4', () {
      expect(computeSizeWithRatio(layoutHorizontal, 3/4), const Size(540,720));
      expect(computeSizeWithRatio(layoutVertical, 3/4), const Size(720,960));
      expect(computeSizeWithRatio(layoutSquare, 3/4), const Size(540,720));
    });
  });
}
