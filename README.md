# Ferris Sweep Firmware

ZMK firmware for a [Ferris Sweep](https://github.com/davidphilipbarr/Sweep) (Cradio) 34-key split keyboard with a USB dongle.

## Hardware

- Ferris Sweep — 34 keys, split
- 3x [nice!nano v2](https://nicekeyboards.com/nice-nano/) (nRF52840): left half, right half, USB dongle
- Dongle is the BLE central — connects to PC via USB, talks to both halves over BLE
- Halves are BLE peripherals — they send key positions to the dongle, which runs the keymap

## Layers

| Layer | Thumb hold | Contents |
|-------|-----------|----------|
| Default | — | QWERTY |
| NavCtrl | Left inner | Navigation (arrows, home/end, pg up/dn) + Ctrl-shortcuts |
| NumSpec | Right inner | Numbers, symbols, brackets |
| Tri | Both inner | F-keys, media, virtual desktops |

Right-side modifiers (Ctrl, Alt, GUI) are Callum-style one-shot: tap for sticky, hold for regular.

## Building

### Prerequisites

- Python 3.x with `pip install west protobuf`
- CMake, Ninja
- [Zephyr SDK 0.17.0](https://github.com/zephyrproject-rtos/sdk-ng/releases/tag/v0.17.0) (arm-zephyr-eabi)

### Set up ZMK workspace (once)

```powershell
mkdir zmk; cd zmk
git clone https://github.com/zmkfirmware/zmk zmk
cd zmk
git checkout 65ef19ca
cd app
west init -l .
west update
```

### Build firmware

```powershell
.\build.ps1
```

Produces four UF2 files:
- `settings_reset.uf2` — clears BLE bonds and NVS
- `cradio_dongle.uf2` — dongle (central)
- `cradio_left.uf2` — left half
- `cradio_right.uf2` — right half

## Flashing

1. For each nice!nano, enter bootloader (short RST+GND twice — `NICENANO` USB drive appears)
2. Flash `settings_reset.uf2` first, then the device-specific firmware
3. After all three are flashed, reset them one by one (dongle first) — they auto-pair

Reset bonds on all three devices if you have pairing issues.
