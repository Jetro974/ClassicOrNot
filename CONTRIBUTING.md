# Contributing to Classic or Not

Bug reports and pull requests are welcome. For anything larger than a fix, open an issue first so we can agree on it before you write code.

By submitting a contribution you accept the contribution terms in [LICENSE](LICENSE): you keep the copyright of your work and grant this project a perpetual license to use it. The code itself may not be copied into other projects.

## Code rules

The addon follows the same rules as EllesmereUI:

- **Zero cost while off.** A place that is turned off runs nothing: its list callbacks are removed, and a hook that cannot be removed returns at once.
- **Cheap while on.** Event-driven only: no polling, no timer used as logic. Nothing is rebuilt in a path that runs often (tooltips, list refreshes); fixed anchors are set once.
- **No taint.** Never write a field, script or anchor on a Blizzard frame, and never call Blizzard code that writes them. Marks are frames of our own, kept in weak tables keyed by the row they sit on. Use `hooksecurefunc`, `HookScript` and callbacks; keep the work cosmetic.
- **No secret values compared**, indexed or used in arithmetic (`ns.IsNew` checks `issecretvalue`).
- **WoW Forever's API**: the `C_` forms, never the legacy globals Forever lacks. Check Blizzard's behavior in the Forever branch of the UI source, not in memory.
- Lua 5.1; ASCII only, except `Locales.lua`; UTF-8 without a BOM.
- Short comments that say why; one-sentence tooltips; no guard for something that always exists.
- Shared work goes in `Core.lua` (settings, the original-game test, marks, places, scrolled lists); a place's file only reads its Blizzard frames.

## Data

The lists in `ClassicOrNot/Data` come from the game's own tables only (wago.tools), never from another addon. `Tools/build_data.py` rebuilds `Items.lua` and `Collections.lua`; each file's header names its table and client build.

## Before you submit

Run `powershell -ExecutionPolicy Bypass -File Tools\check.ps1` (Lua 5.1 syntax, encoding, offline tests) and test the change in game. Say in the pull request what you tested.
