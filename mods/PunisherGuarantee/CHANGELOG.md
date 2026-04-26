# Changelog

All notable changes to the Punisher Guarantee mod are documented here. Dates
are YYYY-MM-DD.

## 0.1.0 — 2026-04-19

Initial release.

- Boosts the `Police` event's `possibility` from 10 to 100 — the Punisher
  spawn-in fires every Area 05 entry instead of being a 1-in-10 roll.
- Removes the day-5 gate by default — the Punisher can show up from day 1.
- Forces the police van into `State.Boss` (sirens, full Punisher cutscene)
  every time, instead of the vanilla 50/50 coin flip between Boss and
  ordinary patrol.
- Optional **F10 hotkey** to spawn a Punisher near the player on demand,
  bypassing the van approach.
- MCM-configurable: every effect can be toggled individually, the spawn key
  can be rebound, and the master toggle disables all patches.
- Police override implemented via `take_over_path` so it stacks cleanly with
  other mods that don't touch `Scripts/Police.gd`.
- Standard Logger integration (level + file + overlay outputs).
