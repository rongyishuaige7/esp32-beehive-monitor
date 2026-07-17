#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PYTHONPYCACHEPREFIX="$(mktemp -d)"; export PYTHONPYCACHEPREFIX
PIO_WORK_DIR="$(mktemp -d)"
FLUTTER_GENERATED_PATHS=(
  "$ROOT/app/.dart_tool" "$ROOT/app/.flutter-plugins" "$ROOT/app/.flutter-plugins-dependencies"
  "$ROOT/app/build" "$ROOT/app/android/.gradle" "$ROOT/app/android/local.properties"
  "$ROOT/app/ios/Flutter/Generated.xcconfig" "$ROOT/app/ios/Flutter/flutter_export_environment.sh"
  "$ROOT/app/ios/Flutter/ephemeral" "$ROOT/app/ios/Flutter/.last_build_id"
)
cleanup() {
  rm -rf -- "$PYTHONPYCACHEPREFIX" "$PIO_WORK_DIR" "$ROOT/tests/__pycache__" "${FLUTTER_GENERATED_PATHS[@]}"
}
trap cleanup EXIT

python3 "$ROOT/scripts/secret_scan.py" --root "$ROOT"
python3 "$ROOT/scripts/check_repo.py" --root "$ROOT"
python3 -m unittest discover -s "$ROOT/tests" -p 'test_*.py' -v

rsync -a --delete --exclude='.git/' --exclude='.pio/' "$ROOT/firmware/" "$PIO_WORK_DIR/"
pio run -d "$PIO_WORK_DIR" -e esp32dev
(
  cd "$ROOT/app"
  flutter pub get --enforce-lockfile
  dart format --output=none --set-exit-if-changed lib test
  flutter test
  flutter analyze
  flutter build apk --debug
)

cleanup
trap - EXIT
python3 "$ROOT/scripts/secret_scan.py" --root "$ROOT"
python3 "$ROOT/scripts/check_repo.py" --root "$ROOT"
echo 'Verification: PASS'
