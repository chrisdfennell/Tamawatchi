# Contributing to Garmigotchi

Thanks for your interest in improving Garmigotchi! 🐾 This guide covers how to get
set up, build, and submit changes.

## Prerequisites

- [Garmin Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) **4.2.0+**
  (developed against **9.1.0**)
- **JDK 21** (the build script expects it; adjust the path in `build.ps1` if yours differs)
- A Connect IQ **developer key** (`developer_key.der`) — generate one from the
  VS Code Monkey C extension or the SDK's `connectiq` tools, and place it in the
  project root (it is git-ignored and must never be committed)
- Windows with **PowerShell** (the helper scripts target it), or adapt the raw
  `monkeyc` commands for your platform

## Build & run

```powershell
# Compile for one device
./build.ps1 -Device fenix7

# Compile and launch in the Connect IQ simulator
./build.ps1 -Device fenix7 -Run

# Build the signed store package (.iq) for all manifest devices
./build.ps1 -Export
```

Or with the raw compiler:

```powershell
monkeyc -f monkey.jungle -o bin/Garmigotchi.prg -y developer_key.der -d fenix7
```

## Project layout

See the **Project Structure** section of the [README](README.md). In short:

- `source/` — all Monkey C code (`Pet.mc` is the model; `TamagotchiView.mc` is the UI)
- `resources/` — sprites, strings, layouts, and the complication definition
- `tools/` — Python art generators and `savescreenshot.ps1`
- `assets/` — generated art packs and screenshots

## Making changes

1. **Branch** off `main`.
2. Keep changes focused and match the surrounding **code style** (the existing
   `.mc` files are the reference: 4-space indent, `as Type` annotations,
   descriptive names, small helper methods).
3. **Build cleanly** — `./build.ps1 -Device fenix7` should compile with no errors,
   and `./build.ps1 -Export` should still package every manifest device.
4. **Test in the simulator.** For visual changes, capture before/after screenshots
   with `tools/savescreenshot.ps1` (run it under **Windows PowerShell 5.1**).
5. If you changed sprite art, re-run `python tools/copy_ciq_resources.py`.
6. Update **[CHANGELOG.md](CHANGELOG.md)** for any user-facing change.
7. Open a PR using the template; fill in what you changed and which devices you tested.

## Adding a new pet (quick reference)

1. Add the species to `SPECIES` in `tools/generate_pixel_pet_pack.py` and the
   `FILES` map in `tools/copy_ciq_resources.py`, then run both scripts.
2. Bind the new bitmaps in `resources/drawables/drawables.xml`.
3. Add a `PET_*` constant and sprite/food mapping in `source/Pet.mc` /
   `source/TamagotchiView.mc`.

## Reporting bugs & ideas

Use the **issue templates** (Bug report / Feature request). For open-ended
questions, start a Discussion instead.

By contributing, you agree your work is licensed under the project's
[MIT License](LICENSE).
