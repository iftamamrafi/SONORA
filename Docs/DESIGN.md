# SONORA Design System

## Native iOS 26 --- iPhone

## 1. Design principles

SONORA should feel premium, calm, editorial, and music-focused. The
interface must be unmistakably native to iOS while maintaining its own
visual identity.

Principles: - Artwork is the visual hero. - Prioritize legibility and
one-handed use. - Use motion to communicate state, not as decoration. -
Keep controls predictable and accessible. - Support Dark, Light, and
System appearance. - Respect Dynamic Type, VoiceOver, Reduce Motion, and
safe areas.

Do not copy Apple Music, Spotify, or Poweramp screen-for-screen.

## 2. Visual tokens

### Color

  Token               Suggested value   Use
  ------------------- ----------------- ------------------------------
  `background`        `#08080B`         Main dark background
  `surface`           `#14141A`         Cards and panels
  `surfaceElevated`   `#1D1D25`         Sheets and elevated controls
  `accent`            `#B69CFF`         Primary actions and progress
  `accentSecondary`   `#8B78D8`         Secondary accent
  `textPrimary`       `#FFFFFF`         Main text in dark mode
  `textSecondary`     `#A1A1AA`         Supporting text
  `separator`         `#303039`         Subtle dividers
  `success`           System green      Success states
  `warning`           System orange     Warnings
  `error`             System red        Errors

Implement semantic adaptive colors for Light Mode rather than reusing
dark-mode hex values unchanged.

### Typography

Use the native San Francisco system typeface. - Large title:
`.largeTitle` / `.title` - Section heading: `.title2` / `.title3` -
Track title: `.headline` - Artist and metadata: `.subheadline` /
`.caption` - Use monospaced digits for playback time where appropriate.

### Shape and spacing

-   Use a consistent 4-point spacing scale.
-   Standard card corner radius: 16--22 pt.
-   Artwork corners: 10--16 pt depending on context.
-   Buttons must meet Apple's touch-target guidance; aim for at least 44
    × 44 pt.
-   Use subtle borders and materials; avoid excessive blur and glass.

## 3. Navigation

Use a native bottom tab bar with: 1. Home 2. Explore 3. Library 4.
Search

A persistent mini-player sits above the tab bar while a track is
selected. Tapping it presents the full Now Playing screen.

Use native navigation stacks and sheets. Avoid custom navigation that
breaks standard iOS gestures.

## 4. Screen specifications

### Home

-   Greeting and SONORA identity.
-   Recently Played.
-   Recently Added.
-   Your Playlists.
-   Favorite Tracks.
-   Local Library entry point.
-   Online editorial sections only when a provider is configured and the
    device is online.
-   Offline state must prioritize local content.
-   Empty state includes a clear "Import Music" action.

### Explore

-   Search entry point.
-   Genres and curated collections from the configured provider.
-   Trending and new releases only when backed by real provider data.
-   Clearly distinguish provider content from local files.

### Library

Provide segmented or grouped access to Songs, Albums, Artists,
Playlists, Downloads, and Folders where supported. - Sorting and
filtering. - Clear source labels: LOCAL, ONLINE, DOWNLOADED. -
Multi-select actions where useful.

### Search

-   Search local library immediately.
-   Search online catalogue only when online and a provider is
    configured.
-   Separate local and online results.
-   Recent search history with clear action.
-   Loading, no-results, offline, and provider-error states.

### Mini-player

-   Artwork thumbnail.
-   Track title and artist.
-   Play/pause.
-   Optional next action if space permits.
-   Clear selected/playing state.
-   Accessible labels for every control.

### Now Playing

-   Large artwork.
-   Track and artist.
-   Favorite action.
-   Scrubber with elapsed and total time.
-   Previous, play/pause, next.
-   Shuffle and repeat.
-   Queue and lyrics entry points.
-   Dynamic artwork-derived background may be used, but maintain
    readable contrast.
-   Show source and offline availability where relevant.

### Queue

-   Current track and upcoming tracks.
-   Reorder, remove, play next, clear queue.
-   Correct behavior with shuffle and repeat.

### Settings

-   Appearance.
-   Playback preferences.
-   Audio/equalizer if genuinely supported.
-   Library management.
-   Storage.
-   Privacy.
-   About.

## 5. Interaction and motion

-   Use native SwiftUI transitions and spring animations sparingly.
-   Animate mini-player expansion and artwork changes smoothly.
-   Respect Reduce Motion.
-   Never animate a fake playback state.
-   Progress must be driven by actual player time.
-   Avoid blocking gestures or controls during transitions.

## 6. Accessibility

-   VoiceOver labels and hints for controls.
-   Dynamic Type support.
-   Sufficient contrast in both themes.
-   Do not rely on color alone to communicate LOCAL/ONLINE/DOWNLOADED.
-   Support Reduce Motion.
-   Ensure all interactive controls have appropriate hit areas.

## 7. Responsive behavior

This is an iPhone-first application. Support compact and larger iPhone
sizes, portrait and landscape where appropriate, and safe-area changes.
Do not create iPad or desktop requirements unless explicitly added
later.
