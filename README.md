# SONORA — Premium Hybrid Music Player (iOS)

Native SwiftUI music player for iPhone, iOS 26. Online discovery through an
authorized provider interface + full offline local library. Bundle ID:
`com.sonora.musicplayer`.

> Tagline: **Your Music. Your World. Always in Rhythm.**

## What is implemented

- **Navigation**: TabView (Home, Explore, Library, Search), persistent mini-player,
  full-screen Now Playing, NavigationStack per tab.
- **Local library**: Files import (MP3/M4A/AAC/WAV/AIFF/FLAC/ALAC/CAF) with
  security-scoped access, app-managed copies in `Documents/Music`, AVAsset metadata +
  artwork extraction, duplicate detection (size + title + duration, including
  duplicates within one import batch). A launch availability check flags tracks
  whose files disappeared; Library shows a "Missing Files" section to remove them.
  Manual metadata editing (title/artist/album/genre/year/track number) is available
  from a song's context menu in the Songs list and from Now Playing. 
- **Playback**: One `PlaybackManager` owning an `AVPlayer` for local files and remote
  streams; real periodic time observer; AVAudioSession `.playback`; Lock Screen /
  Control Center via MPNowPlayingInfoCenter + MPRemoteCommandCenter; interruption and
  headphone-unplug handling; queue with shuffle/repeat; sleep timer with fade-out.
- **Equalizer (honest)**: local files route through `LocalEQPlayer`
  (AVAudioPlayerNode → 10-band AVAudioUnitEQ) when EQ is on. Streams stay on AVPlayer
  and the EQ screen explains the limitation. 9 presets incl. Custom.
- **Online**: `MusicProvider` protocol. Default provider is a clearly-labeled **DEMO**
  using SoundHelix test audio (labeled DEMO everywhere, `isDemo = true`). Disable it in
  Settings and Explore/Search show an explicit "provider not configured" state — no fake
  catalogue. Add a licensed provider by conforming to `MusicProvider`.
- **Downloads**: only for provider-permitted tracks (demo tracks). Progress, pause/resume
  (resume data), cancel; stored in `Documents/Downloads`; respects DRM by design.
- **Lyrics**: embedded lyrics + sidecar `.lrc` files, LRC parser, synced highlighting
  driven by real playback time. No fabricated lyrics.
- **Persistence**: SwiftData (Track, Album, Playlist, PlaylistItem, ListeningHistory,
  LocalAsset). Preferences in UserDefaults.
- **Live Activity**: WidgetKit extension (`SONORAWidgets`) with a Now Playing Live
  Activity / Dynamic Island UI.
- **Tests**: unit tests for queue, shuffle/repeat, LRC parsing, playlists (in-memory
  SwiftData), search, metadata defaults, provider labeling.

## Project structure

```
SONORA-iOS/
  SONORA.xcodeproj/            (shared scheme: SONORA)
  SONORA/
    App/        SONORAApp, AppState, RootView
    Core/       Models, Entities (SwiftData), PlaybackQueue, LRCParser,
                PreferencesStore, DesignSystem
    Services/   PlaybackManager, LocalEQPlayer, MusicProvider (Demo/Unavailable),
                MetadataService, LocalMusicService, LyricsService, DownloadManager,
                NetworkMonitor, ArtworkCache, LiveActivityManager
    Shared/     NowPlayingActivityAttributes (app + widget targets)
    Components/ SharedViews (SongRow, ArtworkView, importer, menus)
    Features/   Home, Explore, Library, Search, DetailViews, Playlists,
                LibraryExtras (Favorites/Recent/Downloads/Missing Files), MiniPlayer,
                NowPlaying, Queue, Lyrics, Equalizer, Settings, EditTrackMetadata
    Resources/  Info.plist, SONORA.entitlements, Assets.xcassets, SampleTone.wav
                (SampleTone.wav is a generated 3s sine-sweep test tone — not music)
  SONORAWidgets/   Live Activity extension
  SONORAUnitTests/ XCTest bundles sources
  codemagic.yaml   unsigned cloud build workflow
  Docs/            the original specification pack
  BUILD.md         step-by-step build + sideload guide
  DEPENDENCIES.md  framework list (zero third-party dependencies)
```

## Build

See **BUILD.md**. Short version: push to GitHub → **Route A:** GitHub Actions
workflow "Build SONORA (unsigned IPA)" (macOS 26 / Xcode 26,
`CODE_SIGNING_ALLOWED=NO`), or **Route B:** Codemagic workflow
`sonora_ios_unsigned` → download `SONORA-unsigned.ipa` → sign & install with
Sideloadly + free Apple ID on Windows.

An unsigned IPA is **not** directly installable; Sideloadly performs the free
provisioning signing during installation.
