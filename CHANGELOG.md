# Changelog

All notable changes to Tamawatchi are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project aims to follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.3.0] - 2026-06-15

### Added
- **Massively expanded watch compatibility** — the app now targets 61 Garmin
  watches (up from 14), including the **Forerunner 970** and the rest of the
  modern Forerunner, fenix 7/8, epix 2, enduro 3, Venu 2/3/4, Venu Sq 2,
  Venu X1, Vivoactive 5/6, Instinct 3/E, and the Approach, Descent, D2 and
  MARQ 2 specialty watches. (A handful of the very newest devices — fr70,
  fr170, d2mach2pro — are held back until the CI Connect IQ SDK image is
  updated past 9.1.0.)

## [1.2.1] - 2026-06-14

### Fixed
- The pet no longer **floats above** the bottom panel — its feet now rest on the
  panel (the sprite's transparent foot padding is accounted for).

## [1.2.0] - 2026-06-14

### Added
- Two more Play mini-games — a **reaction test** and a **button masher** — and
  **Play now picks one at random** each time, so it stays fresh.
- **Name your pet** from a preset list when you first adopt it (the name shows at
  the top), plus a **Rename** option in Settings.
- **Custom typed names** via the Garmin Connect app settings (the `petName`
  property overrides the in-app name when set).

### Changed
- The pet name/title now has a **black outline** so it reads clearly over the pet
  and sky.

### Fixed
- The pet is no longer pushed **behind the bottom panel** (e.g. after cleaning) —
  it now stands correctly on the panel.

## [1.1.0] - 2026-06-14

### Added
- A live **activity panel** on the main pet screen showing daily **steps**,
  **heart rate**, and the pet's **happiness**, with icons.

### Changed
- The pet now stands on the activity panel; egg and death states show a
  "Press START" prompt in its place.
- Care now opens from the **START** button only; tapping the screen flips to the
  Stats page. Help text updated to match.

## [1.0.1] - 2026-06-14

### Added
- Support for the **fenix 8 family** (`fenix843mm`, `fenix847mm`, `fenix8pro47mm`,
  `fenix8solar47mm`, `fenix8solar51mm`), which also covers the matching
  **tactix 8 / quatix 8** models. Verified on the 280×280 MIP Solar panel.

## [1.0.0] - 2026-06-14

### Added
- Five adoptable pets (Cat, Dog, Dragon, Penguin, Fox) with Egg → Baby → Teen →
  Adult life stages and idle/happy/sad/sleep/sick mood sprites.
- Five needs with icons: Hunger, Happiness, Energy, Health, Cleanliness.
- Care menu: Feed, Play, Clean, Sleep, Medicine, Discipline.
- Per-animal foods, eaten one bite at a time.
- "Catch the ball" Play mini-game with a score-scaled happiness reward.
- Poop-and-clean-up loop and sickness with a Medicine cure.
- Multi-hour Sleep with slow decay and energy recovery, plus automatic sleep at
  night and early wake.
- Procedural care animations (eating, shower, ball bounce, Zzz, medicine pill).
- Living day/night world with sun, clouds, moon, and stars, plus an idle breathing
  motion.
- Aging and care-based adult forms (Radiant / Grumpy), and a death legacy that
  starts a new generation whose egg inherits a trait (Hardy / Cheerful / Tidy /
  Energetic).
- Real-activity integration: steps and heart rate feed the pet.
- Paged UI (pet page + stats page), Care menu, and a Settings menu (vibration
  toggle, change pet, reset).
- Glance summary and a published watch-face complication for pet wellbeing.
- Timestamp-driven simulation that stays correct while the app is closed,
  including time spent asleep, with persistent state across launches.
- Touch routing: Care opens only from the button; tapping elsewhere opens Stats.

[Unreleased]: https://github.com/chrisdfennell/Tamawatchi/compare/v1.2.1...HEAD
[1.2.1]: https://github.com/chrisdfennell/Tamawatchi/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/chrisdfennell/Tamawatchi/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/chrisdfennell/Tamawatchi/compare/v1.0.1...v1.1.0
[1.0.1]: https://github.com/chrisdfennell/Tamawatchi/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/chrisdfennell/Tamawatchi/releases/tag/v1.0.0
