#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
command -v flutter >/dev/null || { echo 'Flutter SDK is required.' >&2; exit 2; }
if [[ ! -d android ]]; then
  host_dir="$(mktemp -d)"
  trap 'rm -rf "$host_dir"' EXIT
  flutter create --no-pub --platforms=android --project-name=cars_night \
    --org=com.carsnight.preview "$host_dir/cars_night"
  cp -R "$host_dir/cars_night/android" android
fi
python3 - <<'PY'
from pathlib import Path
manifest = Path('android/app/src/main/AndroidManifest.xml')
text = manifest.read_text().replace('android:label="cars_night"', 'android:label="Cars Night"')
manifest.write_text(text)
PY
