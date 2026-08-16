# Unified HID Firmware

This project is a Rust firmware bridge that converts an external ANSI US BLE
keyboard for a Windows host configured for JIS. Conversion runs on the XIAO
nRF52840 Sense; no resident PC software or driver is required.

The public repository is `unified-hid-firmware`. The current product target is
the keyboard bridge; the HID name leaves room for future mouse and trackball
input without claiming that those transports are implemented today.

## Public documentation

- [Getting started](GETTING-STARTED.md) — flash and connect the bridge
- [Configuration model](CONFIGURATION.md) — sources, profiles, keymaps, and storage
- [Architecture](ARCHITECTURE.md) — supported boundaries and current limits
- [Security](SECURITY.md) — device and secret-handling boundaries
- [日本語 documentation](README.ja.md)

The public repository is a distribution and Pages verification surface. Private
Issues, hardware logs, and internal design records are not public API.
