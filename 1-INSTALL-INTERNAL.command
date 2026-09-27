#!/bin/zsh
set -u

HERE="${0:A:h}"
printf '\033]0;Internal Keyboard Remap — INSTALL\007'
clear

finish() {
    echo
    echo "Нажмите Enter, чтобы закрыть это окно."
    read -r
}
trap finish EXIT

echo "Встроенная клавиатура: F4→Launchpad, полумесяц→F18"
echo "=================================================="
echo

cd "$HERE" || exit 1

if [[ -f SHA256SUMS.txt ]]; then
    echo "Проверяю целостность пакета..."
    if ! /usr/bin/shasum -a 256 -c SHA256SUMS.txt; then
        echo
        echo "ОШИБКА: SHA-256 не совпадает. Установка отменена."
        exit 1
    fi
    echo
fi

echo "Мигрирую со старой RunAtLoad/hidutil схемы на LaunchEvents/IOKit..."
if ! /bin/zsh "$HERE/install-internal.sh"; then
    echo
    echo "ОШИБКА: установка не завершена."
    exit 1
fi

echo
echo "ГОТОВО."
echo "Старый com.landco.hid-keymap отключён и сохранён для отката."
echo "Новый helper запускается только по IOKit-событию и сразу завершает работу."
