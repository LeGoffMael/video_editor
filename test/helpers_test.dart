import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor/src/utils/helpers.dart';

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

  group('resizeCropToRatio', () {
    const layoutHorizontal = Size(1280, 720);
    final layoutHorizontalCrop = Rect.fromLTWH(0, 0, layoutHorizontal.width, layoutHorizontal.height);
    const layoutVertical = Size(720, 1280);
    final layoutVerticalCrop = Rect.fromLTWH(0, 0, layoutVertical.width, layoutVertical.height);

    test('layoutHorizontal default', () {
      expect(resizeCropToRatio(layoutHorizontal, layoutHorizontalCrop, 16/9), layoutHorizontalCrop);
      expect(resizeCropToRatio(layoutHorizontal, layoutHorizontalCrop, 1/1), Rect.fromCenter(center: layoutHorizontalCrop.center, width: 720, height: 720));
      expect(resizeCropToRatio(layoutHorizontal, layoutHorizontalCrop, 9/16), Rect.fromCenter(center: layoutHorizontalCrop.center, width: 405, height: 720));
    });

    test('layoutHorizontal do not get smaller', () {
      // 16/9 -> 9/16
      final croppedOpposite = resizeCropToRatio(layoutHorizontal, layoutHorizontalCrop, 9/16);
      expect(croppedOpposite, Rect.fromCenter(center: layoutHorizontalCrop.center, width: 405, height: 720));

      // 9/16 -> 16/9
      final croppedBack = resizeCropToRatio(layoutHorizontal, croppedOpposite, 16/9);
      expect(croppedBack, Rect.fromCenter(center: croppedOpposite.center, width: 405, height: 227.8125));

      // 16/9 -> 1/1
      final croppedSquare = resizeCropToRatio(layoutHorizontal, croppedBack, 1/1);
      expect(croppedSquare, Rect.fromCenter(center: croppedBack.center, width: 405, height: 405));

      // 1/1 -> 9/16
      final croppedBackOpposite = resizeCropToRatio(layoutHorizontal, croppedSquare, 9/16);
      expect(croppedBackOpposite, Rect.fromCenter(center: croppedSquare.center, width: 405, height: 720));
    });

    test('layoutHorizontal do not go out of bounds', () {
      // top left
      expect(resizeCropToRatio(layoutHorizontal, const Rect.fromLTRB(0, 0, 405, 405), 9/16), const Rect.fromLTRB(0, 0, 405, 720));
      // top right
      expect(resizeCropToRatio(layoutHorizontal, Rect.fromLTRB(layoutHorizontal.width - 405, 0, layoutHorizontal.width, 405), 9/16), Rect.fromLTRB(layoutHorizontal.width - 405, 0, layoutHorizontal.width, 720));
      // bottom right
      expect(resizeCropToRatio(layoutHorizontal, Rect.fromLTRB(layoutHorizontal.width - 405, layoutHorizontal.height - 405, layoutHorizontal.width, layoutHorizontal.height), 9/16), Rect.fromLTRB(layoutHorizontal.width - 405, layoutHorizontal.height - 720, layoutHorizontal.width, layoutHorizontal.height));
      // bottom left
      expect(resizeCropToRatio(layoutHorizontal, Rect.fromLTRB(0, layoutHorizontal.height - 405, 405, layoutHorizontal.height), 9/16), Rect.fromLTRB(0, layoutHorizontal.height - 720, 405, layoutHorizontal.height));
    });

    test('layoutVertical default', () {
      expect(resizeCropToRatio(layoutVertical, layoutVerticalCrop, 9/16), layoutVerticalCrop);
      expect(resizeCropToRatio(layoutVertical, layoutVerticalCrop, 1/1), Rect.fromCenter(center: layoutVerticalCrop.center, width: 720, height: 720));
      expect(resizeCropToRatio(layoutVertical, layoutVerticalCrop, 16/9), Rect.fromCenter(center: layoutVerticalCrop.center, width: 720, height: 405));
    });

    test('layoutVertical do not get smaller', () {
      // 9/16 -> 1/1
      final croppedSquare = resizeCropToRatio(layoutVertical, layoutVerticalCrop, 1/1);
      expect(croppedSquare, Rect.fromCenter(center: layoutVerticalCrop.center, width: 720, height: 720));

      // 1/1 -> 9/16
      final croppedBack = resizeCropToRatio(layoutVertical, croppedSquare, 9/16);
      expect(croppedBack, layoutVerticalCrop);

      // 9/16 -> 16/9
      final croppedOpposite = resizeCropToRatio(layoutVertical, croppedBack, 16/9);
      expect(croppedOpposite, Rect.fromCenter(center: croppedBack.center, width: 720, height: 405));

      // 16/9 -> 1/1
      final croppedSquare2 = resizeCropToRatio(layoutVertical, croppedOpposite, 1/1);
      expect(croppedSquare2, Rect.fromCenter(center: croppedOpposite.center, width: 720, height: 720));
    });

    test('layoutVertical do not go out of bounds', () {
      // top left
      expect(resizeCropToRatio(layoutVertical, const Rect.fromLTRB(0, 0, 405, 405), 9/16), const Rect.fromLTRB(0, 0, 405, 720));
      // top right
      expect(resizeCropToRatio(layoutVertical, Rect.fromLTRB(layoutVertical.width - 405, 0, layoutVertical.width, 405), 9/16), Rect.fromLTRB(layoutVertical.width - 405, 0, layoutVertical.width, 720));
      // bottom right
      expect(resizeCropToRatio(layoutVertical, Rect.fromLTRB(layoutVertical.width - 405, layoutVertical.height - 405, layoutVertical.width, layoutVertical.height), 9/16), Rect.fromLTRB(layoutVertical.width - 405, layoutVertical.height - 720, layoutVertical.width, layoutVertical.height));
      // bottom left
      expect(resizeCropToRatio(layoutVertical, Rect.fromLTRB(0, layoutVertical.height - 405, 405, layoutVertical.height), 9/16), Rect.fromLTRB(0, layoutVertical.height - 720, 405, layoutVertical.height));
    });
  });

  group('translateRectIntoBounds', () {
    const layout = Size(450, 220);
    const double side = 20;
    final centerW = layout.width / 2;
    final centerH = layout.height / 2;

    test('center left', () => expect(translateRectIntoBounds(layout, Rect.fromLTRB(-side, centerH - side / 2, 0, centerH + side / 2)), Rect.fromLTRB(0, centerH - side / 2, side, centerH + side / 2)));
    test('center top', () => expect(translateRectIntoBounds(layout, Rect.fromLTRB(centerW - side / 2, -side, centerW + side /2, 0)), Rect.fromLTRB(centerW - side / 2, 0, centerW + side / 2, side)));
    test('center right', () => expect(translateRectIntoBounds(layout, Rect.fromLTRB(layout.width, centerH - side / 2, layout.width + side, centerH + side / 2)), Rect.fromLTRB(layout.width - side, centerH - side / 2, layout.width, centerH + side / 2)));
    test('center bottom', () => expect(translateRectIntoBounds(layout, Rect.fromLTRB(centerW - side / 2, layout.height, centerW + side / 2, layout.height + side)), Rect.fromLTRB(centerW - side / 2, layout.height - side, centerW + side / 2, layout.height)));

    test('left + top', () => expect(translateRectIntoBounds(layout, const Rect.fromLTRB(-side, -side, 0, 0)), const Rect.fromLTRB(0, 0, side, side)));
    test('right + top', () => expect(translateRectIntoBounds(layout, Rect.fromLTRB(layout.width, -side, layout.width + side, 0)), Rect.fromLTRB(layout.width - side, 0, layout.width, side)));
    test('left + bottom', () => expect(translateRectIntoBounds(layout, Rect.fromLTRB(-side, layout.height, 0, layout.height + side)), Rect.fromLTRB(0, layout.height - side, side, layout.height)));
    test('right + bottom', () => expect(translateRectIntoBounds(layout, Rect.fromLTRB(layout.width, layout.height, layout.width + side, layout.height + side)), Rect.fromLTRB(layout.width - side, layout.height - side, layout.width, layout.height)));
  });

  group('scaleToSize', () {
    const maxSize = Size(375.0, 464.0);

    test('centered 16/9 rect (equals to layout)', () => expect(scaleToSize(maxSize, const Rect.fromLTRB(0.0, 0.0, 375.0, 210.9)), 1));
    test('centered small 16/9 rect', () => expect(scaleToSize(maxSize, const Rect.fromLTRB(51.4, 28.6, 314.7, 176.7)), maxSize.width / 263.3));
    test('centered 9/16 rect', () => expect(scaleToSize(maxSize, const Rect.fromLTRB(128.2, 0.0, 246.8, 210.9)), maxSize.height / 210.9));
    test('centered 1/1 rect', () => expect(scaleToSize(maxSize, const Rect.fromLTRB(51.4, 28.6, 314.7, 176.7)), maxSize.width / 263.3));
  });

  group('getBestIndex', () {
    test('max=4, length=11', () {
      expect(getBestIndex(4, 11, 0), 1);
      expect(getBestIndex(4, 11, 1), 4);
      expect(getBestIndex(4, 11, 2), 7);
      expect(getBestIndex(4, 11, 3), 9);
    });

    test('max=10, length=20', () {
      expect(getBestIndex(10, 20, 0), 1);
      expect(getBestIndex(10, 20, 1), 3);
      expect(getBestIndex(10, 20, 2), 5);
      expect(getBestIndex(10, 20, 3), 7);
      expect(getBestIndex(10, 20, 4), 9);
      expect(getBestIndex(10, 20, 5), 11);
      expect(getBestIndex(10, 20, 6), 13);
      expect(getBestIndex(10, 20, 7), 15);
      expect(getBestIndex(10, 20, 8), 17);
      expect(getBestIndex(10, 20, 9), 19);
    });

    test('max=120, length=213', () {
      expect(getBestIndex(120, 213, 0), 1);
      expect(getBestIndex(120, 213, 19), 35);
      expect(getBestIndex(120, 213, 39), 70);
      expect(getBestIndex(120, 213, 59), 106);
      expect(getBestIndex(120, 213, 79), 141);
      expect(getBestIndex(120, 213, 99), 177);
      expect(getBestIndex(120, 213, 119), 212);
    });
  });

  group('getOppositeRatio', () {
    test('ratio=1', () => expect(getOppositeRatio(1), 1));
    test('ratio=9/16', () => expect(getOppositeRatio(9 / 16), 16 / 9));
    test('ratio=16/9', () => expect(getOppositeRatio(16 / 9), 9 / 16));
    test('ratio=3/4', () => expect(getOppositeRatio(3 / 4), 4 / 3));
    test('ratio=4/3', () => expect(getOppositeRatio(4 / 3), 3 / 4));
    test('ratio=4/5', () => expect(getOppositeRatio(4 / 5), 5 / 4));
    test('ratio=4/5', () => expect(getOppositeRatio(5 / 4), 4 / 5));
  });
}
