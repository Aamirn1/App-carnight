#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
command -v flutter >/dev/null || { echo 'BLOCKED: Flutter SDK is not installed.' >&2; exit 2; }
command -v dart >/dev/null || { echo 'BLOCKED: Dart SDK is not on PATH.' >&2; exit 2; }
flutter --version
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
