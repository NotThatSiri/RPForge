# RP Forge Roadmap

RP Forge is a roleplay addon for World of Warcraft Forever. It works alongside Total RP 3 and adds its own
systems on top. Everything that makes up the world (places, items, quests, vendors, campaigns) is made by
players in game, not hard-coded into the addon. It is built for Horde and Alliance alike.

## Versioning

RP Forge uses [Semantic Versioning](https://semver.org): `MAJOR.MINOR.PATCH`.

- **Before 1.0 (`0.x`):** each minor version is one milestone below. Every build handed over to try in
  game gets the next patch number and a tag, so the number in game always says exactly which build it
  is: `0.2.0`, `0.2.1`, `0.2.2` and so on. Several small changes made together go into one build.
  Starting the next milestone resets it: `0.3.0`.
- **Release candidates:** `1.0.0-rc.1`, `1.0.0-rc.2` before the 1.0 release.
- **From 1.0:** major for changes that break saved data or compatibility between players, minor for new
  features, patch for fixes.
- **Saved data** and **player-to-player messages** have their own version numbers. Saved data upgrades itself
  when its version changes.
- The version lives in `RPForge.toc`. Every version gets one `CHANGELOG.md` entry and a git tag (`v0.1.0`).

## Milestones

| Version | Milestone | Contents |
|---|---|---|
| 0.1 | Foundation | Addon skeleton, saved data with upgrades, player messaging with a version check, UI kit, settings, error log and bug report |
| 0.2 | Profile & Persona | Own profile and IC/OOC/LFRP status; works with Total RP 3 both ways; first impressions, traits, tooltip and target info |
| 0.3 | Chat & Session Log | Typing indicator, accents for Alliance and Horde races, IC session diary |
| 0.4 | Character | 5e-style character sheet; effects (timed buffs and debuffs that change sheet values); Health |
| 0.5 | Places & Triggers | Save places (spot, size, type); When / If / Then rules; automatic effects such as resting at a campfire |
| 0.6 | Items & Packs | Item maker, inventory, vendors; content packs to share and import |
| 0.7 | Quests & Contracts | Quests with objectives that complete themselves; bounties and contracts using the same checks |
| 0.8 | Professions & Business | Professions trained by doing; gathering in places; crafting; player businesses |
| 0.9 | Progression & Houses | Renown, achievements and seasons from visible rules with caps and a log; surname Houses; guild companies with automatic membership |
| 0.10 | Campaigns | Tools for storytellers: run campaigns, hand out quests and items, follow the party |
| 1.0 | Release | Feature freeze, group testing, polish, guide, public release |

Campaigns may move to 1.1 if that gets 1.0 out sooner.

## 0.2 Profile & Persona in detail

RP Forge shows Total RP 3 profiles and sends its own to Total RP 3 users, using the profile format that
Total RP 3, MyRolePlay and XRP share. When Total RP 3 is installed too, RP Forge asks once whether to keep
Total RP 3 for the profile (RP Forge reads it and adds its own parts) or to move the profiles into
RP Forge (Total RP 3 is then turned off; its saved data is kept). First impressions and traits are shared
with Total RP 3's glances and traits rather than kept twice.

| Order | Part | Contents |
|---|---|---|
| 1 | Your profile | Profile page: identity, status, about; several profiles to switch between |
| 2 | Home | Your character's banner: portrait, name, full title, race, class, guild; changeable background; status |
| 3 | Sharing | Send and receive profiles in the shared format; names and status in tooltips; remember people met |
| 4 | The Total RP 3 link | One-time choice; read Total RP 3 profiles; move Total RP 3 profiles into RP Forge |
| 5 | Persona | First impressions, trait sliders, name colour, profile icon, theme tune |
| 6 | Viewing profiles | Open anyone's profile; a People page of everyone met |

Home grows with each milestone: cards for people met, sessions, health, quests and progress appear as
those parts arrive.

## 0.3 Chat & Session Log in detail

| Order | Part | Contents |
|---|---|---|
| 1 | RP chat window | Its own window with Say, Emote and Yell nearby: round portraits, roleplay names, coloured speech, dimmed OOC; game or story layout |
| 2 | Typing box | Multi-line typing in the RP chat window; Say / Emote / Yell; long posts split with (1/3) markers |
| 3 | Typing indicator | "Kiri is typing..." above the box, between RP Forge users nearby |
| 4 | Accents | Starter accents for Alliance and Horde races at three strengths |
| 5 | Your own accents | An editor for word swaps and endings |
| 6 | Session log | Automatic sessions: who, where, how long, and the IC transcript; titles and notes |
| 7 | Sessions page | A Sessions page under Stories, and a Home card for the last session |

## Principles

- **Players decide.** Content is made in game and shared in packs; the addon provides the tools.
- **Nothing counts in secret.** Progress (renown, achievements, levels) only comes from rules a player can
  see, with caps and a log of why it was given.
- **Both factions.** Faction changes flavour and wording, never what a player can do.
- **Our own code.** Other addons are studied for ideas only; no code is copied from them.
