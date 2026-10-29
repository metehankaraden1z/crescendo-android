# Crescendo for Android

The Android app for **Crescendo**, the track-by-track music rating app. Search any album on MusicBrainz, rate
it song by song in half-stars, rate the album as a whole, and watch your Taste DNA build itself.

Built with Flutter in Crescendo's own ink, cream and gold design. The app talks to the Crescendo server's JSON
API, so ratings made here show up on the website too.

## Features

- **Accounts:** sign up, log in, and stay logged in. The session is kept in Android's secure Keystore.
- **Home:** your rating stats, albums you've started rating, and what's trending on Crescendo.
- **Search:** albums and artists from MusicBrainz. Searching an artist's name ("eminem") shows their albums first.
- **Album page:** the full tracklist, community scores, and a half-star rating for every song and for the album.
  Tap or drag across the stars to rate, and long-press to clear.
- **Track-by-track mode:** one song at a time, moving on automatically after each rating, then the album as a
  whole with an optional review.
- **Profile:** Taste DNA genre fingerprint, rating chart, top albums and songs.

## Requirements

- Flutter 3.47 or newer
- Android Studio with the Android SDK (for the emulator) or an Android phone with USB debugging
- A running Crescendo server (`python3 server.py` in the server project)

## Run it

```bash
flutter pub get
flutter run
```

By default the app connects to `http://10.0.2.2:8000`, which is how the Android emulator reaches a server
running on the same computer. On a real phone, start the server with `python3 server.py --host 0.0.0.0` and
point the app at your computer's address:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000
```

Plain HTTP is only allowed in debug builds. Release builds need the server behind HTTPS.

## Project structure

```
lib/
├── main.dart                 # app setup, session check, login vs. main tabs
├── core/
│   ├── config/               # server address
│   ├── network/              # API client, secure session storage, errors
│   ├── session/              # logged-in user state
│   └── theme/                # colours, typography, motion, app theme
├── shared/
│   ├── models/               # album summaries and JSON helpers
│   └── widgets/              # star rating, cover art, buttons, album grid…
└── features/
    ├── auth/                 # sign up / log in
    ├── shell/                # bottom tabs
    ├── home/
    ├── search/
    ├── album/                # album page and track-by-track mode
    └── profile/
```

## Roadmap

- Artist pages, people and taste matching, follows, Listen Later
- iOS release (the project already includes the iOS target)

Music data from [MusicBrainz](https://musicbrainz.org), cover art from the
[Cover Art Archive](https://coverartarchive.org).
