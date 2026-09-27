#!/bin/zsh
set -euo pipefail

BIN="$HOME/bin/internal-keyboard-keymap"
AGENT="$HOME/Library/LaunchAgents/com.landco.internal-keyboard-keymap.plist"

NEW_LABEL="com.landco.internal-keyboard-keymap"
OLD_LABEL="com.landco.hid-keymap"
OLD_AGENT="$HOME/Library/LaunchAgents/com.landco.hid-keymap.plist"

BACKUP_DIR="$HOME/Library/Application Support/InternalKeyboardRemap"
OLD_BACKUP="$BACKUP_DIR/legacy-com.landco.hid-keymap.plist"

DOMAIN="gui/$(id -u)"

/bin/launchctl bootout "$DOMAIN/$NEW_LABEL" 2>/dev/null || true

# Remove only the two mappings managed by the new helper.
if [[ -x "$BIN" ]]; then
    "$BIN" --remove-now 2>/dev/null || true
fi

/bin/rm -f "$AGENT" "$BIN"

# If this package replaced the user's previous working RunAtLoad/hidutil agent,
# restore that exact plist and load it again.
if [[ -f "$OLD_BACKUP" ]]; then
    /bin/cp -f "$OLD_BACKUP" "$OLD_AGENT"
    /usr/bin/plutil -lint "$OLD_AGENT" >/dev/null
    /bin/launchctl bootout "$DOMAIN/$OLD_LABEL" 2>/dev/null || true
    /bin/launchctl bootstrap "$DOMAIN" "$OLD_AGENT"
    echo "Новая схема удалена; прежний com.landco.hid-keymap восстановлен."
else
    echo "Новая схема удалена; управляемые remap-записи сняты."
fi
