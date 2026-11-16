# SONORA iOS Build and IPA Guide

## Environment

-   Target: iPhone / iOS 26.
-   Swift and SwiftUI.
-   Xcode 26-compatible toolchain.
-   Cloud macOS build service such as Codemagic.
-   Windows PC for final sideloading.
-   Free Apple ID; no paid Apple Developer membership.

## Important distinction

Compilation, IPA packaging, code signing, and installation are separate
steps.

An unsigned app bundle or unsigned IPA is not directly installable on an
iPhone. It must be signed with a provisioning profile valid for the
target device.

## Suggested workflow

1.  Muse AI generates the complete Xcode project.
2.  Store the project in a private GitHub repository.
3.  Connect the repository to a cloud macOS build service.
4.  Select a compatible Xcode 26 image.
5.  Build the Release app for `iphoneos` without distribution signing.
6.  Package the `.app` inside a `Payload/` folder and create an unsigned
    IPA artifact if the build service supports this workflow.
7.  Download the artifact to Windows.
8.  Use a reputable sideloading tool such as Sideloadly to sign/install
    with the user's own Apple ID.
9.  Trust/enable the required developer settings on the iPhone if
    prompted.

## Build configuration

-   Bundle identifier: `com.sonora.musicplayer` (verify availability and
    change if needed).
-   Product name: `SONORA`.
-   Deployment target: iOS 26.0.
-   Scheme: `SONORA`.
-   Configuration: Release.
-   SDK: `iphoneos`.

## Unsigned build command

Adjust the project and scheme names to match the generated project:

``` bash
xcodebuild \
  -project SONORA.xcodeproj \
  -scheme SONORA \
  -configuration Release \
  -sdk iphoneos \
  -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO \
  build
```

The resulting `.app` is typically under:
`build/Build/Products/Release-iphoneos/SONORA.app`

Package it as an unsigned IPA:

``` bash
mkdir -p Payload
cp -R build/Build/Products/Release-iphoneos/SONORA.app Payload/
zip -r SONORA-unsigned.ipa Payload
```

Verify the app path and archive contents before treating the artifact as
valid.

## Free Apple ID limitations

Free provisioning is intended for personal development/testing, not
public distribution. Provisioning commonly expires after seven days and
has limits on app IDs and installed development apps. Exact restrictions
can change; check current Apple documentation.

Some capabilities and entitlements require paid Apple Developer Program
membership. Do not enable unsupported capabilities.

## Background audio

Background audio requires correct AVAudioSession configuration and the
appropriate Background Modes capability. Verify on a physical device. Do
not add unrelated entitlements.

## Codemagic

The included `codemagic.yaml` is a starter workflow. Confirm the
available Xcode image identifier and project/scheme names in the
Codemagic dashboard before running it. Cloud build minutes and plan
limits may apply.

## Security

Never put Apple account passwords, app-specific passwords, API private
keys, or signing certificates into source control or Muse AI chat. Use
secure environment variables or the build service's credential
integration.

## Troubleshooting

-   "No such module": verify dependency resolution and Xcode version.
-   Signing error: confirm CODE_SIGNING_ALLOWED=NO for unsigned build
    stage.
-   Missing scheme: create and share the SONORA scheme in Xcode.
-   Missing app bundle: inspect the actual build product path.
-   Install rejected: confirm IPA structure, signing, provisioning,
    device registration, and iOS compatibility.
-   App launches then exits: inspect device logs and crash reports.

## Delivery truthfulness

Do not call an artifact installable until it has been signed for the
device and installation has been verified. Do not claim a cloud build
succeeded without an actual successful build result.
