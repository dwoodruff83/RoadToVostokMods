# Shared libraries

Canonical source for single-file libraries reused across mods in this
workspace. Files here are the **source of truth** — each mod that uses one
has its own embedded copy at `mods/<ModName>/<File>.gd`.

## What's in here

| File | Purpose |
|---|---|
| `Logger.gd` | Reusable logging framework (debug/info/warn/error, file + overlay output, MCM integration). |
| `LOGGER.md` | Public guide — what gets published alongside `Logger.gd` when sharing with other modders. |

## Sync workflow

Each mod carries its own copy with identity (`mod_id`, `mod_display_name`,
`log_filename`) baked in. When the canonical version changes, run:

```
python tools/sync_logger.py          # sync all mods
python tools/sync_logger.py MyMod    # sync one mod
python tools/sync_logger.py --check  # dry run
```

The script preserves each mod's identity and rewrites the rest of the file
with the canonical content.
