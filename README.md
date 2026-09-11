# Boop — Mac Companion

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**Menu bar app that lets your Android phone launch Mac apps.**

Boop runs as an invisible menu-bar companion on your Mac. It serves a tiny, secure local HTTP API that your Android phone connects to over local WiFi, letting you launch any Mac app with a single tap.

---

## 💻 Getting Started

The Boop companion runs in your menu bar. 

Downloadable builds for macOS will be hosted on the official Boop website (coming soon). You can also build and run directly from source below.

---

## How It Works

1. **Instant QR Pairing**: Click **Show QR Code** in the menu bar. The floating window presents a high-resolution QR code encoding your local IP and authentication token.
2. **Scan & Pair**: Scan the QR code with Boop on your Android phone for instant, zero-configuration connection.
3. **Manual Fallback**: If preferred, enter the displayed local IP address and 6-digit PIN manually.
4. **Launch Apps**: Tap any app on your phone's dock to launch it instantly on your Mac.

See [docs/PAIRING_PROTOCOL.md](docs/PAIRING_PROTOCOL.md) for full technical details on the pairing schema and HTTP endpoints.

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
