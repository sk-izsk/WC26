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
