#!/bin/zsh
set -u

printf '\033]0;Magic Keyboard Remap — CHECK\007'
clear

BIN="$HOME/bin/magic-keyboard-keymap"
AGENT="$HOME/Library/LaunchAgents/com.landco.magic-keyboard-keymap.plist"
LABEL="com.landco.magic-keyboard-keymap"
DOMAIN="gui/$(id -u)"

echo "Magic Keyboard Remap — проверка"
echo "==============================="
echo

if [[ -x "$BIN" ]]; then
    echo "✓ Бинарник установлен: $BIN"
else
    echo "✗ Бинарник не найден: $BIN"
fi

if [[ -f "$AGENT" ]]; then
    echo "✓ LaunchAgent установлен: $AGENT"
else
    echo "✗ LaunchAgent не найден: $AGENT"
fi

echo
echo "launchd:"
if /bin/launchctl print "$DOMAIN/$LABEL" >/tmp/magic-keyboard-remap-launchd.$$ 2>&1; then
    /usr/bin/grep -E 'state =|path =|program =|runs =|last exit code =' /tmp/magic-keyboard-remap-launchd.$$ || true
else
    echo "  служба сейчас не зарегистрирована"
fi
/bin/rm -f /tmp/magic-keyboard-remap-launchd.$$

echo
echo "Текущий UserKeyMapping внешней Magic Keyboard:"
/usr/bin/hidutil property \
  --matching '{"VendorID":0x004C,"ProductID":0x029C}' \
  --get "UserKeyMapping" 2>&1 || true

echo
echo "Ожидаемая запись:"
echo "  Search/F4 0xC00000221 → Launchpad 0xC000002A2"
echo
echo "Нажмите Enter, чтобы закрыть это окно."
read -r
