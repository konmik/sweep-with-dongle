# Ferris Sweep Firmware

ZMK firmware for a Ferris Sweep (Cradio) 34-key split keyboard with a USB dongle acting as central.

## File layout

```
shields/cradio/
  cradio.keymap            — the keymap (all layers, behaviors, macros)
  cradio.conf              — shared Kconfig (empty — defaults are fine)
  cradio_dongle.conf       — dongle-specific Kconfig (empty)
  cradio_dongle.overlay    — dongle devicetree: mock kscan, matrix transform
  Kconfig.defconfig         — per-shield defaults (split role, peripheral count)
  Kconfig.shield            — shield detection booleans
build.ps1                  — copies shields/ into ZMK tree, builds all four .uf2 images
zmk/                       — (gitignored) ZMK west workspace, ~2GB
*.uf2                      — (gitignored) build outputs
```

## Bootstrap — setting up the ZMK workspace from scratch

The `zmk/` directory is not checked in. A contributor must create it once:

```powershell
mkdir zmk
cd zmk
git clone https://github.com/zmkfirmware/zmk zmk
cd zmk
git checkout 65ef19ca    # tested commit (v0.3-149-g65ef19ca)
cd app
west init -l .
west update
```

### Dependencies

- Python 3.x with `pip install west protobuf`
- CMake, Ninja
- Zephyr SDK 0.17.0 (arm-zephyr-eabi toolchain)
  - Download from https://github.com/zephyrproject-rtos/sdk-ng/releases/tag/v0.17.0
  - Run the installer, ensure `arm-zephyr-eabi` is selected

### Build

```powershell
.\build.ps1
```

This copies `shields/cradio/*` into `zmk/zmk/app/boards/shields/cradio/`, then builds four images:
- `settings_reset.uf2` — bond/NVS clearing utility
- `cradio_dongle.uf2` — dongle (central)
- `cradio_left.uf2` — left half (peripheral)
- `cradio_right.uf2` — right half (peripheral)

Board target is `nice_nano/nrf52840/zmk` (NOT bare `nice_nano` — that misses BLE, USB, and NVS configs).

## Hardware

- Ferris Sweep (aka Cradio) split keyboard, 34 keys
- 3x nice!nano v2 (nRF52840): left half, right half, USB dongle
- nice!nano has no reset button; enter bootloader by shorting RST+GND twice quickly
- Single short of RST+GND = reset (reboot). Double short = bootloader (NICENANO USB drive appears)
- QMK/Vial do NOT support nRF52840. Only ZMK works on nice!nano

## Architecture

- Dongle = central (connects to PC via USB, talks to halves via BLE)
- Left half = peripheral (NOT central, built with `-DCONFIG_ZMK_SPLIT_ROLE_CENTRAL=n`)
- Right half = peripheral
- Dongle has `ZMK_SPLIT_BLE_CENTRAL_PERIPHERALS=2` in Kconfig.defconfig
- Dongle uses mock kscan (no physical keys), has the matrix transform and keymap
- Keymap processing happens on the dongle; peripherals only send key positions

## Flashing

- Flash order for each device: settings_reset.uf2 first, then actual firmware
- Settings reset clears NVS (BLE bonds, stored settings). Required when:
  - Changing which device is central
  - Pairing issues between dongle and halves
  - Clearing ZMK Studio stored keymap overrides
- BLE bonds are stored on BOTH sides. If you reset bonds on the dongle, you MUST also reset bonds on both halves
- After flashing all three, reset them one by one (dongle first). They auto-pair within seconds
- `&sys_reset` in keymap just reboots; does NOT erase firmware
- `&bootloader` enters UF2 bootloader mode

## ZMK Studio

- Disabled in current build (was causing issues)
- Studio stores keymap changes in NVS which OVERRIDE the compiled keymap
- If Studio is enabled: after reflashing, must "Restore Stock Settings" in Studio or changes from .keymap file won't apply
- Enabling requires: `-S studio-rpc-usb-uart -DCONFIG_ZMK_STUDIO=y` on dongle build, `&studio_unlock` in keymap, protobuf pip package

## Keymap

- Cradio shield in ZMK = "cradio" (original name by davidphilipbarr)
- Do NOT use C preprocessor macros (HRML, HRMR etc) — breaks keymap-editor compatibility
- `&lt` (layer-tap) uses `tap-preferred` flavor by default, unreliable for tri-layer over wireless dongle
- Use custom `ltp` behavior with `balanced` flavor for layer-tap keys when tri-layer is needed
- `&kp` on hold repeats. For single-fire on hold, use a macro wrapping `&kp`
- `&sk` (sticky key) on hold = regular modifier; released alone = one-shot modifier. Covers both use cases
- Keymap editor: https://nickcoutsos.github.io/keymap-editor/ (clipboard mode, select Cradio first)
