# Posture Check

Posture Check is a menu bar macOS app that sends local reminders to check your posture on a schedule. The app is intentionally narrow: it handles scheduling, notifications, and launch-at-login, without tracking or analytics.

## Features

- Menu bar first interface with no regular Dock workflow
- Local posture reminders on a configurable interval
- Optional working-hours window and weekdays-only scheduling
- Launch at login via `SMAppService`
- Sandboxed target suitable for Mac App Store distribution

## Build

1. Generate the project:

   ```bash
   ruby scripts/generate_project.rb
   ```

2. Build the debug target from the command line:

   ```bash
   DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
   xcodebuild \
     -project PostureCheck.xcodeproj \
     -scheme PostureCheck \
     -configuration Debug \
     CODE_SIGNING_ALLOWED=NO \
     build
   ```

3. Run tests:

   ```bash
   DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
   xcodebuild \
     -project PostureCheck.xcodeproj \
     -scheme PostureCheck \
     -destination 'platform=macOS' \
     CODE_SIGNING_ALLOWED=NO \
     test
   ```

4. Build the release configuration that you will archive in Xcode:

   ```bash
   DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
   xcodebuild \
     -project PostureCheck.xcodeproj \
     -scheme PostureCheck \
     -configuration Release \
   CODE_SIGNING_ALLOWED=NO \
   build
   ```

## CI/CD

- [ci.yml](/Users/ruby/Documents/dev/posture-check/.github/workflows/ci.yml) builds and tests the app on every push to `main` and on pull requests.
- [release.yml](/Users/ruby/Documents/dev/posture-check/.github/workflows/release.yml) builds an unsigned `.dmg` and publishes it to the GitHub release when you push a tag like `v1.0.1`.
- [release_dmg.sh](/Users/ruby/Documents/dev/posture-check/scripts/release_dmg.sh) contains the release packaging flow used both by CI and for local validation.

### Release notes

- This workflow intentionally produces an unsigned `.dmg`.
- No Apple Developer account or GitHub Actions secrets are required for this release path.
- End users will likely see Gatekeeper warnings because the app is not notarized.
- Users may need to right-click the app in Finder and choose `Open` on first launch.

### Release flow

1. Push a tag such as `v1.0.1`:

   ```bash
   git tag v1.0.1
   git push origin v1.0.1
   ```

2. The `Release DMG` workflow will publish `PostureCheck.dmg` and its checksum to that GitHub release.

## App Store checklist

- Replace `com.ruby.PostureCheck` with your production bundle identifier if needed.
- Select your Apple Developer team in Xcode for the app target.
- Archive from Xcode with code signing enabled.
- Verify notifications, launch-at-login, and the menu bar workflow on a clean macOS account.
- Capture App Store screenshots and fill in App Privacy in App Store Connect. This app stores settings locally and does not collect user data.

## GitHub Pages

- The static download page lives in [docs/index.html](/Users/ruby/Documents/dev/posture-check/docs/index.html).
- GitHub Pages deployment is configured in [pages.yml](/Users/ruby/Documents/dev/posture-check/.github/workflows/pages.yml) and publishes the `docs/` folder on pushes to `main`.
- The public download target is configured in [site-config.js](/Users/ruby/Documents/dev/posture-check/docs/site-config.js) and points to the latest unsigned DMG release.

## Project structure

- [PostureCheck](/Users/ruby/Documents/dev/posture-check/PostureCheck)
- [PostureCheckTests](/Users/ruby/Documents/dev/posture-check/PostureCheckTests)
- [scripts/generate_project.rb](/Users/ruby/Documents/dev/posture-check/scripts/generate_project.rb)
- [scripts/generate_app_icon.swift](/Users/ruby/Documents/dev/posture-check/scripts/generate_app_icon.swift)
