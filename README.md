# Flutter video editor

[![Platform](https://img.shields.io/badge/Platform-Flutter-yellow.svg)](https://flutter.io)
[![Pub](https://img.shields.io/pub/v/video_editor.svg?logo=flutter&color=blue&style=flat-square)](https://pub.dev/packages/video_editor)

A video editor that allows to edit (trim, crop, rotate and scale) and choose a cover with a very flexible UI design.
The changes are then exported with `ffmpeg`.

### My other APIs

- [Scroll Navigation](https://pub.dev/packages/scroll_navigation)
- [Video Viewer](https://pub.dev/packages/video_viewer)
- [Helpers](https://pub.dev/packages/helpers)

## **Installation** (More info on [Flutter ffmepeg kit](https://github.com/tanersener/ffmpeg-kit/tree/main/flutter/flutter))
Following steps will help you add this library as a dependency in your flutter project.

- In the `pubspec.yaml` file in the root of your project

```yaml
dependencies:
  video_editor: ^1.2.3
```

- Run the following command to install the package:

```bash
$ flutter packages get
```

- Import the package in your project file:

```dart
import 'package:video_editor/video_editor.dart';
```

## **Screenshots** (The UI Design is fully customizable on the [example](https://pub.dev/packages/video_editor/example))

| Crop Video                          | Rotate Video                          |
| ----------------------------------- | ------------------------------------- |
| ![](./assets/readme/crop_video.gif) | ![](./assets/readme/rotate_video.gif) |

| Trim Video                          | Export Video                          |
| ----------------------------------- | ------------------------------------- |
| ![](./assets/readme/trim_video.gif) | ![](./assets/readme/export_video.gif) |

| Trimmer if maxDuration < videoDuration  | Trim timeline                           | Trim icons customization                    |
| --------------------------------------- |  -------------------------------------- |  ------------------------------------------ |
| ![](./assets/readme/new_trim_video.gif) | ![](./assets/readme/trim_timeline.gif)  | ![](./assets/readme/new_trimmer_icons.gif)  |

| Video cover (selection, viewer)       | Export cover                          |
| ------------------------------------- | ------------------------------------- |
| ![](./assets/readme/cover_viewer.gif) | ![](./assets/readme/export_cover.gif) |

## Main Contributors

<table>
  <tr>
    <td align="center"><a href="https://github.com/LeGoffMael"><img src="https://avatars.githubusercontent.com/u/22376981?v=4?s=200" width="200px;" alt=""/><br/><sub><b>Le Goff Maël</b></sub></a></td>
  </tr>
</table>
<br/>
