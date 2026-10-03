MAGIC KEYBOARD — F4/ЛУПА → LAUNCHPAD — v2.1

Для установки:
  1. Распакуйте ZIP.
  2. Дважды щёлкните 1-INSTALL.command.
  3. После сообщения "ГОТОВО" запустите 2-CHECK.command.

Для проверки:
  Дважды щёлкните 2-CHECK.command.

Для полного удаления:
  Дважды щёлкните 3-UNINSTALL.command.

ЧТО ВИДНО В «ОБЪЕКТЫ ВХОДА И РАСШИРЕНИЯ»
  Magic Keyboard — Login
  Magic Keyboard — Reconnect

Это НЕ две копии программы.
Оба имени — hard links одного и того же бинарника:
  ~/bin/magic-keyboard-keymap

Они имеют один inode и не занимают дважды место на диске.

ПОСТОЯННЫЕ ФАЙЛЫ
  ~/bin/magic-keyboard-keymap
  ~/bin/Magic Keyboard — Login
  ~/bin/Magic Keyboard — Reconnect
  ~/Library/LaunchAgents/com.landco.magic-keyboard-keymap.login.plist
  ~/Library/LaunchAgents/com.landco.magic-keyboard-keymap.attach.plist

АРХИТЕКТУРА
  1. Magic Keyboard — Login
     RunAtLoad один раз при входе в Aqua-сессию.
     Вызывает helper с --apply-if-present и завершается.

  2. Magic Keyboard — Reconnect
     launchd LaunchEvents -> com.apple.iokit.matching.
     Срабатывает при появлении целевой Magic Keyboard.
     Helper принимает XPC event, применяет mapping, проверяет read-back и завершается.

  Нет KeepAlive.
  Нет StartInterval.
  Нет периодического polling.
  Нет постоянного процесса.

ТОЧНЫЙ TARGET
  Product: Magic Keyboard
  VendorID: 0x004C
  ProductID: 0x029C
  Transport: Bluetooth
  PrimaryUsagePage: 1
  PrimaryUsage: 6

MAPPING
  Search/F4 0xC00000221 -> Launchpad 0xC000002A2

БЕЗОПАСНОСТЬ
  - не используется Accessibility;
  - не используется Input Monitoring;
  - нет CGEventTap и глобального перехвата клавиатуры;
  - прошивка Magic Keyboard не изменяется;
  - системные файлы macOS не изменяются;
  - helper работает от обычного пользователя, без root;
  - перед записью повторно проверяется точная идентичность клавиатуры;
  - сохраняются все посторонние UserKeyMapping;
  - изменяется только mapping с source Search/F4;
  - после записи mapping немедленно читается обратно;
  - при uninstall снимается только управляемый F4 mapping.

Если Gatekeeper блокирует первый запуск .command:
  Finder -> Control-клик -> Открыть -> Открыть.
