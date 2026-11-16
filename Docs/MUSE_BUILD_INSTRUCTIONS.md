# Instructions for Muse AI --- SONORA

Build SONORA using the accompanying documentation as the source of
truth.

Read these files before implementation: 1. `PRODUCT_SPEC.md` 2.
`DESIGN.md` 3. `ARCHITECTURE.md` 4. `FEATURES.md` 5. `DATA_MODEL.md` 6.
`IOS_BUILD_AND_IPA.md`

## Non-negotiable requirements

-   Native Swift and SwiftUI.
-   iPhone only.
-   iOS 26 target.
-   Online and offline architecture.
-   Real local audio playback.
-   Authorized online provider integration only.
-   No fake playback or fabricated catalogue.
-   Local-first data persistence.
-   Complete Xcode project and shared scheme.
-   Cloud-build-ready project.
-   No secrets committed to source control.

## Work sequence

1.  Inspect environment and confirm available capabilities.
2.  Create the Xcode project and shared scheme.
3.  Implement design tokens and navigation.
4.  Implement persistence and domain models.
5.  Implement local import and metadata extraction.
6.  Implement the local audio playback engine.
7.  Implement mini-player, Now Playing, and queue.
8.  Implement playlists, favorites, and search.
9.  Implement provider abstraction and authorized online integration.
10. Implement background audio and Now Playing integration.
11. Implement advanced features only when genuinely supported.
12. Add tests and resolve compile errors.
13. Prepare cloud build configuration.
14. Produce a complete source ZIP and build documentation.

## Deliverables

-   Complete `.xcodeproj` and source tree.
-   Shared Xcode scheme.
-   Assets and configuration.
-   Unit tests.
-   `codemagic.yaml`.
-   `SONORA-iOS-Project.zip`.
-   Unsigned IPA only after a successful build and packaging step.

Do not merely describe these steps. Execute them in the available
environment. If you cannot create or compile a file, state exactly what
is missing and provide the next actionable step.
