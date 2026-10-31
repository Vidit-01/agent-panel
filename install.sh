#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
DEST="$HOME/.local/share/plasma/plasmoids/com.vidit.agentpanel"
mkdir -p "$(dirname "$DEST")"
rm -rf "$DEST"
cp -R "$ROOT/package" "$DEST"

# Remove the experimental standalone build and launcher.
rm -rf "$HOME/.local/share/agent-panel"
rm -f "$HOME/.local/bin/agent-panel" "${XDG_DATA_HOME:-$HOME/.local/share}/applications/agent-panel.desktop"
printf 'Installed Agent Panel Plasma widget. Add it from the Plasma widget chooser.\n'
