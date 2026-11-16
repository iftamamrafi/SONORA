# SONORA — Dependencies

**Zero third-party dependencies.** No CocoaPods, no Swift Package Manager packages.
Everything is built on native Apple frameworks, which keeps the unsigned cloud
build simple and reproducible.

| Framework | Used for |
|---|---|
| SwiftUI | All UI, navigation, TabView, sheets |
| SwiftData | Local persistence (tracks, albums, playlists, history, assets) |
| AVFoundation | AVPlayer playback, AVAudioEngine + AVAudioUnitEQ equalizer, AVAsset metadata |
| AVFAudio (part of AVFoundation) | AVAudioSession configuration |
| MediaPlayer | MPNowPlayingInfoCenter, MPRemoteCommandCenter (Lock Screen / Control Center) |
| ActivityKit | Live Activity lifecycle from the app |
| WidgetKit | Live Activity / Dynamic Island UI in SONORAWidgets |
| Network | NWPathMonitor online/offline detection |
| UniformTypeIdentifiers | File importer content types |
| UIKit | UIImage artwork handling, dynamic colors |
| Foundation | FileManager, URLSession downloads, UserDefaults, timers |

External content (not a dependency): demo tracks stream from SoundHelix
(https://www.soundhelix.com) test-audio URLs via the DemoMusicProvider. No audio
files from third parties are bundled. `SampleTone.wav` is a locally generated
3-second sine sweep used only as a test tone.
