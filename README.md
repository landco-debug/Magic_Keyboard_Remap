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
The helper does not write firmware or persistent keyboard hardware state. It changes only the in-memory `UserKeyMapping` property of the matching HID service. macOS itself documents that these mappings disappear when the keyboard service is removed or the system restarts.

Before changing anything, the executable independently verifies the full Magic Keyboard identity again. It also preserves all unrelated existing `UserKeyMapping` entries and replaces/removes only the Search/F4 source entry.

`uninstall.sh` removes only this mapping and leaves unrelated remaps untouched.

## Install
Download the Actions artifact, unzip it, then:

```bash
./install.sh
```

Files are installed to:
- `~/bin/magic-keyboard-keymap`
- `~/Library/LaunchAgents/com.landco.magic-keyboard-keymap.plist`

## Uninstall
```bash
./uninstall.sh
```
