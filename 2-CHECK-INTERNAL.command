#!/bin/zsh
set -u

printf '\033]0;Internal Keyboard Remap — CHECK\007'
clear

BIN="$HOME/bin/internal-keyboard-keymap"
AGENT="$HOME/Library/LaunchAgents/com.landco.internal-keyboard-keymap.plist"
NEW_LABEL="com.landco.internal-keyboard-keymap"
OLD_AGENT="$HOME/Library/LaunchAgents/com.landco.hid-keymap.plist"
DOMAIN="gui/$(id -u)"

echo "Internal Keyboard Remap — проверка"
echo "=================================="
echo

[[ -x "$BIN" ]] && echo "✓ Бинарник: $BIN" || echo "✗ Бинарник не найден"
[[ -f "$AGENT" ]] && echo "✓ LaunchAgent: $AGENT" || echo "✗ LaunchAgent не найден"
[[ ! -f "$OLD_AGENT" ]] && echo "✓ Старый RunAtLoad agent отключён" || echo "⚠ Старый com.landco.hid-keymap всё ещё существует"

echo
echo "launchd:"
TMP="/tmp/internal-keyboard-remap-launchd.$$"
if /bin/launchctl print "$DOMAIN/$NEW_LABEL" >"$TMP" 2>&1; then
    /usr/bin/grep -E 'state =|path =|program =|runs =|last exit code =' "$TMP" || true
else
    echo "  служба не зарегистрирована"
fi
/bin/rm -f "$TMP"

echo
echo "Текущий UserKeyMapping встроенной клавиатуры:"
/usr/bin/hidutil property \
  --matching '{"VendorID":0x05AC,"ProductID":0x0281}' \
  --get "UserKeyMapping" 2>&1 || true

echo
echo "Ожидаются две записи:"
echo "  Search/F4  0xC00000221 → Launchpad 0xC000002A2"
echo "  Moon/F6    0x10000009B → F18       0x70000006D"

echo
echo "Нажмите Enter, чтобы закрыть это окно."
read -r
