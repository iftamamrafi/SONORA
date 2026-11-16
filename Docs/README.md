# SONORA --- Project Documentation Pack

This pack contains the product, design, architecture, feature, data, and
iOS build specifications for SONORA.

## Product

SONORA is a native iPhone music application for iOS 26 supporting: -
Offline playback of user-imported local audio. - Online discovery and
playback through properly licensed providers. - Local playlists,
favorites, queue, listening history, and preferences.

## Files

-   `DESIGN.md` --- visual design system and screen specifications.
-   `PRODUCT_SPEC.md` --- product scope, requirements, and acceptance
    criteria.
-   `ARCHITECTURE.md` --- recommended SwiftUI architecture and service
    boundaries.
-   `FEATURES.md` --- functional feature requirements and behavior.
-   `DATA_MODEL.md` --- local persistence model.
-   `IOS_BUILD_AND_IPA.md` --- cloud build, unsigned packaging, and
    sideloading guidance.
-   `MUSE_BUILD_INSTRUCTIONS.md` --- instructions for Muse AI.
-   `codemagic.yaml` --- starter cloud build workflow; adjust project
    and scheme names.

## Important

These are project specifications and starter configuration files, not a
compiled application. Muse AI must generate the actual Swift source
code, Xcode project, assets, and tests. An unsigned IPA is not directly
installable; it must be signed for the target device. Free Apple ID
provisioning has restrictions and generally expires after seven days.

Online music requires an authorized provider and any required
credentials or licensing. Do not scrape services or bypass DRM.
