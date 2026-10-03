#!/bin/zsh
set -euo pipefail

HERE="${0:A:h}"

BIN_SRC="$HERE/magic-keyboard-keymap"
BIN_DST="$HOME/bin/magic-keyboard-keymap"
LOGIN_BIN="$HOME/bin/Magic Keyboard — Login"
RECONNECT_BIN="$HOME/bin/Magic Keyboard — Reconnect"

ATTACH_SRC="$HERE/com.landco.magic-keyboard-keymap.attach.plist"
ATTACH_DST="$HOME/Library/LaunchAgents/com.landco.magic-keyboard-keymap.attach.plist"

LOGIN_SRC="$HERE/com.landco.magic-keyboard-keymap.login.plist"
LOGIN_DST="$HOME/Library/LaunchAgents/com.landco.magic-keyboard-keymap.login.plist"

OLD_AGENT="$HOME/Library/LaunchAgents/com.landco.magic-keyboard-keymap.plist"

DOMAIN="gui/$(id -u)"
OLD_LABEL="com.landco.magic-keyboard-keymap"
ATTACH_LABEL="com.landco.magic-keyboard-keymap.attach"
LOGIN_LABEL="com.landco.magic-keyboard-keymap.login"

[[ -f "$BIN_SRC" ]] || { echo "ОШИБКА: рядом нет magic-keyboard-keymap"; exit 1; }
[[ -f "$ATTACH_SRC" ]] || { echo "ОШИБКА: рядом нет attach plist"; exit 1; }
[[ -f "$LOGIN_SRC" ]] || { echo "ОШИБКА: рядом нет login plist"; exit 1; }

/usr/bin/plutil -lint "$ATTACH_SRC" >/dev/null
/usr/bin/plutil -lint "$LOGIN_SRC" >/dev/null
"$BIN_SRC" --version

mkdir -p "$HOME/bin" "$HOME/Library/LaunchAgents"

/bin/launchctl bootout "$DOMAIN/$OLD_LABEL" 2>/dev/null || true
/bin/launchctl bootout "$DOMAIN/$ATTACH_LABEL" 2>/dev/null || true
/bin/launchctl bootout "$DOMAIN/$LOGIN_LABEL" 2>/dev/null || true

/bin/rm -f "$OLD_AGENT" "$LOGIN_BIN" "$RECONNECT_BIN"

/bin/cp -f "$BIN_SRC" "$BIN_DST"
/bin/chmod 755 "$BIN_DST"
/usr/bin/xattr -d com.apple.quarantine "$BIN_DST" 2>/dev/null || true

# Two hard links to the same binary. They use no extra binary copy, but give
# macOS distinct executable names for Login Items & Extensions.
/bin/ln "$BIN_DST" "$LOGIN_BIN"
/bin/ln "$BIN_DST" "$RECONNECT_BIN"

/bin/cp -f "$ATTACH_SRC" "$ATTACH_DST"
/bin/cp -f "$LOGIN_SRC" "$LOGIN_DST"

/usr/bin/plutil -lint "$ATTACH_DST" >/dev/null
/usr/bin/plutil -lint "$LOGIN_DST" >/dev/null

/bin/launchctl bootstrap "$DOMAIN" "$ATTACH_DST"
/bin/launchctl bootstrap "$DOMAIN" "$LOGIN_DST"

"$BIN_DST" --apply-if-present

if "$BIN_DST" --check; then
    echo "Текущая Magic Keyboard: F4/лупа -> Launchpad подтверждено read-back проверкой."
else
    echo "Magic Keyboard сейчас не найдена или не подключена."
    echo "При появлении клавиатуры attach-agent применит mapping автоматически."
fi

echo
echo "Установлена архитектура v2.1:"
echo "  Magic Keyboard — Login      -> один запуск при входе в Aqua-сессию"
echo "  Magic Keyboard — Reconnect  -> IOKit LaunchEvents при подключении"
echo "  Оба имени ведут на один и тот же бинарник через hard link"
echo "  KeepAlive / StartInterval / polling отсутствуют"
