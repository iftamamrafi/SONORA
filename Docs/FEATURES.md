# SONORA Feature Requirements

## Priority legend

-   P0: Required for a usable first release.
-   P1: Important enhancement.
-   P2: Optional/advanced, subject to platform and provider support.

## P0 --- Core application

-   Native iOS navigation.
-   Home, Explore, Library, Search.
-   Empty, loading, error, and offline states.
-   Dark, Light, and System appearance.
-   Local file import through Files.
-   Local metadata and artwork extraction where available.
-   Songs, Albums, Artists views.
-   Local audio playback.
-   Mini-player and Now Playing.
-   Play, pause, seek, previous, next.
-   Queue, shuffle, repeat.
-   Local playlists.
-   Favorites.
-   Recently played.
-   Local search.
-   Persistent settings and library metadata.

## P0 --- Online provider foundation

-   Provider protocol and adapter architecture.
-   Provider configuration state.
-   Online search when configured.
-   Authorized stream playback when available.
-   Explicit provider errors and unavailable states.
-   No fake catalogue or playback.

## P1 --- Native experience

-   Background audio.
-   Lock Screen and Control Center Now Playing information.
-   Headphone and audio interruption handling.
-   Artwork caching.
-   Import progress and duplicate detection.
-   Playlist reorder.
-   Manual metadata editing.
-   Storage management.

## P1 --- Advanced audio

-   Equalizer only if the selected processing pipeline genuinely
    supports it.
-   Playback speed where supported.
-   Crossfade/gapless only if technically supported and tested.
-   Sleep timer.

## P1 --- Lyrics

-   Embedded lyrics where extractable.
-   Local LRC files.
-   Synchronized highlighting based on actual playback time.
-   Clear unavailable state.

## P2 --- Optional integrations

-   Live Activities / Dynamic Island.
-   Cloud playlist synchronization.
-   Account system.
-   Cross-device settings synchronization.
-   Provider-authorized offline downloads.

## Explicit limitations

-   Do not bypass DRM.
-   Do not copy protected provider streams.
-   Do not claim every audio format is supported without testing.
-   Do not claim true system-wide equalizer control if only app playback
    can be processed.
-   Do not claim folder-wide filesystem access on iOS; use supported
    document picker workflows.
