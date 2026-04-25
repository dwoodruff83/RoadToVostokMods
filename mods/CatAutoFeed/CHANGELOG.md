# Changelog

All notable changes to the Cat Auto Feed mod are documented here. Dates are
YYYY-MM-DD.

## 1.0.0 — 2026-04-19

Initial release.

- Continuous auto-feed: cat gets topped up to 100% when hunger drops below the
  threshold, anywhere on the map.
- Shelter detection via CatBox item — no hardcoded shelter name.
- Skips feed when player is inside the cat's shelter (vanilla feeder handles).
- Consumes loose placed items first, then container storage.
- Patches `Character.tres` directly so the fed value persists across
  `LoadCharacter()` calls triggered by scene transitions.
- Orange hunger warning on-screen once per hunger cycle.
- MCM integration: enable toggle, feed threshold, fed notification, hunger
  warning (all separately toggleable).
- Default threshold = 25 (matches the in-game red-stat threshold).
- Feeds the same item set as the vanilla CatFeeder: Cat Food, Canned Meat,
  Canned Tuna, Perch.
