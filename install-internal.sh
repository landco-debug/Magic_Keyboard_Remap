#!/bin/zsh
set -euo pipefail

HERE="${0:A:h}"

BIN_SRC="$HERE/internal-keyboard-keymap"
BIN_DST="$HOME/bin/internal-keyboard-keymap"

AGENT_SRC="$HERE/com.landco.internal-keyboard-keymap.plist"
AGENT_DST="$HOME/Library/LaunchAgents/com.landco.internal-keyboard-keymap.plist"

NEW_LABEL="com.landco.internal-keyboard-keymap"
OLD_LABEL="com.landco.hid-keymap"
OLD_AGENT="$HOME/Library/LaunchAgents/com.landco.hid-keymap.plist"

BACKUP_DIR="$HOME/Library/Application Support/InternalKeyboardRemap"
OLD_BACKUP="$BACKUP_DIR/legacy-com.landco.hid-keymap.plist"

DOMAIN="gui/$(id -u)"

[[ -f "$BIN_SRC" ]] || { echo "ОШИБКА: рядом нет internal-keyboard-keymap"; exit 1; }
[[ -f "$AGENT_SRC" ]] || { echo "ОШИБКА: рядом нет com.landco.internal-keyboard-keymap.plist"; exit 1; }

/usr/bin/plutil -lint "$AGENT_SRC" >/dev/null

mkdir -p "$HOME/bin" "$HOME/Library/LaunchAgents" "$BACKUP_DIR"

# Preserve the previous RunAtLoad/hidutil scheme exactly once for rollback.
if [[ -f "$OLD_AGENT" && ! -f "$OLD_BACKUP" ]]; then
    /bin/cp -p "$OLD_AGENT" "$OLD_BACKUP"
fi

# Prevent the legacy job from re-applying an old/cached mapping.
# This is especially important because launchd caches ProgramArguments for a loaded job.
/bin/launchctl bootout "$DOMAIN/$OLD_LABEL" 2>/dev/null || true
/bin/rm -f "$OLD_AGENT"

# Replace/update the new event-driven job cleanly.
/bin/launchctl bootout "$DOMAIN/$NEW_LABEL" 2>/dev/null || true

/bin/cp -f "$BIN_SRC" "$BIN_DST"
/bin/chmod 755 "$BIN_DST"
/usr/bin/xattr -d com.apple.quarantine "$BIN_DST" 2>/dev/null || true

/bin/cp -f "$AGENT_SRC" "$AGENT_DST"
/usr/bin/plutil -lint "$AGENT_DST" >/dev/null

/bin/launchctl bootstrap "$DOMAIN" "$AGENT_DST"

# Apply immediately to the currently present built-in keyboard.
"$BIN_DST" --apply-now

echo "Установлено:"
echo "  F4/лупа -> Launchpad"
echo "  полумесяц -> F18"
echo "  только Apple Internal Keyboard / Trackpad (0x05AC:0x0281, SPI)"
echo "  без polling / StartInterval / KeepAlive"
