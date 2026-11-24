# Contributing to RP Forge

Thanks for helping with RP Forge. Everyone taking part follows the [Code of Conduct](CODE_OF_CONDUCT.md).

## Reporting a bug

Open a [bug report](https://github.com/NotThatSiri/RPForge/issues/new?template=bug_report.yml). The form
asks for:

- your RP Forge version (`/rpf version` in game);
- what you did, what you expected, and what happened instead;
- what `/rpf errors` shows, if anything;
- which other roleplay addons you have turned on (for example Total RP 3).

One bug per report makes each one easier to follow and close.

## Suggesting an idea

Open an [idea](https://github.com/NotThatSiri/RPForge/issues/new?template=idea.yml). Say what you'd like to
do in game and why. Check the [roadmap](ROADMAP.md) first: it may already be planned.

## Changing the code

### Before you start

Open an issue or comment on one first, so we can agree on the change before you spend time on it.

### Our own code only

RP Forge is written from scratch. Don't copy code, images or sounds from other addons, even if they're
open. If something from elsewhere is really needed, it must have a licence that allows it (Apache 2.0, MIT
or similar), and it must be credited in the pull request and in `NOTICE`. Game textures and icons
referenced by their in-game path are fine.

### How we work (GitHub Flow)

1. Branch from `main` with a short name: `feature/…`, `fix/…` or `docs/…`.
2. Make your changes and test them in game on WoW Forever.
3. Open a pull request into `main` and fill in the template.
4. `main` is protected: every change goes in through a pull request.

### Versions

RP Forge uses [Semantic Versioning](https://semver.org). Work is done in bundles (for example "the
window and its look"). Small changes don't change the version. When a bundle is finished, it becomes one
version: the number goes up once in `RPForge.toc`, it gets one entry in `CHANGELOG.md`, and `main` is
tagged (`v0.1.2`). Leave the version number to the maintainer unless asked.

### Code style

- Lua, 4 spaces, no tabs. Short functions with names that say what they do.
- Every file starts with a comment saying what it's for.
- Colours come from the theme (`RPF.UI.Color("accent")`), never written into a page.
- Text players see is plain and friendly: say what happens, not how it works inside.
- Errors go through `RPF.SafeCall`, so one broken feature never stops the rest.

### Licence of contributions

By opening a pull request you agree that your contribution is licensed under the
[Apache License 2.0](LICENSE), like the rest of RP Forge.
