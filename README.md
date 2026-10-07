# Ukulele Groove

Live app: https://kunaxar.github.io/ukulele-groove/

A Flutter web ear-training app. Listen to an original mini-song, choose a strumming pattern, and learn why it fits. Same-meter alternatives are valid arrangements, not automatically wrong answers.

## Run locally

Use Flutter 3.47.6 stable or a compatible newer stable release.

```sh
python3 web/generate_audio.py
flutter pub get
flutter run -d chrome
flutter analyze
flutter test
flutter build web --base-href /ukulele-groove/
```

## Features

- Five original synthesized mini-songs; five strumming patterns.
- Song playback, 0.75x speed, beat guide and comparison audio.
- Meter, offbeat, skip and mute explanations.
- Editable rhythm lab with synthesized playback.

## Project layout

`lib/main.dart` contains the Flutter UI; `lib/data.dart` contains lessons and patterns. `web/audio.js` handles browser audio and the rhythm synthesizer; `web/audio.json` indexes original generated WAV clips. `test/widget_test.dart` checks lesson/pattern invariants. `docs/` is the release web build served by GitHub Pages.

`web/generate_audio.py` reproduces every practice clip with standard Python. The workflow tests source changes and updates the release build automatically.

To update the site manually, run the build command above, replace `docs/` with the contents of `build/web/`, and commit. Pages serves the `main` branch's `docs` folder. The audio bridge is web-only. Android/iOS builds need a platform audio adapter; this is not an APK.

No microphone scoring, upload analysis or commercial song recordings. Progress lasts for the open session. Suggestions are teaching arrangements, not a single compulsory answer.

## Teaching references

- https://ukuleletricks.com/4-strumming-patterns-to-play-any-song-on-ukulele/
- https://www.ukulalala.com/learn/how-to-strum-the-ukulele

The sample recordings are original synthesized practice content. No proprietary hosted-page components are used.
