#!/bin/zsh
set -u

HERE="${0:A:h}"
printf '\033]0;Magic Keyboard Remap — UNINSTALL\007'
clear

finish() {
    echo
    echo "Нажмите Enter, чтобы закрыть это окно."
    read -r
}
trap finish EXIT

echo "Удаление Magic Keyboard F4/лупа → Launchpad"
echo "==========================================="
echo
echo "Будет удалён только этот remap и его LaunchAgent."
echo "Другие переназначения клавиатуры не затрагиваются."
echo

printf "Продолжить? [y/N]: "
read -r answer

case "$answer" in
    y|Y|yes|YES|Yes) ;;
    *)
        echo "Отменено."
        exit 0
        ;;
esac

if ! /bin/zsh "$HERE/uninstall.sh"; then
    echo
    echo "ОШИБКА: удаление не завершено."
    exit 1
fi

echo
echo "ГОТОВО. Remap удалён."
