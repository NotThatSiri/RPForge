# Changelog

All notable changes to RP Forge are listed here. Versions follow [Semantic Versioning](https://semver.org).

## [0.3.28] - 2026-11-25

### Added
- **Whispers window.** With "Whispers window" on (Settings > Chat), whispers you get and send go to their
  own window, one tab per person:
  - Click a tab to read and answer. Right-click it to clear or close that conversation. Tabs that don't fit
    are under "More".
  - /w Name and /r in the RP chat box (or in the Whispers window) open the right tab. "/w Kiri Stormcrest
    hello" sends "hello" straight away. Name suggestions work in both boxes.
  - New whispers put a dot on the RP button by the game's chat (a click then opens the Whispers window) and
    a count in the RP chat's title ("Whispers (2)", click to open).
  - Whispers are kept per character, so they survive a reload.
- **Clear the chat log:** "Clear" in the RP chat title, "Clear" in the Whispers window (this conversation,
  or all whispers), the buttons in Settings > Chat, or /rpf clearchat. Each asks once more first.
- /rpf whispers opens or closes the Whispers window.

### Changed
- Whispers no longer show in the RP chat window. The setting is now called "Whispers window".
- The cogwheel on the RP chat opens Settings > Chat.

## [0.3.27] - 2026-11-25

### Added
- **Name suggestions for /w** in the RP chat box, like the game's chat. Names show up as you type, newest
  first: people you whispered with, your target, your group, online friends and guild, and people in the
  RP chat. Up and Down pick a name; Tab, Enter or a click takes it.

### Fixed
- /w works with first and last names. The name ends where a name RP Forge knows ends ("/w Kiri Stormcrest
  well met"). For a name it doesn't know, type the whole name and press Enter.

## [0.3.26] - 2026-11-25

### Added
- **Write to your party, raid and whispers from the RP chat box**, like the game's chat:
  - /p and /ra for party and raid (with "Party and raid in RP chat" on).
  - /w Name to whisper someone, and /r to answer the last whisper (with "Whispers in RP chat" on).
  - The box shows where it sends ("Party:", "To Kiri:") in that chat colour, and stays there until you
    switch with /s, /e or /y. Party and raid go back to Say when you leave the group.
  - Typing in party or raid tells your group you're typing. Typing a whisper tells no one.
- **Chat tab in Settings.** The RP chat layout, typing indicator, party and raid, whispers and the RP button
  have moved there from General and Appearance, with a list of the commands you can use in the box.

## [0.3.25] - 2026-11-25

### Added
- **Whispers in RP chat** (Settings > General, off at first): whispers you get show as "Name (whisper)",
  and ones you send as "You -> Name (whisper)", in the whisper colour.

## [0.3.24] - 2026-11-25

### Changed
- The RP button sits above the General chat tab instead of in the row of tabs.

## [0.3.23] - 2026-11-25

### Fixed
- You could see yourself as "typing" when you wrote in party or raid: your own message came back from the
  group and your name didn't match. Typing messages now carry your character's ID, and your own are ignored.

## [0.3.22] - 2026-11-25

### Added
- **Party and raid in RP chat** (Settings > General, off at first): the RP chat window also shows what
  your party and raid write, marked "(party)", "(raid)" or "(raid warning)" in their chat colours.
- **Click a message to copy it.** The text opens selected in a small box; Ctrl+C copies it and closes the
  box. Messages light up faintly when you point at them.
- **RP button on the chat:** a small "RP" button above the right end of the game's chat window opens and
  closes the RP chat. It can be turned off in Settings > General.

## [0.3.21] - 2026-11-25

### Added
- **Typing indicator for the game's chat box.** Typing in say or emote tells RP Forge users near you, and
  typing in party or raid tells your group, just like the RP chat window does.
- While the RP chat window is closed, a small bar under the chat shows who is typing ("Kiri is typing in
  party..."). Drag it to move it.
- **Show accents for other races** on the Voice tab. Without it you only see your own race's accents (your
  game race, or the race written on your profile).

### Changed
- Accents are only for the races in the game, and only for your faction:
  - Alliance: Dwarven, Gnomish, Kaldorei.
  - Horde: Orcish, Trollish, Forsaken, Tauren.
- Accents only change your words while your profile is **In Character**. The RP chat and the Voice tab say
  when it is off. Try it on the Voice tab works either way.

### Removed
- The Draenei, Gilnean, Sin'dorei and Goblin accents.

### Fixed
- The Gnomish accent had gone missing in 0.3.19.

## [0.3.20] - 2026-11-24

### Added
- **Talking to** next to Try it on the Voice tab (for Dwarven): your target, a man or a woman, so you can
  see "friend" become lad or lass without targeting anyone.

### Fixed
- Five-letter "-ing" words change too: "going" becomes "goin'", "doing" becomes "doin'". Short words
  where "ing" is part of the word stay ("thing", "bring", "swing").

## [0.3.19] - 2026-11-24

### Changed
- **Dwarven** uses the full word list from before: "friend", "mate", "buddy" and "pal" become lad or lass
  from your target's gender (laddie or lassie at Strong), and stay as they are without a target. Also
  "guys" becomes "lads", "nope" becomes "nae", and Strong covers more words (hasnae, werenae, and
  "dont" or "cant" typed without an apostrophe).
- "Evening" is left alone.

## [0.3.18] - 2026-11-24

### Changed
- The **Try it** box on the Voice tab changes as you type too, like the RP chat window. Choosing another
  accent or strength starts it again from the sample text in that accent.

## [0.3.17] - 2026-11-24

### Changed
- **Your accent shows as you type** in the RP chat window: each word changes as soon as you finish it,
  so you see what you will post before you send it.
- **Dwarven** now sounds like the game's dwarves (Falstad, Kurdran, quest text) instead of Scots:
  - Light: ye, yer, me, aye, lad/lass, -in'.
  - Medium: adds fer, tae, wi', an', 'em, 'tis, wee.
  - Strong: adds th', o', nae, och, cannae, dinnae, laddie/lassie.
- **Kaldorei** starts formal and saves Darnassian for Strong:
  - Light: no contractions ("I don't" becomes "I do not", "isn't it" becomes "is it not").
  - Medium: formal words (greetings, farewell, very well, thank you).
  - Strong: Ishnu-alah and Elune-adore.

### Fixed
- Words where "ing" is part of the word are left alone ("string", "spring", "during", "ceiling").
- An accent never changes its own words a second time (Draenei "by the Naaru" stays "by ze Naaru",
  Trollish "sometin'", Gilnean "smashin'").

## [0.3.16] - 2026-11-24

### Fixed
- Opening the RP chat could give "attempt to compare a secret string value" while nameplates were shown.
  The game hides who some nameplates belong to; RP Forge now skips those instead of failing (for
  portraits, "Name -> Target" and the typing indicator).

## [0.3.15] - 2026-11-24

### Added
- The RP chat window shows your accent above the typing box ("Accent: Dwarven, medium"). Click it to
  choose an accent and strength without leaving the chat, or to open the Voice tab and try it out.

### Fixed
- Pop-up menus open upwards when there is no room below them, and always stay on screen.

## [0.3.14] - 2026-11-24

### Fixed
- An error ("bad argument #1 to 'UnitFullName' ... Secret values are only allowed during untainted
  execution") could appear when someone's profile arrived while a player tooltip was open. The game now
  hides which unit a tooltip shows in some cases; RP Forge then uses the player under your mouse.

## [0.3.13] - 2026-11-24

### Added
- **Accents.** A new **Voice** tab in the profile editor lets each profile pick an accent and a strength
  (Light, Medium or Strong):
  - Alliance: Dwarven, Gnomish, Kaldorei, Draenei, Gilnean.
  - Horde: Orcish, Trollish, Forsaken, Tauren, Sin'dorei, Goblin.
- The accent changes what you post from the RP chat window: everything you say or yell, and only the
  words in "quotes" when you emote. *Actions*, ((OOC)), links and colour codes are left alone. Capitals
  are kept ("You" becomes "Ye", "YOU" becomes "YE").
- **Try it** on the Voice tab shows your own text and an emote with the accent applied.
- The RP chat typing box shows your accent in its corner.

## [0.3.12] - 2026-11-24

### Changed
- The RP chat typing box has no Say, Emote and Yell buttons any more. Type **/s**, **/e** (or /me) or
  **/y** at the start, like in the game's chat, to switch; the command disappears and the box shows
  "Say:", "Emote:" or "Yell:" with its border and text in that chat colour. It stays in that mode until
  you switch again.

## [0.3.11] - 2026-11-24

### Added
- **Typing indicator** in the RP chat: "Kiri Stormcrest is typing..." appears above the typing box while an
  RP Forge user near you writes in their RP chat, and disappears when they post, empty their box or stop
  for a few seconds. Others see the same when you type. It only goes to RP Forge users you can see or
  heard recently, by invisible addon whispers. **Settings > General > Typing indicator** turns it off.

## [0.3.10] - 2026-11-24

### Fixed
- Opening the RP chat gave the error "Cannot set tex coords when texture has mask" when a message came
  from someone out of sight with no profile icon (shown with their class icon).

## [0.3.9] - 2026-11-24

### Changed
- RP chat portraits use the same thin accent-coloured ring as the Home portrait, instead of the thick
  gold border.

## [0.3.8] - 2026-11-24

### Changed
- The round Home portrait now has a thin ring in the theme's accent colour, matching the square frame,
  instead of the thick gold border.

## [0.3.7] - 2026-11-24

### Changed
- The **Square** portrait shape no longer shows a moving 3D model. It uses the same still portrait as
  Circle, cropped to fill the square.

## [0.3.6] - 2026-11-24

### Fixed
- The round Home portrait had blocky orange corners instead of a frame. It now sits in the game's gold
  round border, the same one the RP chat uses.

## [0.3.5] - 2026-11-24

### Added
- RP chat shows **whom a message was aimed at**: "Kiri Stormcrest -> Sigoblanc Fireheart says:", using
  roleplay names when known. For other players this works when the game can see them (target, mouseover,
  group or nameplates).

### Changed
- Messages in a row from the same person now stay together under one name and portrait until someone
  else speaks, they switch between Say, Emote and Yell, change target, or pause for more than 15 minutes
  (it was 2 minutes, too short for RP). Point at a grouped message to see its time.

## [0.3.4] - 2026-11-24

### Added
- A **cogwheel** in the RP chat title bar opens Settings > Appearance, where the RP chat layout is chosen.

## [0.3.3] - 2026-11-24

### Added
- A **typing box** at the bottom of the RP chat window:
  - **Say**, **Emote** and **Yell** buttons choose how you post; it remembers your last choice. Starting
    with /s, /e (or /me) or /y switches for that post.
  - **Enter** sends, **Shift+Enter** starts a new line, Escape leaves the box. The box grows as you write.
  - Long posts are split at word boundaries into several messages marked **(1/3), (2/3), (3/3)**; a
    counter shows how many posts it will be. New lines become spaces, as the game can't send them.

### Fixed
- The RP chat was hard to read on the **Parchment** theme. Parchment now uses dark chat colours (ink for
  Say, amber for Emote, deep red for Yell), and very light class colours are darkened for names.

## [0.3.2] - 2026-11-24

### Added
- **Settings > Appearance > Portrait shape** for your portrait on Home:
  - **Circle** (the default): a round portrait in a ring of the theme's colour.
  - **Square**: a close-up of your character that fills the whole square.

### Fixed
- The Home portrait was round inside a square frame.

## [0.3.1] - 2026-11-24

### Fixed
- A warning, "Binding header RPFORGE was attempted to be loaded more than once", after logging in.

## [0.3.0] - 2026-11-24

The RP chat window, the start of the Chat & Session Log milestone.

### Added
- An **RP chat** window: only Say, Emote and Yell from people nearby, without trade, guild or system
  messages. Your normal chat stays as it is.
  - Each message shows the speaker's **portrait** in a round frame (their profile icon or class icon when
    the game can't show them), their **roleplay name** in its colour, and the time.
  - Speech in "quotes" inside emotes is coloured like Say; ((OOC)) text is dimmed.
  - Several messages in a row from the same person share one name and portrait.
  - Move it by its title bar and resize it from the corner; it remembers where it was and keeps the last
    messages after a reload.
- Open it with the **RP chat** button on Home, `/rpf chat`, or a key you set under Key Bindings >
  AddOns > RP Forge (there's also a key for the RP Forge window).
- **Settings > Appearance > RP chat layout:** game style (Kiri says: Well met.) or story style
  (Kiri: "Well met.").

## [0.2.15] - 2026-11-24

### Changed
- The **Settings** button in the title bar is a cogwheel again, coloured by the theme. The cogwheel
  image comes from an icon pack (see `NOTICE`).

## [0.2.14] - 2026-11-24

### Changed
- RP Forge no longer uses image files of its own; everything is drawn with simple shapes and text, or
  uses the game's own art.
  - The title bar has a **Settings** text button (highlighted while Settings is open) and a text **X**.
    The bug report window has the same X.
  - Your portrait on Home sits in a square frame with a thin border in the theme's colour.
  - Traits show as flat **pips** instead of round dots: faint when empty, full colour when filled.

## [0.2.13] - 2026-11-24

### Changed
- The Traits tab in the profile editor uses the same **dots** instead of sliders: click a dot towards the
  side that fits your character; click the same dot again to go back to balanced.

## [0.2.12] - 2026-11-24

### Changed
- Traits on profiles show as **dots**, like a tabletop character sheet: five on each side, filled from the
  middle towards the side the character leans to. One dot is a slight lean, five is completely; no
  filled dots means balanced. The side they lean to is highlighted.

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
