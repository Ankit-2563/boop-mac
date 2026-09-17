# Boop Pairing Protocol & API Specification

This document specifies the network communication and pairing protocol between **Boop Mac Companion** and the **Boop Android Mobile App**.

## 1. Overview

Boop pairs devices seamlessly over the local Wi-Fi network without requiring third-party cloud servers or accounts.

1. **Mac** generates a random 6-digit numeric pairing token upon initial launch and persists it in `UserDefaults`.
2. **Mac** determines its local IPv4 address using `getifaddrs` on network interface `en0`/`en1`.
3. **Mac** starts an embedded HTTP server on port `8492`.
4. **Mac** presents a QR code containing the pairing URI.
5. **Android app** scans the QR code or receives manual IP & token input.
6. **Android app** connects directly to the Mac via local HTTP requests authenticated with an `X-Dock-Token` header.

---

## 2. QR Code URI Schema

The QR code encodes a custom URI scheme:

```text
boop://<HOST>:<PORT>?token=<TOKEN>
```

### Example
```text
boop://192.168.1.42:8492?token=482910
```

### Parameters
| Parameter | Type | Required | Description |
|---|---|---|---|
| `HOST` | String | Yes | IPv4 address of the Mac companion |
| `PORT` | Integer | Yes | Listening HTTP port (default `8492`) |
| `token` | String | Yes | 6-digit numeric pairing token |

---

## 3. HTTP Endpoints

All requests must be sent over HTTP to `http://<HOST>:<PORT>`.

### `GET /ping`
Checks connectivity and returns host metadata.
- **Authentication**: Optional
- **Response**: `200 OK`
```json
{
  "status": "ok",
  "deviceName": "Ankit's MacBook Pro"
}
```

### `POST /pair`
Registers the mobile device name with the Mac companion and establishes paired state.
- **Authentication**: Required (`X-Dock-Token: <token>`)
- **Body**:
```json
{
  "deviceName": "Google Pixel 8 Pro"
}
```
- **Response**: `200 OK`
```json
{
  "status": "paired",
  "macName": "Ankit's MacBook Pro"
}
```

### `POST /heartbeat`
Periodic heartbeat sent by the connected mobile device to update presence/online status.
- **Authentication**: Required (`X-Dock-Token: <token>`)
- **Body**:
```json
{
  "deviceName": "Google Pixel 8 Pro"
}
```
- **Response**: `200 OK`
```json
{
  "status": "ok",
  "paired": true,
  "macName": "Ankit's MacBook Pro"
}
```
- **Error Response**: `401 Unauthorized` if the device has been unpaired on the Mac.

### `POST /unpair`
Explicitly unpairs the device, invalidating the pairing token and resetting Mac companion state.
- **Authentication**: Required (`X-Dock-Token: <token>`)
- **Response**: `200 OK`
```json
{
  "status": "unpaired"
}
```

### `GET /apps`
Lists installed macOS applications available in `/Applications` and `~/Applications`.
- **Authentication**: Required (`X-Dock-Token: <token>`)
- **Response**: `200 OK`
```json
[
  {
    "name": "Visual Studio Code",
    "path": "/Applications/Visual Studio Code.app",
    "bundleId": "com.microsoft.VSCode"
  }
]
```

### `GET /icon?path=<urlencoded_path>`
Fetches the 256x256 PNG application icon.
- **Authentication**: Required (`X-Dock-Token: <token>`)
- **Response**: `200 OK (image/png)`

### `POST /launch`
Launches or activates a Mac application.
- **Authentication**: Required (`X-Dock-Token: <token>`)
- **Body**:
```json
{
  "path": "/Applications/Visual Studio Code.app"
}
```
- **Response**: `200 OK`
```json
{
  "status": "launched",
  "name": "Visual Studio Code"
}
```
