# Changelog

All notable changes to Garmigotchi are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project aims to follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Two more Play mini-games — a **reaction test** and a **button masher** — and
  **Play now picks one at random** each time, so it stays fresh.

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

[Unreleased]: https://github.com/chrisdfennell/Garmigotchi/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/chrisdfennell/Garmigotchi/compare/v1.0.1...v1.1.0
[1.0.1]: https://github.com/chrisdfennell/Garmigotchi/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/chrisdfennell/Garmigotchi/releases/tag/v1.0.0
