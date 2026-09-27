#!/bin/zsh
set -euo pipefail

HERE="${0:A:h}"
BIN_SRC="$HERE/magic-keyboard-keymap"
BIN_DST="$HOME/bin/magic-keyboard-keymap"
AGENT_SRC="$HERE/com.landco.magic-keyboard-keymap.plist"
AGENT_DST="$HOME/Library/LaunchAgents/com.landco.magic-keyboard-keymap.plist"
DOMAIN="gui/$(id -u)"
LABEL="com.landco.magic-keyboard-keymap"

[[ -f "$BIN_SRC" ]] || { echo "ОШИБКА: рядом нет magic-keyboard-keymap"; exit 1; }
[[ -f "$AGENT_SRC" ]] || { echo "ОШИБКА: рядом нет plist"; exit 1; }

/usr/bin/plutil -lint "$AGENT_SRC" >/dev/null

mkdir -p "$HOME/bin" "$HOME/Library/LaunchAgents"

/bin/launchctl bootout "$DOMAIN/$LABEL" 2>/dev/null || true

/bin/cp -f "$BIN_SRC" "$BIN_DST"
/bin/chmod 755 "$BIN_DST"
/usr/bin/xattr -d com.apple.quarantine "$BIN_DST" 2>/dev/null || true

/bin/cp -f "$AGENT_SRC" "$AGENT_DST"
/usr/bin/plutil -lint "$AGENT_DST"

/bin/launchctl bootstrap "$DOMAIN" "$AGENT_DST"

if "$BIN_DST" --apply-now; then
    echo "Текущая подключённая Magic Keyboard переназначена."
else
    echo "Magic Keyboard сейчас не найдена; mapping применится при её подключении."
fi

echo
echo "Установлено:"
echo "  F4/лупа -> Launchpad только на Magic Keyboard 0x004C:0x029C"
echo "  Нет StartInterval, KeepAlive или polling."
