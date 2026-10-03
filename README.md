# Magic Keyboard F4/Search → Launchpad v2.1

Native macOS remap for the user's external Apple Magic Keyboard.

## Visible background item names
System Settings shows two intentionally distinct entries:

- `Magic Keyboard — Login`
- `Magic Keyboard — Reconnect`

They are **not two binary copies**. The installer creates two hard links to the single canonical executable:

- `~/bin/magic-keyboard-keymap`
- `~/bin/Magic Keyboard — Login`
- `~/bin/Magic Keyboard — Reconnect`

All three directory entries reference the same inode.

This follows Apple's behavior for unattributed legacy LaunchAgents: System Settings displays the executable name from `Program` / `ProgramArguments`.

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

## Architecture
1. **Magic Keyboard — Login**
   - `RunAtLoad=true`
   - Aqua session only
   - `--apply-if-present`
   - exits immediately

2. **Magic Keyboard — Reconnect**
   - `LaunchEvents -> com.apple.iokit.matching`
   - consumes the XPC stream
   - applies/remaps the target keyboard
   - exits immediately

No `KeepAlive`, no `StartInterval`, no polling.

## Safety
- no Accessibility
- no Input Monitoring
- no CGEventTap
- no root
- no firmware writes
- no system-file modification
- exact target identity is re-checked before write
- unrelated `UserKeyMapping` entries are preserved
- read-back verification after write
