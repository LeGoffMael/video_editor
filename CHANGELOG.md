## [1.2.5]

- Upgraded `video_thumbnail` dependency
- Fix dependency conflict with `path 1.8.1` [#79](https://github.com/seel-channel/video_editor/issues/79)

## [1.2.4]

- Updated dependencies
- Add `isFiltersEnabled` param to disable all changes at extraction [#76](https://github.com/seel-channel/video_editor/pull/76)
- Fix an error at extraction if the destination path contains a space [#74](https://github.com/seel-channel/video_editor/pull/74)

## [1.2.3]

- Update `ffmpeg_kit_flutter` to latest 4.5.1 [#65](https://github.com/seel-channel/video_editor/pull/65)
- Print ffmpeg session state, return code and fail stack trace if exists [#63](https://github.com/seel-channel/video_editor/pull/63)
- New function to get metadata of video file [#57](https://github.com/seel-channel/video_editor/pull/57)
- Update `README.md` about `ffmpeg_kit_flutter` configuration [#53](https://github.com/seel-channel/video_editor/pull/53) by [@qiongshusheng](https://github.com/qiongshusheng)

## [1.2.2]

MAËL LE GOFF changes

- Error MissingPluginException with video_thumbnail fixed [#49](https://github.com/seel-channel/video_editor/pull/49)
- Add epoch to exportation names by default [#50](https://github.com/seel-channel/video_editor/pull/50)

## [1.2.1]

MAËL LE GOFF changes

- Added icons customization in trimmer style [#45](https://github.com/seel-channel/video_editor/pull/45)
- Improved cover exportation + apply cover quality in thumbnail [#46](https://github.com/seel-channel/video_editor/pull/46)
- Fix exportation directory issues + add exportation parameters (cover format and exportation directory) [#47](https://github.com/seel-channel/video_editor/pull/47)
- Change how video dimensions are computed + update example and libraries [#48](https://github.com/seel-channel/video_editor/pull/48)

FELIPE MURGUIA changes

- Migrated to FFMPEG KIT xd

## [1.2.0]

MAËL LE GOFF changes

- Trim slider timeline
- New smooth trimmer when video durarion > maxDuration
- Export video cover
- Crop's bugs fixed
- Video export's bugs fixed
- Portrait scale's bugs fixed

## [1.1.0]

- Sound Null Safety Migration
- Preffered Aspect Ratio on crop
- Improved gesture on crop screen

## [1.0.3+1]

- [UNIDENTIFIED] ERROR FIXED.

## [1.0.3]

- Progress bar on export
- Improved export function

## [1.0.2]

- Improved cropping gestures
- TrimSlider bugs fixed

## [1.0.1]

- Export Video:

  - VideoExportPreset
  - customFFMPEGInstruction

- Trim Slider:
  - Load faster thumbnails
  - MaxTrimDuration
  - Bugs Fixed

## [1.0.0+1]

- Export error fixed.

## [1.0.0]

- Initial Release.
