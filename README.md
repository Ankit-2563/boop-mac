# Boop — Mac Companion

**Menu bar app that lets your Android phone launch Mac apps.**

Boop runs as an invisible menu-bar app on your Mac. It serves a tiny local HTTP API that your phone connects to over WiFi, letting you launch any Mac app with a single tap from your phone.

## How It Works

```
Phone ──── WiFi (LAN) ────► Mac (port 8492)
```

1. Launch Boop — it appears as an icon in your menu bar
2. Click the icon to see your **6-digit pairing code**
3. Enter this code in the Boop Android app to pair
4. Your phone can now browse and launch Mac apps

## Requirements

- macOS 13+ (Ventura or later)
- Xcode 15+ (to build from source)
- Both devices on the same WiFi network

## Build from Source

1. Open `Boop.xcodeproj` in Xcode (or create a new macOS App project)
2. File → Add Package Dependencies → paste:
   ```
   https://github.com/httpswift/swifter.git
   ```
3. Add the source files: `AppDelegate.swift`, `HTTPServer.swift`, `AppScanner.swift`
4. Copy `Boop/Info.plist` and `Boop/Boop.entitlements` into the project
5. Build & Run (⌘R)

## API Endpoints

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/ping` | GET | No | Returns Mac name for discovery |
| `/apps` | GET | Token | Lists all installed Mac apps |
| `/icon?path=...` | GET | Token | Returns app icon as PNG |
| `/launch` | POST | Token | Launches an app on the Mac |

Auth: Send pairing token as `X-Dock-Token` header.

## Security

- **Path validation**: Only apps in `/Applications`, `/System/Applications`, `~/Applications` can be launched
- **Rate limiting**: 60 requests/minute per endpoint
- **Token persistence**: Pairing code survives app restarts
- **Local only**: Server only accessible on LAN

See [docs/SECURITY.md](docs/SECURITY.md) for the full threat model.

## Companion App
Install [Boop for Android](https://github.com/Ankit-2563/boop-android) on your phone.

## License
MIT — see [LICENSE](LICENSE) for details.
