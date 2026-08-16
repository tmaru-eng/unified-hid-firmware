# Getting started

This guide covers flashing the public firmware, connecting a BLE keyboard, and
using the Web UI. If you only want to inspect the UI, use the simulation section
without a board.

## Hardware

Use a Seeed XIAO nRF52840 Sense, a USB data cable, an ANSI US BLE keyboard, and
Chrome or Edge with WebHID support. The bridge is the USB HID output device and
accepts BLE keyboard input. Keep the keyboard disconnected from the host while
changing firmware or persistent configuration.

## Flashing

Download the UF2 from the matching [GitHub Release](https://github.com/tmaru-eng/unified-hid-firmware/releases).
Check the board model, firmware version, and build identifier before writing. Do
not flash an assumed board or artifact.

Keep all BLE keyboards disconnected and make sure no radio link is active. Follow
the release-specific backup and preflight instructions. From the repository root,
run the preflight first:

```powershell
Set-Location firmware/nrf52840-ble-usb/tools
.\flash_xiao.ps1 `
  -Uf2Path 'C:\path\to\release.uf2' `
  -BackupDirectory 'C:\path\to\uf2-backups' `
  -WhatIf
```

Confirm the XIAO Sense Board-ID, S140, UF2 range, and backup path. Only after
explicit owner approval, remove `-WhatIf`, add `-ConfirmFlash`, put the board in
its UF2 bootloader, and run the command. Wait for the board to reboot and keep the
`CURRENT.UF2` backup for recovery.

Never erase or write flash while a BLE link is active. A physical write requires
explicit owner approval and a verified recovery path.

### Manual UF2 copy (recovery or host without the helper script)

Use the scripted path above for normal updates. If you must use Explorer, first
disconnect every BLE keyboard and confirm that no radio link or pending save is
active. A manual copy does not automate or enforce the script's candidate
validation, Board-ID check, backup handling, or overwrite guard; perform the
checks below yourself.

1. Obtain the matching UF2 from the GitHub Release. Do not use an unreviewed
   worktree build or copy a UF2 from another board.
2. From `firmware/nrf52840-ble-usb/tools`, validate the candidate before
   connecting it to the board:

   ```powershell
   uv run xiao_uf2.py check 'C:\path\to\release.uf2'
   ```

   Stop if the family ID or application address range is not accepted.
3. If the running firmware exposes exactly one configuration HID interface,
   run `uv run --with hidapi reset_xiao.py` from the same tools directory.
   Otherwise, double-press the board's reset button to enter the UF2 bootloader.
4. Wait for the XIAO UF2 drive to appear in Explorer. Open `INFO_UF2.TXT` and
   verify `Board-ID: Seeed_XIAO_nRF52840_Sense` and the expected S140 version
   (`7.3.0` for the public bridge releases).
5. Before writing, copy `CURRENT.UF2` from the drive to a separate physical
   volume. Do not overwrite an existing backup. If `CURRENT.UF2` is absent or
   the copy cannot be verified, stop. To restore this backup later, run the
   same candidate check and verified drag-and-drop procedure.
6. After explicit owner approval, drag the release `.uf2` file to the root of
   the verified UF2 drive. If Explorer asks to replace or overwrite a file,
   cancel and stop. Wait for the drive to disappear and the board to reboot;
   do not unplug it while the copy is in progress.
7. After startup settles, run `uv run read_diagnostics.py` and confirm the
   firmware version, build identifier, bond state, source slots, and profile.

If any identity, version, or recovery check differs from the release notes,
stop and use the scripted path or investigate before writing.

## Diagnostics

Use the host tool to read the firmware version, bond state, source slots, and
profile state:

```powershell
Set-Location firmware/nrf52840-ble-usb/tools
uv run read_diagnostics.py
```

Immediately after boot, bond loading may still be in progress. Read diagnostics
again after a few seconds before concluding that stored keys are absent.

## Connecting a keyboard

Bonded keyboards normally reconnect automatically. Open pairing mode only when
welcoming a new keyboard:

```powershell
uv run pairing_mode.py on
```

After pairing, confirm that the intended source slot is connected in diagnostics.
Do not enable pairing mode merely to reconnect an already bonded keyboard.

## Web UI

Open the [published Pages site](https://tmaru-eng.github.io/unified-hid-firmware/)
in Chrome or Edge. Choose **Connect to device** and
select the bridge's configuration HID interface. The UI validates the vendor usage,
report identity, and approved vendor/product identity; selecting an unrelated HID
device is rejected.

For a registered BLE source, **Disconnect** ends only the link and preserves its
bond and settings. **Reconnect** permits discovery again but does not claim that
the keyboard is connected until its advertisement and GATT setup complete.
**Remove pairing** disconnects first when necessary, then removes the bond, name,
and source settings.

The profile screen can change US-to-JIS, Caps-to-Control, and Alt/GUI behavior for
the selected source. Source slots, link state, and the pending-save state must be
visible before applying a change.

## First configuration

1. Read diagnostics and confirm the firmware version.
2. Enable the US-to-JIS profile for the relevant source.
3. Pair a keyboard only when the pairing window is explicitly open.
4. Confirm source state and output in diagnostics.

In the keymap screen, choose a registered BLE slot or the virtual slot, read its
keymap, edit the fixed 32-rule single layer, and save it. The host tool exposes
the same path with:

```powershell
uv run read_keymap.py --slot 4
uv run write_keymap.py --slot 4 --us-jis
```

Settings can be applied to RAM while a source is connected and may remain pending
until the radio reaches a quiet boundary. Confirm the result in the UI or with
`read_diagnostics.py`; do not reset or flash while a save is pending.

## Simulation

From the repository's `ui` directory, run:

```powershell
npm ci
npm run dev
```

Open the displayed URL and choose **Connect to simulation**. The simulation uses
the same 32-byte configuration protocol, but it does not open BLE, USB, or flash
and does not send keystrokes to physical hardware.

## Troubleshooting

- If the bridge is not listed, check the USB data cable and select the configuration
  HID interface, not the keyboard HID interface.
- If a bonded keyboard does not connect, verify the host OS pairing state and read
  diagnostics again after startup settles.
- If a firmware write is needed, disconnect keyboards, run the release preflight,
  preserve a backup, and obtain explicit approval before writing.

- [日本語 getting started](GETTING-STARTED.ja.md)
