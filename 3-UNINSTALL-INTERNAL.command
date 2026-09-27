#!/bin/zsh
set -u

HERE="${0:A:h}"
printf '\033]0;Internal Keyboard Remap — ROLLBACK\007'
clear

finish() {
    echo
    echo "Нажмите Enter, чтобы закрыть это окно."
    read -r
}
trap finish EXIT

echo "Удаление новой событийной схемы"
echo "==============================="
echo
echo "Если при установке был найден старый com.landco.hid-keymap,"
echo "он будет автоматически восстановлен."
echo
printf "Продолжить? [y/N]: "
read -r answer

case "$answer" in
    y|Y|yes|YES|Yes) ;;
    *) echo "Отменено."; exit 0 ;;
esac

if ! /bin/zsh "$HERE/uninstall-internal.sh"; then
    echo
    echo "ОШИБКА: откат не завершён."
    exit 1
fi

echo
echo "ГОТОВО."
