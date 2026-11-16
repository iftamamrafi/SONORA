# SONORA Technical Architecture

## 1. Recommended architecture

Use SwiftUI with MVVM and protocol-based service boundaries. Keep UI,
domain logic, persistence, and platform integrations separate.

## 2. Suggested project structure

``` text
SONORA/
├── App/
│   ├── SONORAApp.swift
│   ├── AppCoordinator.swift
│   └── AppDependencies.swift
├── Core/
│   ├── Models/
│   ├── Protocols/
│   ├── Errors/
│   ├── Utilities/
│   └── DesignSystem/
├── Features/
│   ├── Home/
│   ├── Explore/
│   ├── Library/
│   ├── Search/
│   ├── NowPlaying/
│   ├── Queue/
│   ├── Playlists/
│   ├── Downloads/
│   ├── Lyrics/
│   ├── Equalizer/
│   └── Settings/
├── Services/
│   ├── Playback/
│   ├── LocalMedia/
│   ├── Metadata/
│   ├── Streaming/
│   ├── Providers/
│   ├── Persistence/
│   ├── Networking/
│   └── Downloads/
├── Resources/
│   └── Assets.xcassets/
├── Configuration/
└── Tests/
    ├── SONORAUnitTests/
    └── SONORAIntegrationTests/
```

## 3. Core service boundaries

### PlaybackCoordinator

Single owner of playback state and active queue. Exposes observable
state to SwiftUI. Prevents multiple simultaneous playback engines.

### LocalMediaService

Imports files, validates formats, manages app-owned copies, and returns
local track records.

### MetadataService

Reads available metadata and artwork from supported media files.
Metadata extraction must not block the main thread.

### MusicProvider

Protocol for authorized online catalogue providers. Example
responsibilities: search, fetch track/album/artist details, and create
playable stream sessions where provider terms permit.

### LibraryRepository

Reads and writes tracks, albums, artists, playlists, favorites, and
history.

### NetworkMonitor

Reports connectivity changes. Connectivity alone does not guarantee
provider availability; requests must still handle errors.

### DownloadManager

Only handles content whose provider explicitly permits offline storage.
Respect DRM and provider licensing.

## 4. Playback design

Use AVPlayer for compatible remote streams and a suitable AVFoundation
implementation for local files. A unified coordinator should normalize
state and commands.

The coordinator should expose: - currentTrack - playbackStatus -
currentTime - duration - queue - shuffleMode - repeatMode -
activeSource - playbackError

Use actual player callbacks/time observers to update progress. Do not
run a UI timer that pretends to represent playback.

## 5. Concurrency

-   Use async/await for asynchronous work.
-   Keep UI state on the main actor.
-   Perform scanning and metadata work off the main thread.
-   Cancel obsolete search and scanning tasks.
-   Avoid retaining large artwork or audio buffers unnecessarily.

## 6. Persistence

Use SwiftData or SQLite. Choose one primary persistence strategy and
document why. Use file storage for imported audio and artwork where
appropriate; store stable identifiers and metadata in the database.

## 7. Security

-   Never commit API secrets.
-   Use Keychain for user tokens where needed.
-   Keep provider credentials in secure build/runtime configuration.
-   Do not upload local files without explicit user action.
-   Use least-privilege file access.

## 8. Testing

Test playback state transitions, queue behavior, repository persistence,
import failures, provider errors, and offline behavior. Mock provider
protocols in unit tests. Test actual audio and background behavior on a
physical iPhone.
