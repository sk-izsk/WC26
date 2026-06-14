# WC26

macOS menu bar app for World Cup 2026 fixtures, live scores, standings, and match alerts.

![WC26 demo](./WC26.gif)

## Features

- Menu bar app with a popover UI for fixtures and standings
- Live matches pinned to the top of the fixture list
- Live timer support, including stoppage time when the API provides it
- Team detail sheets with standings, schedule, and recent results
- Favorite teams that bubble to the top of daily fixtures
- Match notifications for kickoff, goals, and full time
- In-app banners while the popover is open
- Pinned live match and rotating menu bar score modes
- Start at login toggle
- Appearance controls for panel and card transparency
- Adjustable refresh interval

## Data Source

Fixture and standings data come from Reza Rahiminia's World Cup 2026 API project:

- GitHub: <https://github.com/rezarahiminia/worldcup2026>

Credit to the API owner for making the data available.

## Install

This app is not signed or notarized with an Apple Developer account. That is intentional for this fun project.

The normal install flow:

1. Open the DMG.
2. Drag `WC26.app` to `Applications`.
3. Run:

```bash
xattr -cr /Applications/WC26.app
```

4. Try opening the app.
5. If macOS still blocks it, right-click the app and choose `Open`.

If you want to check attributes first:

```bash
xattr /Applications/WC26.app
```

If you are opening it directly from the DMG instead of copying first:

```bash
xattr -cr "/Volumes/WC26/WC26.app"
```

If execution permission somehow got messed up:

```bash
chmod +x /Applications/WC26.app/Contents/MacOS/WC26
```

Skipped: proper Apple signing and notarization. Add that only if you want installs without workarounds.

## Build

Open `WC26.xcodeproj` in Xcode and run the `WC26` scheme.

CLI build:

```bash
xcodebuild -project WC26.xcodeproj -scheme WC26 build
```

## GitHub Release

### Web UI

1. Push your code to GitHub.
2. Open the repository on GitHub.
3. Click `Releases`.
4. Click `Draft a new release`.
5. Choose or create a tag like `v0.1.0`.
6. Add a release title and notes.
7. In the binaries/assets area, drag the `.dmg` file onto the release form.
8. Publish the release.

### GitHub CLI

If you use `gh`, this is shorter:

```bash
gh release create v0.1.0 path/to/WC26.dmg --title "WC26 v0.1.0" --notes "First public build"
```

If the release already exists and you just want to upload the DMG:

```bash
gh release upload v0.1.0 path/to/WC26.dmg
```

## Notes

- If you share the DMG with someone else, tell them up front that the app is unsigned.
- For unsigned builds, `xattr -cr` is the usual workaround.
- The app is designed for macOS and lives in the menu bar, not the Dock.

## Sources

- GitHub Docs, "Managing releases in a repository": <https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository>
