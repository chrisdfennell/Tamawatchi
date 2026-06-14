# Garmi-gotchi

Tamagotchi-style virtual pet for Garmin Connect IQ watches.

## Setup

Requirements:

- Garmin Connect IQ SDK 4.x or newer
- Monkey C extension or command-line `monkeyc`
- A simulator target such as `fr965`, `venu3`, or your desired device

Build example:

```powershell
monkeyc -f monkey.jungle -o bin/GarmiGotchi.prg -y developer_key.der -d fr965
```

Run in simulator:

```powershell
connectiq
monkeydo bin/GarmiGotchi.prg fr965
```

## Assets

The app expects pixel art PNGs under `resources/images/` and binds them through
`resources/drawables/drawables.xml`. This scaffold uses the previously generated
native 48x48 pet sprites and 500x500 launcher icon.

To add more animals later:

1. Copy the animal sprites into `resources/images/`.
2. Add bitmap IDs in `resources/drawables/drawables.xml`.
3. Add a new pet type constant and sprite mapping in `source/TamagotchiView.mc`.
4. Add behavior tuning in `source/Pet.mc` if needed.

## Project Structure

```text
manifest.xml                         Connect IQ manifest
monkey.jungle                        Build configuration
source/
  TamagotchiApp.mc                   App lifecycle, glance entry
  TamagotchiView.mc                  Main UI, input, animation
  TamagotchiGlanceView.mc            Quick status glance
  Pet.mc                             Stats, stages, behavior, real-world decay
  StorageManager.mc                  Persistence helpers
resources/
  strings/strings.xml                Localizable strings
  drawables/drawables.xml            Bitmap resource bindings
  layouts/main_layout.xml            Placeholder for future XML layouts
  images/                            Pixel art PNGs
assets/                              Source/generated asset packs
tools/                               Local asset generation scripts
```

## Design Notes

Connect IQ packages have one application type. This project is configured as a
widget-style app so it can provide a glance for quick status and a full
interactive view when opened. The model is timestamp-driven to keep battery use
low: stats are advanced when the app/glance resumes, with a slow visible timer
only for animation and prompts.
