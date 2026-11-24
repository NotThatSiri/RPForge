# RP Forge

A roleplay addon for **World of Warcraft Forever**. RP Forge gives roleplayers tools to build their own
stories in game: a character sheet, places, items, quests, professions and more. Everything that makes up
the world is made by players, not hard-coded into the addon. It works alongside
[Total RP 3](https://www.curseforge.com/wow/addons/total-rp-3) and is built for Horde and Alliance alike.

> **Early development.** RP Forge is at version 0.1 (the foundation). Most features below are planned;
> see the [roadmap](ROADMAP.md) for what comes when.

## What's in it now

- The RP Forge window with three themes: **Parchment**, **Forge** and **Arcane**.
- A minimap button (the anvil) and settings behind the cogwheel.
- An update notice: RP Forge tells you when another player has a newer version.
- `/rpf who` shows which players around you use RP Forge.

## What's planned

| Milestone | Contents |
|---|---|
| 0.2 Profile & Persona | Your profile and IC/OOC status, working with Total RP 3 both ways; first impressions and traits |
| 0.3 Chat & Session Log | Typing indicator, accents for Alliance and Horde races, an IC diary of your sessions |
| 0.4 Character | A 5e-style character sheet, effects (buffs and wounds) and Health |
| 0.5 Places & Triggers | Save places in the world and add rules to them, like resting at a campfire |
| 0.6 Items & Packs | Make items and vendors, and share your creations as packs |
| 0.7 Quests & Contracts | Quests whose objectives complete themselves; bounties and contracts |
| 0.8 Professions & Business | Professions you train by doing; gathering in places; player businesses |
| 0.9 Progression & Houses | Renown, achievements and seasons from rules you can see; family Houses and guild companies |
| 0.10 Campaigns | Tools for storytellers to run campaigns |

## Installing

1. Download the latest release from the [Releases page](https://github.com/NotThatSiri/RPForge/releases).
2. Unzip it into `World of Warcraft\_forever_\Interface\AddOns\`. The folder must be called `RPForge`.
3. Start the game and make sure RP Forge is ticked in the AddOns list.

## Using it

Click the anvil on the minimap, or type `/rpf`.

| Command | What it does |
|---|---|
| `/rpf` | Open or close the window |
| `/rpf help` | List every command |
| `/rpf who` | Show RP Forge users around you and their versions |
| `/rpf theme parchment` | Change the theme (`parchment`, `forge` or `arcane`) |
| `/rpf minimap` | Show or hide the minimap button |
| `/rpf reset` | Move the window back to the middle of the screen |
| `/rpf errors` | Show the last errors, for bug reports |
| `/rpf version` | Show your RP Forge version |

## Reporting bugs and ideas

Use the [issue forms](https://github.com/NotThatSiri/RPForge/issues/new/choose). For bugs, include what
`/rpf version` and `/rpf errors` show. See [CONTRIBUTING.md](CONTRIBUTING.md) if you'd like to help.

## Versions

RP Forge uses [Semantic Versioning](https://semver.org). What changed in each version is in the
[changelog](CHANGELOG.md).

## Licence

RP Forge is licensed under the [Apache License 2.0](LICENSE). You may use, change and share it; keep the
copyright notice and say what you changed. World of Warcraft is a trademark of Blizzard Entertainment,
Inc. RP Forge isn't affiliated with or endorsed by Blizzard.
