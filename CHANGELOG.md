# Changelog

All notable changes to RP Forge are listed here. Versions follow [Semantic Versioning](https://semver.org).

## [0.2.0] - unreleased

Your roleplay profile.

### Added
- A **Profile** page in the side menu, under Character.
  - **Identity:** first and last name, title, epithet, nickname, pronouns, race, class, age, height,
    eyes, birthplace, home and house.
  - **Status:** In character, Looking for RP or Out of character; what you're doing right now; an OOC
    note; a motto.
  - **About:** appearance and history.
  - Everything saves as you type. Your name shows at the top as others will see it.
- Several profiles: make new ones, copy, rename, delete and switch between them. Profiles are shared by
  all your characters; each character remembers which one it uses.
- The page uses the full width. A **Profile** button next to your name opens a menu to switch profiles
  or make, copy, rename and delete them.
- Thin scrollbars in the theme's colours, shown only when there is something to scroll.
- The window background is fully solid, so nothing behind it shows through.
- New profiles start Out of character, so nobody is shown as IC until they choose it. Copies keep the
  status of the profile they were copied from.

## [0.1.3] - 2026-11-24

Bug reports, finishing the Foundation milestone.

### Added
- `/rpf bug` and a **Report a bug** button on the About page open a window with everything a bug report
  needs: your RP Forge and game versions, your settings, your other loaded addons and the recent errors.
  Copy it into the bug report form on GitHub (the link is in the window).
- RP Forge now also keeps errors that happen in its buttons and windows, not just in its background work.
  Errors from other addons are left alone. This also works alongside BugGrabber and BugSack.
- The first time something goes wrong in a session, RP Forge says so once in chat and points to `/rpf bug`.
- The About page shows how many errors are logged.

## [0.1.2] - 2026-11-24

The RP Forge window, in its own look.

### Added
- The RP Forge window. `/rpf` opens it (`/rpf open` too).
  - Drag the title bar to move it; it remembers where you left it.
  - Escape or the X closes it. `/rpf reset` moves it back to the middle of the screen.
- A side menu with the main pages:
  - **Home:** your version (and whether a newer one is out), how many RP Forge players were heard, and
    a "Who's around?" button.
  - **About:** credits, licence and a link to the GitHub page to copy.
- **Settings**, opened with the cogwheel next to the X. Click it again to go back to the page you were on.
  - **General:** player messages and debug messages on or off, and a button to move the window back to
    the middle.
  - **Appearance:** themes and the minimap button.
- Three themes: **Parchment** (warm paper and dark ink, the default), **Forge** (charcoal with an ember
  glow) and **Arcane** (slate blue with a teal light). They change the window straight away.
  `/rpf theme parchment`, `forge` or `arcane` works too.
- A minimap button with an anvil. Left-click opens or closes RP Forge, right-click opens Settings >
  Appearance; drag it to move it around the minimap. `/rpf minimap` shows or hides it.
- RP Forge's own cogwheel and X icons, coloured by the theme.

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
