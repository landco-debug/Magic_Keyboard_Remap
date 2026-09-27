#!/bin/zsh
set -euo pipefail

BIN="$HOME/bin/magic-keyboard-keymap"
AGENT="$HOME/Library/LaunchAgents/com.landco.magic-keyboard-keymap.plist"
DOMAIN="gui/$(id -u)"
LABEL="com.landco.magic-keyboard-keymap"

/bin/launchctl bootout "$DOMAIN/$LABEL" 2>/dev/null || true

# Remove only our Search/F4 mapping and preserve any unrelated UserKeyMapping entries.
if [[ -x "$BIN" ]]; then
    "$BIN" --remove-now 2>/dev/null || true
fi

/bin/rm -f "$AGENT" "$BIN"

echo "Удалено. Другие remap-записи Magic Keyboard не изменялись."
