# Magic Keyboard F4/Search → Launchpad

Native event-driven remap for the user's external Apple Magic Keyboard on macOS Sequoia.

## Exact target
- IOProviderClass: `AppleHIDKeyboardEventDriverV2`
- VendorID: `76` / `0x004C`
- ProductID: `668` / `0x029C`
- Transport: `Bluetooth`
- PrimaryUsagePage: `1`
- PrimaryUsage: `6`

## Mapping
- source: `0xC00000221` — Search/F4
- destination: `0xC000002A2` — Launchpad

## Design
- `launchd LaunchEvents`
- XPC stream `com.apple.iokit.matching`
- IOKit `IOHIDServiceClientSetProperty`
- no polling
- no `StartInterval`
- no `KeepAlive`
- no third-party libraries
- process exits after handling the attach event
- 5-second fail-safe timeout prevents it remaining resident if event delivery fails

## Safety
The helper does not write firmware or persistent keyboard hardware state. It changes only the in-memory `UserKeyMapping` property of the matching HID service.

Before changing anything, the executable independently verifies the full Magic Keyboard identity again. It preserves all unrelated existing `UserKeyMapping` entries and replaces/removes only the Search/F4 source entry.

## Easy install
Unpack the release ZIP and double-click:

- `1-INSTALL.command` — install
- `2-CHECK.command` — verify installation/status
- `3-UNINSTALL.command` — remove

The terminal scripts pause at the end so the result remains visible.

Permanent files:
- `~/bin/magic-keyboard-keymap`
- `~/Library/LaunchAgents/com.landco.magic-keyboard-keymap.plist`

No Homebrew, Xcode, CLT, Python, third-party libraries, polling, or permanent resident helper process are required.
