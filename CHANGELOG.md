## [1.4.4]

- Massive upgrades without breaking changes.
- 2 New functions extractCoverWithFuture and exportVideoWithFuture both functions will do same task as default export functions but they will behave like Future. Their return type is Future<File?> and they does not have onCompleted callback. To avoid nests of callback users who want to use future version they can use these functions as well.
Updated example on how to use them.
- New capDimension parameter in export functions in which user can limit the max dimension without losing video aspect ratio.

- Now user will have more control over output video
cappedVideoBitRate nullable parameter (pass 128000 for 128kbps)- will cap the max bitrate of output video
cappedAudioBitRate nullable parameter (pass 1500000 for 1.5Mbps) - will cap the max bitrate of output audio
cappedOutputVideoSize nullable parameter - Advanced feature when passed a size in bytes will limit the output file size.
- cappedOutputVideoSize working
    - case 1: If cappedOutputVideoSize is not passed _maxDuration parameter value will limit the trim.
    - case 2: cappedOutputVideoSize is passed , for example 16MB like whatsapp
      - Step 1: Now on-initialize ffprobe will get the metadata of video to fetch current bitrates.
      - Step 2: updateMaxDuration function will calculate the max duration a user can select which falls below the cappedOutputVideoSize size.
        - example 1: A low bitrate file of 16Mb can be of 2-3 minutes or more , trim slider will be adjusted to that max value.
        - example 2: A high bitrate file whose maxduration was sepcified to be 60 seconds.
          - case 1: cappedVideoBitRate and cappedAudioBitRate are present
            - trimslider will be adjusted according to the cappedVideoBitRate and cappedAudioBitRate.
          - case 2: cappedVideoBitRate and cappedAudioBitRate are absent
            - trimslider will be adjusted accroding to the maximum duration that can be attained which falls below cappedOutputVideoSize.

- Mute audio functionality given through a value notifier and ffmpeg command is adjusted according to that.

- Output size prediction value notifier is introduced to predict the output size through bitrates and trimmed duration . variable name estimatedOutputSize.
It can be used with Value listenable builder to show size like whatsapp does. Updated example that shows the filesize and the trimmed duration.

- Introduced Trimmed duration (trimmedDuration) value notitifer to show the duration as user uses trim. Updated example to show that duration.

- croppedDimensions variable will always have latest value which can be used by user to show or operate on. Initially those dimension will be of video size but then as video crop is applied it will have latest dimensions which will be applied on output.

- Added screenshots for new updated exmaple




## [1.4.3]

- New `onError` param in export functions [#98](https://github.com/seel-channel/video_editor/pull/98)
- New selectedIndicator param in `CoverSelectionStyle` [#97](https://github.com/seel-channel/video_editor/pull/97)
- Update dependencies

## [1.4.2]

- Update to flutter 3 [#91](https://github.com/seel-channel/video_editor/pull/91)

## [1.4.1]

- Generated thumbnails list is not cleared after an exception [#88](https://github.com/seel-channel/video_editor/pull/88)

## [1.4.0]

- Fix crop grid : gesture, aspect ratio, and painting area [#87](https://github.com/seel-channel/video_editor/pull/87)
- [MAJOR INTERNAL CROP CHANGES]
  - The aspect ratio is resizing the crop area differently depending of the current crop ratio
  - The crop rect is updated using `Rect.LTRB`
  - The crop area gesture is detected differently
  - The crop paint area is diplayed using `Path.combine`

## [1.3.1]

- Implements flutter_lints configuration [#86](https://github.com/seel-channel/video_editor/issues/86)
- [NEW] Exportation progress value is returned in `onProgress` function of exportVideo [#85](https://github.com/seel-channel/video_editor/issues/85)

## [1.3.0]

- [BREAKING CHANGE]
    - In TrimTimeline, `secondGap` param is no more nullable
    - In TrimSliderStyle, positionlineWidth param is renamed `positionLineWidth`
    - In CoverSelection, nbSelection param is renamed `quantity`
- Improve package documentation [#84](https://github.com/seel-channel/video_editor/issues/84)
- Switch from LTS FFmpeg package to Main release [#81](https://github.com/seel-channel/video_editor/issues/81) by [@adigladi](https://github.com/adigladi)

## [1.2.5]

- Upgraded `video_thumbnail` dependency
- Fix dependency conflict with `path 1.8.1` [#79](https://github.com/seel-channel/video_editor/issues/79)

## [1.2.4]

- Updated dependencies
- Add `isFiltersEnabled` param to disable all changes at extraction [#76](https://github.com/seel-channel/video_editor/pull/76) by [@AlexSmirnov9107](https://github.com/AlexSmirnov9107)
- Fix an error at extraction if the destination path contains a space [#74](https://github.com/seel-channel/video_editor/pull/74) by [@rgplvr](https://github.com/rgplvr)

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
