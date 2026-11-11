#!/usr/bin/env bash
set -euo pipefail
KIT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
TRAIN_ROOT=${TRAIN_ROOT:-"$HOME/training"}
if [ -e "$TRAIN_ROOT" ]; then
  echo "Refusing to overwrite $TRAIN_ROOT. Use a fresh VM or a new TRAIN_ROOT." >&2
  exit 1
fi
mkdir -p "$TRAIN_ROOT/seed"
cp -a "$KIT_DIR/." "$TRAIN_ROOT/seed/"
cd "$TRAIN_ROOT/seed"
git init -b main
git config user.name 'Training Instructor'
git config user.email 'instructor@example.invalid'
git add .
git commit -m 'Initial training release'
git tag -a v1.0.0 -m 'Training release 1.0.0'
printf '1.1.0\n' > VERSION
git add VERSION
git commit -m 'Release version 1.1.0'
git tag -a v1.1.0 -m 'Training release 1.1.0'
git clone --bare . "$TRAIN_ROOT/origin.git"
git clone "$TRAIN_ROOT/origin.git" "$TRAIN_ROOT/ops-notes"
git -C "$TRAIN_ROOT/ops-notes" config user.name 'Student'
git -C "$TRAIN_ROOT/ops-notes" config user.email 'student@example.invalid'
echo "Ready: $TRAIN_ROOT/ops-notes"
