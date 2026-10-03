# Magic Keyboard F4/Search → Launchpad v2

Native macOS remap for the user's external Apple Magic Keyboard.

## Exact target
- Product: `Magic Keyboard`
- IOProviderClass: `AppleHIDKeyboardEventDriverV2`
- VendorID: `76` / `0x004C`
- ProductID: `668` / `0x029C`
- Transport: `Bluetooth`
- PrimaryUsagePage: `1`
- PrimaryUsage: `6`

## Mapping
- source: `0xC00000221` — Search/F4
- destination: `0xC000002A2` — Launchpad

## Why v2 has two launchd jobs
Apple documents `UserKeyMapping` as volatile: remaps are lost when the system restarts or the keyboard service is removed.

v2 therefore handles the two lifecycle cases separately:

1. **Login restoration job**
   - `RunAtLoad=true`
   - Aqua session only
   - calls the helper with `--apply-if-present`
   - exits immediately
   - no `LaunchEvents`

2. **Keyboard attach job**
   - `LaunchEvents -> com.apple.iokit.matching`
   - consumes the XPC stream with `xpc_set_event_stream_handler`
   - applies the mapping when the target HID service appears
   - exits after handling the event

This separation keeps the launchd contracts unambiguous: the event job always checks into its advertised event stream; the login job never advertises one.

## Safety properties
- no Accessibility permission
- no Input Monitoring permission
- no CGEventTap
- no global keyboard interception
- no root
- no firmware writes
- no system-file modification
- no network access
- no `KeepAlive`
- no `StartInterval`
- no periodic polling
- helper is not resident between events
- full target identity is re-checked before every write
- all unrelated `UserKeyMapping` entries are preserved
- only the Search/F4 source entry is replaced or removed
- every write is read back and verified before success is reported

## Installation
Unpack the release ZIP and double-click:
- `1-INSTALL.command`
- `2-CHECK.command` to verify
- `3-UNINSTALL.command` to remove

Permanent files:
- `~/bin/magic-keyboard-keymap`
- `~/Library/LaunchAgents/com.landco.magic-keyboard-keymap.login.plist`
- `~/Library/LaunchAgents/com.landco.magic-keyboard-keymap.attach.plist`

The installer removes the previous single-job `com.landco.magic-keyboard-keymap.plist` so the old and new architectures cannot run together.
