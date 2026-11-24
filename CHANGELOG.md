# Changelog

All notable changes to RP Forge are listed here. Versions follow [Semantic Versioning](https://semver.org).

## [0.1.5] - 2026-11-24

### Fixed
- The cogwheel showed a game icon with a dark square behind it. It is now RP Forge's own cogwheel and
  takes the theme's colours.
- The close button is now a matching X icon, muted until you point at it.

## [0.1.4] - 2026-11-24

### Changed
- Settings moved out of the side menu to a cogwheel next to the close button. Click it to open
  Settings; click it again to go back to the page you were on. General and Appearance are tabs at the
  top of Settings.
- Right-clicking the minimap anvil opens Settings > Appearance.

## [0.1.3] - 2026-11-24

### Added
- A **Settings** section in the side menu, with **General** and **Appearance** pages.
- General: turn player messages and debug messages on or off, and move the window back to the middle.
- Themes: **Parchment** (warm paper and dark ink, the new default), **Forge** (charcoal with an ember
  glow) and **Arcane** (slate blue with a teal light). Pick one under Settings > Appearance or with
  `/rpf theme parchment`, `forge` or `arcane`. The window changes straight away.
- Minimap button with an anvil. Left-click opens or closes RP Forge, right-click opens Appearance; drag
  it to move it around the minimap. Hide or show it under Settings > Appearance or with `/rpf minimap`.

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
