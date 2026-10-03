MAGIC KEYBOARD — F4/ЛУПА → LAUNCHPAD — v2

Для установки:
  1. Распакуйте ZIP.
  2. Дважды щёлкните 1-INSTALL.command.
  3. После сообщения "ГОТОВО" запустите 2-CHECK.command.

Для проверки:
  Дважды щёлкните 2-CHECK.command.

Для полного удаления:
  Дважды щёлкните 3-UNINSTALL.command.

ПОСТОЯННЫЕ ФАЙЛЫ
  ~/bin/magic-keyboard-keymap
  ~/Library/LaunchAgents/com.landco.magic-keyboard-keymap.login.plist
  ~/Library/LaunchAgents/com.landco.magic-keyboard-keymap.attach.plist

АРХИТЕКТУРА
  1. login-agent:
     RunAtLoad один раз при входе в Aqua-сессию.
     Вызывает magic-keyboard-keymap --apply-if-present и завершается.

  2. attach-agent:
     launchd LaunchEvents -> com.apple.iokit.matching.
     Срабатывает при появлении целевой Magic Keyboard.
     Helper принимает XPC event, применяет mapping, проверяет его read-back и завершается.

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
  - после записи mapping немедленно читается обратно; ложный success не принимается;
  - при uninstall снимается только управляемый F4 mapping.

ЗАМЕЧАНИЕ
  UserKeyMapping в macOS является временным свойством активного HID service.
  Поэтому v2 закрывает два независимых lifecycle-события:
  - login/reboot -> login-agent;
  - создание/пересоздание Bluetooth HID service -> attach-agent.

Если Gatekeeper блокирует первый запуск .command:
  Finder -> Control-клик -> Открыть -> Открыть.
