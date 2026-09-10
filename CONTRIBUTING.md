# Contributing to Boop Mac

Thanks for your interest! Here's how to get started.

## Development Setup

1. Open the Xcode project
2. Add Swifter package dependency
3. Build & Run (⌘R)

## Architecture

- `AppDelegate.swift` — Menu bar UI, Bonjour advertisement, pairing token
- `HTTPServer.swift` — Local HTTP API (Swifter-based)
- `AppScanner.swift` — Finds installed apps, renders icons, launches apps

## Code Style
- Follow standard Swift naming conventions
- Use `// MARK: -` for code sections
- Keep functions focused and small

## Pull Requests
1. Fork → branch from `main`
2. Make changes and test locally
3. Open a PR with a clear description
