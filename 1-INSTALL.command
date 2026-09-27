#!/bin/zsh
set -u

HERE="${0:A:h}"
printf '\033]0;Magic Keyboard Remap — INSTALL\007'
clear

finish() {
    echo
    echo "Нажмите Enter, чтобы закрыть это окно."
    read -r
}
trap finish EXIT

echo "Magic Keyboard F4/лупа → Launchpad"
echo "=================================="
echo

cd "$HERE" || exit 1

if [[ -f SHA256SUMS.txt ]]; then
    echo "Проверяю целостность пакета..."
    if ! /usr/bin/shasum -a 256 -c SHA256SUMS.txt; then
        echo
        echo "ОШИБКА: проверка SHA-256 не пройдена. Установка отменена."
        exit 1
    fi
    echo
fi

echo "Устанавливаю..."
if ! /bin/zsh "$HERE/install.sh"; then
    echo
    echo "ОШИБКА: установка не завершена."
    exit 1
fi

echo
echo "ГОТОВО."
echo "F4 с лупой на внешней Magic Keyboard должна запускать Launchpad."
echo "При следующем Bluetooth-подключении mapping восстановится автоматически."
