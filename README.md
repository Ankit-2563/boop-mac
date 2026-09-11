# Boop — Mac Companion

[![Release](https://img.shields.io/github/v/release/Ankit-2563/boop-mac?color=blue&label=macOS%20Release)](https://github.com/Ankit-2563/boop-mac/releases/latest)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**Menu bar app that lets your Android phone launch Mac apps.**

Boop runs as an invisible menu-bar companion on your Mac. It serves a tiny, secure local HTTP API that your Android phone connects to over local WiFi, letting you launch any Mac app with a single tap.

---

## 🚀 Quick Download & Install

1. Download **[Boop-macOS.zip](https://github.com/Ankit-2563/boop-mac/releases/latest/download/Boop-macOS.zip)**.
2. Unzip and drag **Boop.app** into your `/Applications` folder.
3. Launch **Boop.app**.
4. Look for the dock icon in your **menu bar** (top right) — click it to see your 6-digit pairing code!

---

## How It Works

1. **Local WiFi Discovery**: Advertises via Bonjour (`_boop._tcp`) so your phone automatically detects your Mac on the same network.
2. **Pair Once**: Enter the 6-digit code shown in your menu bar into the Android app.
3. **Launch Apps**: Browse all installed Mac applications from your phone and launch them instantly.

---

## Security

- **Local Network Only**: The companion binds only to your local network interface. No internet server or cloud relay.
- **Token Authentication**: All API endpoints require an `X-Dock-Token` header matching the 6-digit pairing code.
- **Path Validation**: Only launch requests targeting verified applications within `/Applications` or `/System/Applications` are allowed.

---

## Building from Source

Prerequisites: macOS 13+, Swift 5.9+

```bash
git clone https://github.com/Ankit-2563/boop-mac.git
cd boop-mac
swift run
```

To build a release binary:
```bash
swift build -c release
```

---

## License

MIT © [Ankit-2563](https://github.com/Ankit-2563)
