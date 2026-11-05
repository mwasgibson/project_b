#!/usr/bin/env bash
# One-time setup. Run from anywhere: ./tool/bootstrap.sh
# Optional: ORG=com.yourname.projectb ./tool/bootstrap.sh
# Decide the org BEFORE publishing; Android package ids are hard to change later.
set -euo pipefail
cd "$(dirname "$0")/.."

command -v fvm >/dev/null 2>&1 || {
  echo "FVM is required to use this project's pinned Flutter 3.38.10 SDK."
  echo "Install FVM (https://fvm.app/documentation/getting-started/installation), then rerun this script."
  exit 1
}

echo "Installing the project-pinned Flutter SDK..."
fvm install

ORG="${ORG:-com.example.projectb}"

if [ ! -d android ] || [ ! -d ios ]; then
  echo "Generating android/ and ios/ platform folders (org: $ORG)..."
  tmp="$(mktemp -d)"
  fvm flutter create --org "$ORG" --project-name project_b --platforms=android,ios "$tmp/project_b"
  cp -R "$tmp/project_b/android" ./android
  cp -R "$tmp/project_b/ios" ./ios
  [ -f .metadata ] || cp "$tmp/project_b/.metadata" ./.metadata
  rm -rf "$tmp"
fi

echo "Resolving packages declared in pubspec.yaml..."
fvm flutter pub get

echo "Generating Drift code..."
fvm dart run build_runner build --force-jit

echo "Analyzing..."
fvm flutter analyze

echo "Testing..."
fvm flutter test

echo "Done. Run the app with: fvm flutter run"
