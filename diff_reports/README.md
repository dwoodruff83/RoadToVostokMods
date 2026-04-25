# diff_reports

HTML mod-impact reports produced by `tools/version_tracker/analyze_mods.py`. Each
report compares two snapshots in `reference/RTV_history` and shows which of the
mods in `mods/` may be affected by changes between those game versions.

## Why this folder is mostly gitignored

The reports embed unified diffs of game scripts (decompiled), so they are a
derivative of the game's source code. To stay safe-side on copyright we keep
the HTML files **local only**. Only this `README.md` is tracked in git.

If you need the metadata-only version (no diffs) for sharing or archival, run
the analyzer with `--no-diffs` and the resulting HTML contains paths and labels
but no source excerpts.

## Naming convention

`<from-version>_to_<to-version>.html`

Example: `0.1.0.0_to_0.1.1.3.html` audits everything that changed between the
launch build and Hotfix 0.1.1.3 against the current set of mods.

## Quick commands

```bash
# Full report with embedded diffs (default)
python tools/version_tracker/analyze_mods.py \
    --from game-v0.1.0.0-build22674175 \
    --to   game-v0.1.1.3-build22913400 \
    --output diff_reports/0.1.0.0_to_0.1.1.3.html

# Lightweight, no source excerpts (suitable for sharing)
python tools/version_tracker/analyze_mods.py \
    --from game-v0.1.0.0-build22674175 \
    --to   game-v0.1.1.3-build22913400 \
    --output diff_reports/0.1.0.0_to_0.1.1.3.metadata.html \
    --no-diffs

# List available snapshot tags
python tools/version_tracker/analyze_mods.py --list-tags
```

## Reading a report

Each mod is bucketed:

- 🟢 **Safe** — no changed file overlaps with what the mod overrides
- 🟡 **Review** — overlap exists, but only file bodies changed (signatures intact); compare the patches against your override logic
- 🔴 **Broken** — a function signature in an overridden file changed, or the file was deleted; the override almost certainly needs an update

Per-file rows expand to show the unified diff between the two versions.
