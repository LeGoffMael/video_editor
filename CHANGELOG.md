## 3.0.0

> **Note**
> If you continue to use the previous versions (from 1.2.3 to 2.4.0) your project might be subject to a GPL license.

- Removed dependency to FFmpeg from this package ([reasons](https://github.com/LeGoffMael/video_editor#1-why-was-ffmpeg-removed-from-this-package-))

Before:

```dart
// Basic export video function
Future<void> exportVideo() => _controller.exportVideo(
  onCompleted: (file) {}, // show the exported video
);
```

After:
```dart
/// Basic export video function
Future<void> exportVideo() async {
  // You could generate your command line yourself or if you want to continue to use FFmpeg : 
  final config = VideoFFmpegVideoEditorConfig(_controller);
  // Returns the generated command and the output path
  final FFmpegVideoEditorExecute execute = await config.getExecuteConfig();

  // ... handle the video exportation yourself, using ffmpeg_kit_flutter, your own video server, ... (more example in the example app)
}
```

- New complete control over the command generation using `commandBuilder` in `VideoFFmpegVideoEditorConfig`
  - Removed `VideoExportPreset`, you can specifies it using the `commandBuilder`.
  - Removed `customInstruction`, you can now custom the command using the `commandBuilder`.
- The exportation is now very fast if there is no filter [#140](https://github.com/LeGoffMael/video_editor/issues/140)
- Fix assert error while triming [#157](https://github.com/LeGoffMael/video_editor/issues/157)
- New `coverThumbnailsQuality` and `trimThumbnailsQuality` in controller
  - Removed `quality` in `CoverSelection`, instead uses `coverThumbnailsQuality`
  - Removed `quality` in `ThumbnailSlider`, instead uses `trimThumbnailsQuality`
  - Removed `quality` in `TrimSlider`, instead uses `trimThumbnailsQuality`

## 2.4.0

- Fix update TrimSlider trim values from controller [#141](https://github.com/LeGoffMael/video_editor/pull/141)
- Add `scrollController` param in TrimSlider [#139](https://github.com/LeGoffMael/video_editor/pull/139) by [@jcsena](https://github.com/jcsena)

- Some controller's methods name has been changed :

### Breaking changes

- `updateCrop()` method is now renamed `applyCacheCrop()`.
- Setters `minTrim`, `maxTrim`, `minCrop` & `maxCrop` has been removed.<br>Prefer using `updateTrim(min, max)` and the new `updateCrop(min, max)` methods instead.

## 2.3.0

- fixes GIF file exportation [#134](https://github.com/LeGoffMael/video_editor/pull/134)

### Breaking changes

- `format` argument in `exportVideo` and `exportCover`, is now an object.

Before:

```dart
await controller.exportVideo(format: 'mp4', onCompleted: (_) {});
await controller.extractCover(format: 'jpg', onCompleted: (_) {});
```

After:
```dart
await controller.exportVideo(
  format: VideoExportFormat.mp4, // or const VideoExportFormat('mp4')
  onCompleted: (_) {}.
);

await controller.extractCover(
  format: CoverExportFormat.jpg, // or const CoverExportFormat('jpg')
  onCompleted: (_) {}.
);
```

## 2.2.0

- improved widgets performances [#130](https://github.com/LeGoffMael/video_editor/pull/130) & [#132](https://github.com/LeGoffMael/video_editor/pull/132)
- improve crop preview internal logic by using mixin [#131](https://github.com/LeGoffMael/video_editor/pull/131)
- new `rotateCropArea` parameter in `CropGridViewer.edit` [#130](https://github.com/LeGoffMael/video_editor/pull/130)

## 2.1.0

- Trim values are now more accurate for exportation [#127](https://github.com/LeGoffMael/video_editor/pull/127)
- New `minDuration` argument in controller [#126](https://github.com/LeGoffMael/video_editor/pull/126)
  - Timeline shows milliseconds
- Crop values are now more accurate for exportation [#125](https://github.com/LeGoffMael/video_editor/pull/125)
  - Fix issue were crop were not applied on export
  - New `trimmedDuration` getter

## 2.0.0

- New trimmer gesture [#124](https://github.com/LeGoffMael/video_editor/pull/124)
- New animation during rotation [#123](https://github.com/LeGoffMael/video_editor/pull/123)
- Better trimmer [#122](https://github.com/LeGoffMael/video_editor/pull/122)
- Better crop boundaries touch detection [#121](https://github.com/LeGoffMael/video_editor/pull/121)
- New style parameters
- New thumbnails fadein animation at generation
- Video cursor position updated better while trimming
- Fix scale issue in thumbnails

Check [migration guide](https://github.com/LeGoffMael/video_editor/wiki/Migration-to-2.0.0).

## 1.5.2

- Fix scale issue when video is rotated

## 1.5.1

- New `aspectRatio` param in initialize function, to set up the crop param without opening the crop view
- Fix some crop resize issue with ratio
- Fix scale issue

## 1.5.0

- Upgrade `flutter_ffmpeg_kit` to latest 5.1.0

## 1.4.4

- Fix export error when space in output path [#108](https://github.com/LeGoffMael/video_editor/pull/108) by [@martingeorgiu](https://github.com/martingeorgiu)
- Bump `video_thumbnail` dependencies to 0.5.3 so upgrade android compileSdkVersion to 33

## 1.4.3

- New `onError` param in export functions [#98](https://github.com/LeGoffMael/video_editor/pull/98)
- New selectedIndicator param in `CoverSelectionStyle` [#97](https://github.com/LeGoffMael/video_editor/pull/97)
- Update dependencies

## 1.4.2

- Update to flutter 3 [#91](https://github.com/LeGoffMael/video_editor/pull/91)

## 1.4.1

- Generated thumbnails list is not cleared after an exception [#88](https://github.com/LeGoffMael/video_editor/pull/88)

## 1.4.0

- Fix crop grid : gesture, aspect ratio, and painting area [#87](https://github.com/LeGoffMael/video_editor/pull/87)
- [MAJOR INTERNAL CROP CHANGES]
  - The aspect ratio is resizing the crop area differently depending of the current crop ratio
  - The crop rect is updated using `Rect.LTRB`
  - The crop area gesture is detected differently
  - The crop paint area is diplayed using `Path.combine`

## 1.3.1

- Implements flutter_lints configuration [#86](https://github.com/LeGoffMael/video_editor/issues/86)
- [NEW] Exportation progress value is returned in `onProgress` function of exportVideo [#85](https://github.com/LeGoffMael/video_editor/issues/85)

## 1.3.0

- [BREAKING CHANGE]
    - In TrimTimeline, `secondGap` param is no more nullable
    - In TrimSliderStyle, positionlineWidth param is renamed `positionLineWidth`
    - In CoverSelection, nbSelection param is renamed `quantity`
- Improve package documentation [#84](https://github.com/LeGoffMael/video_editor/issues/84)
- Switch from LTS FFmpeg package to Main release [#81](https://github.com/LeGoffMael/video_editor/issues/81) by [@adigladi](https://github.com/adigladi)

## 1.2.5

- Upgraded `video_thumbnail` dependency
- Fix dependency conflict with `path 1.8.1` [#79](https://github.com/LeGoffMael/video_editor/issues/79)

## 1.2.4

- Updated dependencies
- Add `isFiltersEnabled` param to disable all changes at extraction [#76](https://github.com/LeGoffMael/video_editor/pull/76) by [@AlexSmirnov9107](https://github.com/AlexSmirnov9107)
- Fix an error at extraction if the destination path contains a space [#74](https://github.com/LeGoffMael/video_editor/pull/74) by [@rgplvr](https://github.com/rgplvr)

## 1.2.3

- Update `ffmpeg_kit_flutter` to latest 4.5.1 [#65](https://github.com/LeGoffMael/video_editor/pull/65)
- Print ffmpeg session state, return code and fail stack trace if exists [#63](https://github.com/LeGoffMael/video_editor/pull/63)
- New function to get metadata of video file [#57](https://github.com/LeGoffMael/video_editor/pull/57)
- Update `README.md` about `ffmpeg_kit_flutter` configuration [#53](https://github.com/LeGoffMael/video_editor/pull/53) by [@qiongshusheng](https://github.com/qiongshusheng)

## 1.2.2

[@legoffmael](https://github.com/LeGoffMael) changes

- Error MissingPluginException with video_thumbnail fixed [#49](https://github.com/LeGoffMael/video_editor/pull/49)
- Add epoch to exportation names by default [#50](https://github.com/LeGoffMael/video_editor/pull/50)

## 1.2.1

[@legoffmael](https://github.com/LeGoffMael) changes

- Added icons customization in trimmer style [#45](https://github.com/LeGoffMael/video_editor/pull/45)
- Improved cover exportation + apply cover quality in thumbnail [#46](https://github.com/LeGoffMael/video_editor/pull/46)
- Fix exportation directory issues + add exportation parameters (cover format and exportation directory) [#47](https://github.com/LeGoffMael/video_editor/pull/47)
- Change how video dimensions are computed + update example and libraries [#48](https://github.com/LeGoffMael/video_editor/pull/48)

[FELIPE MURGUIA](https://github.com/seel-channel) changes

- Migrated to FFMPEG KIT xd

## 1.2.0

[@legoffmael](https://github.com/LeGoffMael) changes

- Portrait scale's bugs fixed [#32](https://github.com/LeGoffMael/video_editor/pull/32)
- Video export's bugs fixed [#31](https://github.com/LeGoffMael/video_editor/pull/31)
- Crop's bugs fixed [#30](https://github.com/LeGoffMael/video_editor/pull/30)
- Export video cover [#29](https://github.com/LeGoffMael/video_editor/pull/29)
- Trim slider timeline [#28](https://github.com/LeGoffMael/video_editor/pull/28)
- New smooth trimmer when video durarion > maxDuration [#27](https://github.com/LeGoffMael/video_editor/pull/27)


## 1.1.0

- Sound Null Safety Migration [#21](https://github.com/LeGoffMael/video_editor/pull/21) by [@paricleu](https://github.com/paricleu)
- Preffered Aspect Ratio on crop
- Improved gesture on crop screen

## 1.0.3+1

- [UNIDENTIFIED] ERROR FIXED.

## 1.0.3

- Progress bar on export
- Improved export function

## 1.0.2

- Improved cropping gestures
- TrimSlider bugs fixed

## 1.0.1

- Export Video:

  - VideoExportPreset
  - customFFMPEGInstruction

- Trim Slider:
  - Load faster thumbnails
  - MaxTrimDuration
  - Bugs Fixed

## 1.0.0+1

- Export error fixed.

## 1.0.0

- Initial Release.
