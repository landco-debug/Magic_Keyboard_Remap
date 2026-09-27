ВСТРОЕННАЯ КЛАВИАТУРА — НАТИВНЫЙ EVENT-DRIVEN REMAP

Назначения:
  F4 / лупа      -> Launchpad
  полумесяц / F6 -> F18

Установка:
  дважды щёлкните 1-INSTALL-INTERNAL.command

Проверка:
  дважды щёлкните 2-CHECK-INTERNAL.command

Откат:
  дважды щёлкните 3-UNINSTALL-INTERNAL.command

Что меняется:
  - старый ~/Library/LaunchAgents/com.landco.hid-keymap.plist
    сохраняется как резервная копия и отключается;
  - устанавливается ~/bin/internal-keyboard-keymap;
  - устанавливается event-driven LaunchAgent
    ~/Library/LaunchAgents/com.landco.internal-keyboard-keymap.plist.

Точный target:
  Product: Apple Internal Keyboard / Trackpad
  VendorID: 0x05AC
  ProductID: 0x0281
  Transport: SPI
  PrimaryUsagePage: 1
  PrimaryUsage: 6

Архитектура:
  launchd LaunchEvents -> com.apple.iokit.matching -> XPC -> IOKit
  Никакого polling, StartInterval или KeepAlive.
  Helper не остаётся постоянно в памяти.

Безопасность:
  - прошивка клавиатуры не меняется;
  - helper проверяет точную идентичность встроенной клавиатуры;
  - сохраняются любые посторонние UserKeyMapping;
  - helper управляет только двумя известными source-кодами;
  - откат восстанавливает прежнюю схему, если она была.
