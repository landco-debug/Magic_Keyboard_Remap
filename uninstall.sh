#!/bin/zsh
set -euo pipefail

BIN="$HOME/bin/magic-keyboard-keymap"
LOGIN_BIN="$HOME/bin/Magic Keyboard — Login"
RECONNECT_BIN="$HOME/bin/Magic Keyboard — Reconnect"

OLD_AGENT="$HOME/Library/LaunchAgents/com.landco.magic-keyboard-keymap.plist"
ATTACH_AGENT="$HOME/Library/LaunchAgents/com.landco.magic-keyboard-keymap.attach.plist"
LOGIN_AGENT="$HOME/Library/LaunchAgents/com.landco.magic-keyboard-keymap.login.plist"

DOMAIN="gui/$(id -u)"

for LABEL in     com.landco.magic-keyboard-keymap     com.landco.magic-keyboard-keymap.attach     com.landco.magic-keyboard-keymap.login
do
    /bin/launchctl bootout "$DOMAIN/$LABEL" 2>/dev/null || true
done

if [[ -x "$BIN" ]]; then
    "$BIN" --remove-now 2>/dev/null || true
fi

/bin/rm -f     "$OLD_AGENT"     "$ATTACH_AGENT"     "$LOGIN_AGENT"     "$LOGIN_BIN"     "$RECONNECT_BIN"     "$BIN"

echo "Удалено:"
echo "  magic-keyboard-keymap"
echo "  Magic Keyboard — Login"
echo "  Magic Keyboard — Reconnect"
echo "  оба LaunchAgent"
echo "Управляемый F4-remap снят; посторонние remap-записи не изменялись."
