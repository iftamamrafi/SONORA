# SONORA — Build & Install Guide

Environment: Windows 11 PC, no Mac, free Apple ID, iPhone on iOS 26.
Signing/install: Sideloadly. Two cloud build routes are provided — you only
need ONE. **Route A (GitHub Actions) is recommended**: it needs only a free
GitHub account. Route B (Codemagic) is the alternative.

## Step 1 — Push the project to GitHub (both routes)

1. Create a **private** repository on GitHub, e.g. `sonora-ios`.
2. Push the **contents** of the `SONORA-iOS/` folder as the repository root:

   ```bat
   cd SONORA-iOS
   git init
   git add .
   git commit -m "SONORA initial project"
   git branch -M main
   git remote add origin https://github.com/<your-username>/sonora-ios.git
   git push -u origin main
   ```

   The repo root must contain `SONORA.xcodeproj`, `codemagic.yaml`, and the
   `.github/workflows/` folder (all are at the root of `SONORA-iOS/`).

## Route A — GitHub Actions (recommended, free)

1. Open your GitHub repo → **Actions** tab. If prompted, enable workflows.
2. Select **"Build SONORA (unsigned IPA)"** → **Run workflow** (it also runs
   automatically on every push to `main`).
3. It runs on GitHub's macOS 26 image with Xcode 26, builds the app unsigned
   (`CODE_SIGNING_ALLOWED=NO`), and packages `SONORA-unsigned.ipa`.
4. Open the finished run → **Artifacts** → download **SONORA-unsigned-ipa**.
5. Continue at **Step 3** below (Sideloadly).

> Free GitHub accounts include a monthly Actions allowance (macOS runners
> consume it faster than Linux ones); public repos get free standard minutes.
> If the `macos-26` runner label is unavailable,
> edit `.github/workflows/build-sonora.yml` and switch to `macos-15` as noted
> in the file's comments.

## Route B — Codemagic (alternative)

1. Sign up at codemagic.io with your GitHub account and add the `sonora-ios` app.
2. Codemagic detects `codemagic.yaml` automatically. Workflow: **sonora_ios_unsigned**
   (instance `mac_mini_m2`, Xcode **26.0**). If the Xcode 26.0 image is named
   differently in your dashboard, update `environment.xcode` in `codemagic.yaml`.
3. Start the workflow. It runs:

   ```bash
   xcodebuild -project SONORA.xcodeproj -scheme SONORA -configuration Release \
     -sdk iphoneos -derivedDataPath build CODE_SIGNING_ALLOWED=NO build
   mkdir -p Payload && cp -R build/Build/Products/Release-iphoneos/SONORA.app Payload/
   zip -r SONORA-unsigned.ipa Payload
   ```

4. When it finishes, download the **`SONORA-unsigned.ipa`** artifact.
5. Continue at **Step 3** below (Sideloadly).

> The project sets no signing identity and no paid entitlements, so the unsigned
> build needs no Apple Developer account. If the build fails, read the first
> `error:` line in the Codemagic log — common causes are listed below.

## Step 3 — Sign & install with Sideloadly (Windows)

1. Install iTunes and iCloud from **Apple's website** (not the Microsoft Store
   versions) so Windows has the USB drivers Sideloadly needs.
2. Download Sideloadly from sideloadly.io and open it.
3. Connect the iPhone by USB, unlock it, and tap **Trust** if prompted.
4. Drag `SONORA-unsigned.ipa` into Sideloadly, select your device, enter your
   **free Apple ID**, and click **Start**. Sideloadly creates a free provisioning
   profile for your device and installs SONORA.
5. On the iPhone: **Settings → General → VPN & Device Management** → your Apple ID
   profile → **Trust**.
6. If iOS asks, enable **Developer Mode**: Settings → Privacy & Security →
   Developer Mode → On (iPhone restarts).
7. Open SONORA. Import music from Files (Home or Library → import icon), or use the
   labeled DEMO provider tracks in Explore.

## Free Apple ID limits (important)

- The app **expires after 7 days**; reconnect and re-run Sideloadly to refresh it
  (your library data stays — it lives in the app's Documents/database, but note:
  deleting the app deletes your imported music copies and playlists).
- Max ~3 sideloaded apps active at once and a limited number of App IDs per week.
- No push notifications / paid capabilities — SONORA doesn't need any.
- Live Activities work under free provisioning on iOS 26.

## Troubleshooting

| Problem | Fix |
|---|---|
| Cloud build: "scheme not found" | Ensure `SONORA.xcodeproj/xcshareddata/xcschemes/SONORA.xcscheme` was committed (it is shared, not per-user). |
| Cloud build: signing error | Confirm the workflow still passes `CODE_SIGNING_ALLOWED=NO` and no identity is set in the project. |
| Sideloadly: `provision.cpp` / App ID errors | Weekly App ID limit reached, or bundle ID collision — wait, or change bundle ID in Xcode project settings consistently (app + `.widgets` + `.tests`). |
| "Untrusted Developer" | Trust the profile in Settings (Step 3.5). |
| App installs but won't open | Developer Mode off (Step 3.6), or the 7-day profile expired — re-sideload. |
| No sound in background | Check the app wasn't force-quit; background audio requires the `audio` background mode, already set in Info.plist. |
| Imported FLAC won't play | iOS/AVFoundation FLAC support varies by encoding; convert to M4A/ALAC if a specific file fails. The app reports unsupported files instead of crashing. |

## Local Mac build (if you later get access to one)

Open `SONORA.xcodeproj`, select the SONORA scheme, set your team for signing, Run.
Unit tests: Product → Test (SONORAUnitTests target).
