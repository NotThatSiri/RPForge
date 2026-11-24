# Changelog

All notable changes to RP Forge are listed here. Versions follow [Semantic Versioning](https://semver.org).

## [0.2.11] - 2026-11-24

### Added
- A **Profile** page in the side menu, under Character: your own profile shown the way other players
  see it, with **Edit profile** and your profile switcher at the top. With Keep Total RP 3, it shows
  your Total RP 3 profile and **Edit in Total RP 3**.

### Changed
- **Edit profile** moved from the Home banner to the Profile page. **Done** in the editor goes back to it.
- `/rpf view` without a player targeted opens your Profile page.

### Fixed
- The People page could fail to open with "integer overflow" when someone's icon came from Total RP 3 in
  its packed form. Icons from other addons (including atlas icons) now show correctly everywhere.

## [0.2.10] - 2026-11-24

Viewing profiles, finishing the Profile & Persona milestone.

### Added
- A **People** page (side menu, under Character): everyone whose roleplay profile RP Forge has heard,
  most recent first, with their icon, roleplay name, title, race and class, status and when you last saw
  them. Search by name, title or race. Click someone to open their profile.
- A **profile viewer**: icon, name and full title, status, what they're doing, their OOC note, details
  (nickname, pronouns, age, height, eyes, birthplace, home, house, motto), first impressions, traits,
  appearance and history, and **Play theme** for their theme tune. It works for profiles from RP Forge,
  Total RP 3, MyRolePlay and XRP.
- `/rpf view` opens your target's profile, or your own when you have no player targeted.
- RP Forge keeps the profiles it hears (up to 500 people), so they can be read later, even offline. It
  does this also when Total RP 3 shares your profile.

## [0.2.9] - 2026-11-24

### Added
- **Theme tune** on the Persona tab: choose a song from the game's music. **Choose...** opens a
  searchable list of every track with its length; **Play** previews a track, clicking a row picks it.
  Play, stop or clear your tune from the Persona tab.
- Total RP 3 users can play your theme tune from your profile. **Move my profiles to RP Forge** also
  copies Total RP 3 theme tunes.

## [0.2.8] - 2026-11-24

### Added
- **Class colour presets** for your name colour: a row of swatches under Name colour, your own class first.
  Point at one to see the class; click to use it.

## [0.2.7] - 2026-11-24

### Added
- **Search** in the icon picker: type part of a name (for example sword, fire or book) to find icons
  among all of the game's icons. Point at an icon to see its name.

### Notes
- Icon names come from LibRPMedia, a shared roleplay library (public domain), included with its WoW
  Forever data. RP Forge is larger because of it (about 1.8 MB).

## [0.2.6] - 2026-11-24

Persona: how your character comes across.

### Added
- A **Persona** tab in the profile editor:
  - **Profile icon**, chosen from the game's own icons.
  - **Name colour** for your roleplay name.
  - Up to five **first impressions**: an icon, a title and what people notice.
- A **Traits** tab: up to ten trait sliders (for example Brave or Cautious), your own or from a list of
  common pairs.
- Home shows your first impressions as icons under the banner (hover to read them) and your name in your
  name colour.
- Total RP 3 users see your icon, name colour, first impressions (as glances) and traits.
- With **Keep Total RP 3**, Home shows your Total RP 3 glances and name colour. **Move my profiles to
  RP Forge** now also copies glances, custom traits, name colour and icon.

### Fixed
- An error ("Chomp.NameMergedRealm: expected a full name") could appear while standing near other
  players, when the game hadn't loaded someone's full name yet. ([#7](https://github.com/NotThatSiri/RPForge/issues/7))

## [0.2.5] - 2026-11-24

Choosing between Total RP 3 and RP Forge.

### Added
- When Total RP 3 is installed, RP Forge asks once what you'd like to do:
  - **Keep Total RP 3 for my profile:** Total RP 3 keeps editing and sharing your profile. Home shows your
    Total RP 3 profile, and **Edit in Total RP 3** opens it.
  - **Move my profiles to RP Forge:** every Total RP 3 profile is copied into RP Forge (names, titles,
    identity, status, currently, OOC note, appearance, history), then Total RP 3 and its add-ons are turned
    off and the game reloads. Total RP 3's saved data is kept.
  - **Decide later:** asks again at the next login.
- If you moved to RP Forge and Total RP 3 is turned on again, RP Forge asks again.
- **Settings > General** shows your choice, with **Choose again**.

## [0.2.4] - 2026-11-24

Sharing your profile with other roleplay addons.

### Added
- Players using Total RP 3, MyRolePlay or XRP can now see your RP Forge profile: your name, title, full
  title, status, what you're doing, your appearance, history and the other details.
- Player tooltips show other players' roleplay name, full title, status (In character, Looking for RP,
  Out of character) and what they're doing, if they use a roleplay addon.
- RP Forge remembers the profiles it hears, ready for a People page later.
- `/rpf sharing` says which addon shares your profile.

### Notes
- Only one addon can share your profile. If Total RP 3 (or MyRolePlay, XRP or Kinship) is running, it
  keeps doing so and RP Forge stays quiet; choosing between them comes in a later build.
- Profiles travel through LibMSP and Chomp, the shared libraries these addons use (see `Libs/README.txt`).

## [0.2.3] - 2026-11-24

### Fixed
- The background page listed races that only NPCs have (such as the Broken, Fel Orcs and Forest Trolls),
  which have no picture. It now only lists playable races.

## [0.2.2] - 2026-11-24

### Changed
- **Change background** opens a page of previews instead of a long list: a scrolling grid with a strip of
  each picture and its name. Click one to use it; **Done** goes back to Home.

## [0.2.1] - 2026-11-24

A new Home: your character's banner.

### Added
- **Banner** at the top of Home: your character's portrait in a ring, your RP name, your full title in
  < >, your race and class, and your guild.
- **Banner background** from the game's own pictures: it starts with your race's dressing-room background.
  **Change background** picks another race's. The choice is saved with each profile.
- **Status** buttons under the banner (In character, Looking for RP, Out of character) and your
  "currently" line. Click the line to change it.
- `/rpf profile` opens the profile editor.

### Changed
- The profile editor opens from **Edit profile** on Home instead of the side menu. **Done** goes back to
  Home.
- The RP Forge card (version, players heard, "Who's around?") sits under the status.

## [0.2.0] - 2026-11-24

Your roleplay profile.

### Added
- A **Profile** page in the side menu, under Character.
  - **Identity:** first and last name, title, full title, nickname, pronouns, race, class, age, height,
    eyes, birthplace, home and house.
  - **Status:** In character, Looking for RP or Out of character; what you're doing right now; an OOC
    note; a motto.
  - **About:** appearance and history.
  - Everything saves as you type. Your name shows at the top as others will see it, with your full
    title under it in < >, like Total RP 3.
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
