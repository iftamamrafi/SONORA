# SONORA Product Specification

## 1. Product summary

SONORA is a native iPhone music application for iOS 26 that combines
local/offline music playback with online discovery and authorized
streaming.

## 2. Target user

People who want one polished music app for their own audio files and
access to legitimate online music catalogues.

## 3. Product goals

1.  Make local music importing and playback reliable.
2.  Keep core local playback useful without internet.
3.  Provide a clean integration point for licensed online providers.
4.  Deliver a premium native iOS experience.
5.  Keep user music and personal library data private.

## 4. Non-goals

-   Reproducing Spotify or Apple Music's licensed catalogue.
-   Scraping music services.
-   Circumventing DRM.
-   Uploading personal music automatically.
-   Claiming unsupported platform features work.
-   Building Android, Windows, or web applications.

## 5. Platform

-   iPhone.
-   iOS 26 deployment target.
-   Swift 6 and SwiftUI.
-   Xcode 26 compatible project.
-   Native frameworks wherever practical.

## 6. Functional requirements

### Local music

-   Import audio through the Files document picker.
-   Validate file types and access.
-   Extract metadata and artwork where available.
-   Maintain durable access using app-managed copies or supported
    security-scoped access.
-   Browse songs, albums, artists, and playlists.
-   Handle unavailable and corrupt files gracefully.

### Online music

-   Use a provider adapter.
-   Require authorized API access and credentials where applicable.
-   Search and stream only content the provider permits.
-   Reflect real provider availability and network state.
-   Never present mock catalogue entries as live results.

### Playback

-   One playback coordinator manages the active source.
-   Support play, pause, seek, previous, next, shuffle, and repeat.
-   Update Now Playing metadata.
-   Handle interruptions and audio route changes.
-   Background playback only when correctly configured and verified.

### Personal library

-   Local playlists.
-   Favorites.
-   Listening history.
-   Queue.
-   User preferences.

## 7. Reliability requirements

-   No fake playback state.
-   No silent failure when a file is missing.
-   No duplicate playback engines.
-   Do not block the main thread during scanning.
-   Persist user data.
-   Provide useful error messages and recovery actions.

## 8. Acceptance criteria

-   A user can import a supported audio file.
-   The imported track appears in the local library.
-   The track plays without network access.
-   Playback controls reflect actual audio state.
-   A playlist survives app relaunch.
-   Favorites survive app relaunch.
-   Local search works offline.
-   Online sections clearly indicate unavailable provider/network
    states.
-   The project compiles with the documented Xcode version.
-   IPA packaging and signing steps are reproducible.
