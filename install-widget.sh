#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
DEST="$HOME/.local/share/plasma/plasmoids/com.vidit.agentpanel"
mkdir -p "$(dirname "$DEST")"
rm -rf "$DEST"
cp -R "$ROOT/package" "$DEST"
printf 'Installed Agent Panel Plasma widget. Add it from the Plasma widget chooser.\n'
