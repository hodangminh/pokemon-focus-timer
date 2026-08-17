---
name: create-release-version
description: Build, package, and publish a new GitHub release of PokemonFocusTimer. Use whenever the user asks to "cut a release", "ship a new version", "publish an update", "create a release version", "make a release", "release v1.x", or otherwise indicates they want end users to receive a new build of the app. Handles version bump, archive/export, zipping, GitHub release creation, and README download-link update.
---

# Create Release Version — PokemonFocusTimer

This skill drives the full release pipeline for the PokemonFocusTimer macOS app: version bump → archive → export → zip → GitHub release → README update.

## Prerequisites

Verify these once at the start; stop and tell the user if anything is missing:

- Full **Xcode** is installed (`xcode-select -p` should not point at `CommandLineTools`). If it does, run `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`.
- **`gh` CLI** is installed and authenticated (`gh auth status`).
- Working tree is clean (`git status --porcelain` is empty). If not, ask the user whether to commit or stash first.
- Current branch is `main` (or ask the user to confirm the release branch).

## Inputs to collect

Before running, confirm with the user:

1. **New version** (Marketing Version), e.g. `1.1`. Look up the current one first via `agvtool what-marketing-version` or by grepping `MARKETING_VERSION` in `PokemonFocusTimer.xcodeproj/project.pbxproj`, and propose a bump (patch by default).
2. **Release notes** — a short summary of what changed since the last tag. Suggest a draft from `git log <last-tag>..HEAD --oneline` and let the user edit.

## Steps

Run from the repo root (`PokemonFocusTimer/`). Use `TaskCreate` to track these; mark each completed as you go.

### 1. Bump the version

```bash
cd "/Users/minh.ho/Git Repos/Git/FooBar/PokemonFocusTimer"
xcrun agvtool new-marketing-version <NEW_VERSION>
xcrun agvtool next-version -all   # bumps CURRENT_PROJECT_VERSION (build number)
```

Commit the bump:

```bash
git add -A && git commit -m "Bump version to <NEW_VERSION>"
```

### 2. Archive and export the .app

```bash
BUILD_DIR="$(mktemp -d)"
xcodebuild -project PokemonFocusTimer.xcodeproj \
  -scheme PokemonFocusTimer \
  -configuration Release \
  -archivePath "$BUILD_DIR/PokemonFocusTimer.xcarchive" \
  clean archive

xcodebuild -exportArchive \
  -archivePath "$BUILD_DIR/PokemonFocusTimer.xcarchive" \
  -exportPath "$BUILD_DIR/export" \
  -exportOptionsPlist .claude/skills/create-release-version/ExportOptions.plist
```

If `ExportOptions.plist` doesn't exist yet, create it with method `mac-application` (developer-id distribution requires a signing cert; skip if the user isn't set up for that). See `references/export-options.md` for templates.

### 3. Zip the app

`ditto` preserves macOS metadata and code signatures correctly — do NOT use plain `zip`.

```bash
cd "$BUILD_DIR/export"
ditto -c -k --keepParent PokemonFocusTimer.app "PokemonFocusTimer-<NEW_VERSION>.zip"
```

### 4. Tag and create the GitHub release

```bash
cd "/Users/minh.ho/Git Repos/Git/FooBar/PokemonFocusTimer"
git tag -a "v<NEW_VERSION>" -m "Release v<NEW_VERSION>"
git push origin main
git push origin "v<NEW_VERSION>"

gh release create "v<NEW_VERSION>" \
  "$BUILD_DIR/export/PokemonFocusTimer-<NEW_VERSION>.zip" \
  --title "v<NEW_VERSION>" \
  --notes "<release notes>"
```

### 5. Update README download link

The README has a "Download" section pointing at the latest release asset. Update the version in the link and any version-specific text (e.g. "Latest: v1.1"), then:

```bash
git add README.md && git commit -m "Update README download link to v<NEW_VERSION>"
git push origin main
```

### 6. Post-release verification

- `gh release view v<NEW_VERSION>` — confirm the asset uploaded.
- Download the zip from the release page, unzip, and open. On unsigned builds the user (and any tester) will hit Gatekeeper; the README should mention `xattr -dr com.apple.quarantine PokemonFocusTimer.app` as the workaround.

## Notes on signing & notarization

If the user has a Developer ID cert, add these steps between #3 and #4 to avoid the Gatekeeper prompt for end users:

```bash
codesign --deep --force --options runtime \
  --sign "Developer ID Application: <NAME> (<TEAMID>)" PokemonFocusTimer.app
xcrun notarytool submit PokemonFocusTimer-<NEW_VERSION>.zip \
  --apple-id <APPLE_ID> --team-id <TEAMID> --keychain-profile <PROFILE> --wait
xcrun stapler staple PokemonFocusTimer.app
# Re-zip after stapling so the release asset includes the stapled ticket.
```

If they don't have a cert, ship unsigned and keep the quarantine workaround in the README.

## Recovery / rollback

If something fails partway:

- **Bad build**: delete the local tag (`git tag -d v<NEW_VERSION>`) and remote tag (`git push --delete origin v<NEW_VERSION>`), then delete the draft release (`gh release delete v<NEW_VERSION>`). Ask the user before running destructive commands.
- **Wrong asset uploaded**: `gh release upload v<NEW_VERSION> <file> --clobber`.
