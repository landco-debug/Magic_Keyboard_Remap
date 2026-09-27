MAGIC KEYBOARD — F4/ЛУПА → LAUNCHPAD

Для установки:
  1. Распакуйте ZIP.
  2. Дважды щёлкните 1-INSTALL.command.
  3. После сообщения "ГОТОВО" нажмите F4 с лупой на внешней Magic Keyboard.

Для проверки:
  Дважды щёлкните 2-CHECK.command.

Для полного удаления:
  Дважды щёлкните 3-UNINSTALL.command.

После установки для работы нужны только:
  ~/bin/magic-keyboard-keymap
  ~/Library/LaunchAgents/com.landco.magic-keyboard-keymap.plist

Остальную распакованную папку можно удалить.

Как работает:
  - только внешняя Magic Keyboard 0x004C:0x029C;
  - F4/Search переназначается на Launchpad;
  - подключение отслеживается штатным launchd/IOKit событием;
  - нет polling, StartInterval или KeepAlive;
  - helper не висит постоянно в памяти;
  - прошивка клавиатуры не изменяется;
  - другие UserKeyMapping сохраняются.

Если macOS блокирует первый запуск .command после загрузки из Интернета:
  Finder → Control-клик по нужному .command → Открыть → Открыть.
Это стандартная защита Gatekeeper для загруженных исполняемых файлов.
