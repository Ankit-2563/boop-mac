# Security Model — Boop

## Overview

Boop runs a lightweight HTTP server on your Mac that your Android phone connects to over the local WiFi network. This document explains the security measures in place and the threat model.

## Architecture

```
Phone  ──── WiFi (HTTP) ────►  Mac (port 8492)
              LAN only           │
                                 ├─ /ping   (no auth)
                                 ├─ /apps   (token required)
                                 ├─ /icon   (token required)
                                 └─ /launch (token required)
```

## Security Measures

### 1. Pairing Token

- All sensitive endpoints require a 6-digit pairing token sent in the `X-Dock-Token` HTTP header.
- The token is displayed in the Mac's menu bar and entered manually on the phone.
- The token persists across app restarts and can be regenerated at any time from the Mac's menu.

### 2. Path Validation

The `/launch` and `/icon` endpoints validate that requested paths:
- Are inside `/Applications`, `/System/Applications`, or `~/Applications`
- End with `.app`
- Do not contain path traversal sequences (`/../`, `/./`)

This prevents an attacker with a stolen token from using the launch endpoint to execute arbitrary files.

### 3. Rate Limiting

All endpoints are rate-limited to 60 requests per minute. This prevents brute-forcing the pairing token and denial-of-service attacks.

### 4. Local Network Only

The HTTP server binds to the local network interface. It is not accessible from the internet unless the user has explicitly configured port forwarding (which we strongly advise against).

## Known Limitations

### HTTP (not HTTPS)

Boop currently uses plain HTTP. On a shared WiFi network, the pairing token could theoretically be intercepted via packet sniffing. Mitigations:
- The token is only useful on the local network
- Regenerate the token if you suspect it's been compromised
- On trusted home networks, the risk is minimal

**Future improvement**: Self-signed TLS certificate generated on first launch, with certificate pinning in the mobile app.

### 6-Digit Token Space

The pairing token is a 6-digit number (1,000,000 possible values). With rate limiting (60/min), brute-forcing would take ~11.5 days on average. For most home network use cases, this is sufficient.

**Future improvement**: Switch to a longer alphanumeric token or a challenge-response pairing flow.

## Reporting Security Issues

If you discover a security vulnerability, please **do not** open a public issue. Instead, email the maintainer directly. We will respond within 48 hours and work on a fix before public disclosure.

## Recommendations for Users

1. **Use on trusted networks only** — home WiFi, not public coffee shop WiFi
2. **Regenerate the pairing code** if you suspect someone on your network may have intercepted it
3. **Keep Boop updated** — security fixes will be released as they're identified
4. **Do not port-forward port 8492** — Boop is designed for local network use only
