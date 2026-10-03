#!/bin/zsh
set -u

printf '\033]0;Magic Keyboard Remap v2 — CHECK\007'
clear

BIN="$HOME/bin/magic-keyboard-keymap"
OLD_AGENT="$HOME/Library/LaunchAgents/com.landco.magic-keyboard-keymap.plist"
ATTACH_AGENT="$HOME/Library/LaunchAgents/com.landco.magic-keyboard-keymap.attach.plist"
LOGIN_AGENT="$HOME/Library/LaunchAgents/com.landco.magic-keyboard-keymap.login.plist"

DOMAIN="gui/$(id -u)"
ATTACH_LABEL="com.landco.magic-keyboard-keymap.attach"
LOGIN_LABEL="com.landco.magic-keyboard-keymap.login"

fail=0

echo "Magic Keyboard Remap v2 — проверка"
echo "==================================="
echo

if [[ -x "$BIN" ]]; then
    echo "✓ Бинарник установлен: $BIN"
    "$BIN" --version
else
    echo "✗ Бинарник не найден"
    fail=1
fi

if [[ -f "$ATTACH_AGENT" ]]; then
    echo "✓ Attach LaunchAgent установлен"
else
    echo "✗ Attach LaunchAgent не найден"
    fail=1
fi

if [[ -f "$LOGIN_AGENT" ]]; then
    echo "✓ Login LaunchAgent установлен"
else
    echo "✗ Login LaunchAgent не найден"
    fail=1
fi

if [[ -f "$OLD_AGENT" ]]; then
    echo "✗ Старый single-job LaunchAgent всё ещё существует"
    fail=1
else
    echo "✓ Старый single-job LaunchAgent отсутствует"
fi

echo
echo "===== LOGIN JOB ====="
LOGIN_TMP="/tmp/magic-keyboard-login.$$"
if /bin/launchctl print "$DOMAIN/$LOGIN_LABEL" >"$LOGIN_TMP" 2>&1; then
    /usr/bin/grep -E 'state =|path =|program =|runs =|last exit code =' "$LOGIN_TMP" || true
else
    echo "✗ login job не зарегистрирован"
    fail=1
fi
/bin/rm -f "$LOGIN_TMP"

echo
echo "===== ATTACH JOB ====="
ATTACH_TMP="/tmp/magic-keyboard-attach.$$"
if /bin/launchctl print "$DOMAIN/$ATTACH_LABEL" >"$ATTACH_TMP" 2>&1; then
    /usr/bin/grep -E 'state =|path =|program =|runs =|last exit code =|watching =|stream =|keepalive =' "$ATTACH_TMP" || true
    if ! /usr/bin/grep -q 'watching = 1' "$ATTACH_TMP"; then
        echo "✗ IOKit event channel не находится в watching=1"
        fail=1
    fi
else
    echo "✗ attach job не зарегистрирован"
    fail=1
fi
/bin/rm -f "$ATTACH_TMP"

echo
echo "===== CURRENT MAPPING ====="
if [[ -x "$BIN" ]] && "$BIN" --check; then
    echo "✓ Read-back: F4/Search -> Launchpad установлен на целевой Magic Keyboard"
else
    echo "⚠ Целевая Magic Keyboard сейчас не найдена либо mapping отсутствует"
fi

/usr/bin/hidutil property   --matching '{"VendorID":0x004C,"ProductID":0x029C}'   --get "UserKeyMapping" 2>&1 || true

echo
echo "===== RESIDENT PROCESS ====="
if /usr/bin/pgrep -alf 'magic-keyboard-keymap' >/dev/null 2>&1; then
    /usr/bin/pgrep -alf 'magic-keyboard-keymap'
    echo "⚠ Helper сейчас запущен (обычно это кратковременно во время события)."
else
    echo "✓ Helper не висит в памяти"
fi

echo
if [[ "$fail" -eq 0 ]]; then
    echo "ИТОГ: структура установки исправна."
else
    echo "ИТОГ: обнаружена ошибка установки."
fi

echo
echo "Нажмите Enter, чтобы закрыть это окно."
read -r
