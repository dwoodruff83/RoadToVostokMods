# RTVModItemRegistry — publish notes

Internal workspace doc. Not bundled in the .vmz.

## Status

**RETIRED — workspace history only, do not publish.**

Metro Mod Loader v3.0.0 added a native `[registry]` opt-in (mod.txt) plus an `Engine.get_meta("RTVModLib").register(SCENES/ITEMS/LOOT/...)` API that subsumes everything this mod was built to coordinate. The in-loader implementation is strictly better — it runs at loader startup before any user mod, supports 16 registries (vs our SCENES-only), and exposes register / override / patch / remove / revert verbs with stash-and-restore semantics our shim never had.

**Decision (2026-04-26):** retire. No ModWorkshop publish. Retain source as workspace reference. CatAutoFeed and RTVWallets migrated to call Metro's registry directly (`lib.register(lib.Registry.SCENES, ...)`), declared via `[registry]` in their mod.txt files.

## Why we keep the source

- Best-documented mod in the workspace; useful learning artifact for the take_over_path coordination pattern
- The diagnostic / self-check tooling (`run_self_check`) is a nice debugging aid for the take_over_path mechanics — could be salvaged into a separate dev-mode tool later
- Reference implementation for any future mod that needs to wrap a non-registry-supported autoload

## Was-going-to-publish summary (historical)

- Would have been first day-one publishable
- Tests #1–#4 passed; hostile-clobber limitation was documented
- Outreach DMs were drafted to domfrags and metro — never sent
- Migration path for consumers was the planned `register()` shim API

## References

- User-facing docs: [README.md](README.md) (carries the RETIRED banner)
- Modder integration guide: [REGISTRY.md](REGISTRY.md)
- Metro's superseding registry: [Metro Registry docs](https://github.com/ametrocavich/vostok-mod-loader/blob/development/docs/wiki/Registry.md)
