# Flutter video editor

[![Platform](https://img.shields.io/badge/Platform-Flutter-yellow.svg)](https://flutter.io)
[![Pub](https://img.shields.io/pub/v/video_editor.svg?logo=flutter&color=blue&style=flat-square)](https://pub.dev/packages/video_editor)

A video editor that allows to edit (trim, crop, rotate and scale) and choose a cover with a very flexible UI design.
The changes are then exported with `ffmpeg`.

## Installation


Following steps will help you add this library as a dependency in your flutter project.

- In the `pubspec.yaml` file in the root of your project

```yaml
dependencies:
  video_editor: ^1.2.5
```

- Run the following command to install the package:

```bash
$ flutter packages get
```

- Import the package in your project file:

```dart
import 'package:video_editor/video_editor.dart';
```

Since `1.3.0` video_editor uses ffmpeg_kit_flutter main release which supports the latest features. (More info on [flutter FFmepeg kit](https://github.com/tanersener/ffmpeg-kit/tree/main/flutter/flutter))

Those Android API level and iOS deployment target are required to uses this package. If you're planing to target older devices, check about the [LTS release](#1-how-to-use-ffmpeg-lts-release).

<table>
<thead>
<tr>
<th align="center">Android<br>API Level</th>
<th align="center">iOS Minimum<br>Deployment Target</th>
</tr>
</thead>
<tbody>
<tr>
<td align="center">24</td>
<td align="center">12.1</td>
</tr>
</tbody>
</table>

## **Screenshots** (The UI Design is fully customizable on the [example](https://pub.dev/packages/video_editor/example))

| Crop Video                          | Rotate Video                          | Video cover (selection, viewer)       |
| ----------------------------------- | ------------------------------------- | ------------------------------------- |
| ![](./assets/readme/crop_video.gif) | ![](./assets/readme/rotate_video.gif) | ![](./assets/readme/cover_viewer.gif) |

| Trim video                              | Trimmer customization                       |
| --------------------------------------- |  ------------------------------------------ |
| ![](./assets/readme/new_trim_video.gif) | ![](./assets/readme/new_trimmer_icons.gif)  |

## FAQ

### 1. How to use FFmpeg LTS release

Since `1.3.0` video_editor uses ffmpeg_kit_flutter main release which supports the latest features. If you want to support a wider range of devices you should use the LTS release. [more info](https://github.com/tanersener/ffmpeg-kit#10-lts-releases)


To do this, add this to your `pubspec.yaml`:
```yaml
dependency_overrides:
  ffmpeg_kit_flutter_min_gpl: ^4.5.1-LTS
```

## Main Contributors

<table>
  <tr>
    <td align="center"><a href="https://github.com/LeGoffMael"><img src="https://avatars.githubusercontent.com/u/22376981?v=4?s=200" width="200px;" alt=""/><br/><sub><b>Le Goff Maël</b></sub></a></td>
  </tr>
</table>
<br/>
