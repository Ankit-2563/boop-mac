#!/usr/bin/env bash
set -euo pipefail

# Build standalone Boop.app bundle using Swift Package Manager
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
DIST_DIR="${REPO_DIR}/dist"
APP_DIR="${DIST_DIR}/Boop.app"

echo "==> Building Boop binary in release mode..."
cd "${REPO_DIR}"
swift build -c release --build-system native

echo "==> Packaging into ${APP_DIR}..."
rm -rf "${APP_DIR}"
mkdir -p "${APP_DIR}/Contents/MacOS"
mkdir -p "${APP_DIR}/Contents/Resources"

cp "${REPO_DIR}/.build/arm64-apple-macosx/release/Boop" "${APP_DIR}/Contents/MacOS/Boop"
cp "${REPO_DIR}/Boop/Info.plist" "${APP_DIR}/Contents/Info.plist"

echo "==> Boop.app successfully created at: ${APP_DIR}"
