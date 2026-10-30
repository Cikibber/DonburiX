#!/usr/bin/env bash
# Runs the DonburiX mobile quality gates.
# Agent sessions in this workspace have no shell tool; run this from a normal terminal.

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root/apps/mobile"

flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --coverage
