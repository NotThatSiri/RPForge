# Changelog

All notable changes to RP Forge are listed here. Versions follow [Semantic Versioning](https://semver.org).

## [0.1.2] - 2026-11-24

### Added
- The RP Forge window. `/rpf` opens it (`/rpf open` too). Drag the title bar to move it; it remembers
  where you left it. Escape or the x closes it. `/rpf reset` moves it back to the middle of the screen.
- Home page: your version (and whether a newer one is out), how many RP Forge players were heard, and a
  "Who's around?" button.
- About page: credits, licence and a link to the GitHub page to copy.

### Changed
- `/rpf` on its own now opens the window. `/rpf help` lists the commands.

## [0.1.1] - 2026-11-24

### Added
- Update notice: RP Forge tells you when another player has a newer version. You hear it once per
  session, and again at login if that version was seen in the last 3 days.
- `/rpf who` lists the RP Forge users around you (guild, group and the RP Forge channel) and their
  versions. Newer versions show in green, older ones in orange.
- `/rpf network` turns player messages on or off.
- RP Forge joins a hidden channel, `RPForgeNet`, to reach players outside your guild and group. It does
  not show in your chat.
- Licensed under the Apache License 2.0 (`LICENSE`, `NOTICE`).

## [0.1.0] - 2026-11-24

### Added
- Addon skeleton for WoW Forever.
- Saved data for the account and for each character, with automatic upgrades between data versions.
- Error log: errors inside RP Forge are caught and kept so they can be reported.
- `/rpf` commands: `help`, `version`, `errors`, `debug`.
