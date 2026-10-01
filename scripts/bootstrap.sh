#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
command -v flutter >/dev/null || { echo 'Install Flutter first.' >&2; exit 1; }
if [[ -e android || -e ios ]]; then
  echo 'Native host directories already exist. No files changed.' >&2
  exit 1
fi
bootstrap_dir="$(mktemp -d)"
trap 'rm -rf "$bootstrap_dir"' EXIT
flutter create --platforms=android,ios --project-name=cars_night \
  --org=com.example "$bootstrap_dir/cars_night"
cp -R "$bootstrap_dir/cars_night/android" android
cp -R "$bootstrap_dir/cars_night/ios" ios
echo 'Native hosts created. Run flutter pub get, analyze and test.'
