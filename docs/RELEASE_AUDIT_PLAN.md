# Release Audit & CHANGELOG Pruning — Plan

Status: **Planning complete, implementation not started.** Last updated 2026-05-01.

## Concept

Doc drift compounds across rapid iteration. We touch one file at a time
(README, CHANGELOG, mod.txt, NOTICES.txt, PUBLISH_NOTES.md, workspace-root
README mod-versions table), forget the rest, and ship inconsistencies. The
problem grows with every published mod and every patch cadence — CatAutoFeed
shipped 9 versions in 12 days and we still missed an MCM table row, a
workspace-versions row, and a player-visible MCM tooltip after demoting the
bowl from Legendary to Rare.

This plan defines:

1. **A two-gate audit system** that runs automatically on local installs
   (warn-only) and on tagged releases (block-on-fail by default).
2. **A discovery-driven check catalogue** — auto-walks `mods/*/mod.txt` so new
   mods are covered without config changes.
3. **A one-time CHANGELOG pruning pass** that lifts pre-1.0 history into a
   per-mod `CHANGELOG_archive.md` so the live ModWorkshop changelog tab stays
   readable.
4. **An immediate-fix punch list** for drift the research already found,
   including one player-visible bug.

The audit tooling is the centerpiece. The pruning is a one-shot cleanup that
the audit then enforces going forward.

---

## 1. Scope

| In scope | Out of scope |
|---|---|
| Every directory under `mods/` containing a `mod.txt` (auto-discovered) | `F:\rtv-mod-impact-tracker\` (separate repo, has its own life) |
| Workspace-root `README.md` "Mod Releases" table | `reference/RTV_decompiled/` (decompiled game code, never committed) |
| Per-mod `README.md`, `CHANGELOG.md`, `NOTICES.txt`, `LICENSE`, `PUBLISH_NOTES.md`, `config.gd`, `mod.txt`, `assets/` | `docs/archive/` (historical workspace docs — read-only context) |
| Live ModWorkshop `desc` and `changelog` fields for published mods | Build artifacts, `.godot/`, `.import` sidecars |
| Git tag history per mod | Anything outside this workspace root |

A mod is **published** if `.publish` exists in its folder. Discovery treats
unpublished mods identically for in-repo checks but skips ModWorkshop checks.
This way RTVHideoutLights gets covered the moment it ships, with no config
edits.

---

## 2. The two gates

### Gate A — Local iteration (cheap, runs often, warn-only)

Fires on: `publish.bat <Mod> --version X.Y.Z --no-open --install` (the "I'm
test-building this locally" path) and on any explicit `audit.bat <Mod>` invocation
with no flags.

**Checks (mechanical, ~1 second total):**

| # | Check | Failure looks like |
|---|---|---|
| A1 | `mod.txt` `version=X` matches CHANGELOG.md top entry header | `mod.txt: 1.1.6` vs `CHANGELOG: ## 1.1.5` |
| A2 | Workspace-root README mod-versions table row matches `mod.txt` for this mod | Table says `1.1.4`, mod.txt says `1.1.6` |
| A3 | `config.gd` MCM var count matches README MCM table row count | 9 settings vs 8 rows |
| A4 | All `[autoload]` paths in mod.txt point to files that exist on disk | `Logger.gd` autoload but file missing |

Output: one-line summary per mod, exit 0 even on warnings. Designed to be
ignored mid-flow but caught when reading scrollback.

### Gate B — Tagged release (heavy, runs rarely, block-on-fail)

Fires on: `publish.bat <Mod> --version X.Y.Z` (no `--no-open` — meaning the
browser opens to the upload page, the actual publish path) and on
`audit.bat <Mod> --release`.

**All Gate A checks plus:**

| # | Check | Failure looks like |
|---|---|---|
| B1 | Latest git tag `<Mod>-v<X.Y.Z>` exists OR `--allow-untagged` passed | About to publish 1.1.7 with no tag |
| B2 | Every boolean MCM toggle is mentioned in README "Features" section | Toggle exists in MCM but no Feature bullet |
| B3 | README MCM table row order matches `config.gd` `menu_pos` order | Settings re-ordered in code but not docs |
| B4 | README MCM table defaults match `config.gd` schema defaults | Table says On, code says false |
| B5 | `PUBLISH_NOTES.md` has no unchecked TODO checkboxes | `[ ] First publish` still unchecked on a mod that's been live 3 weeks |
| B6 | If `assets/` exists, every third-party-looking file is attributed in NOTICES.txt | `Cat_Bowl.glb` present, no NOTICES line for it |
| B7 | If NOTICES.txt non-empty, LICENSE has the third-party carve-out paragraph | NOTICES has 4 GLB attributions, LICENSE is plain MIT only |
| B8 | If mod has `[registry]` opt-in in mod.txt, the block has a descriptive comment | `[registry]` bare line with nothing after |
| B9 | `config.gd` runtime fallback defaults match schema defaults | `_apply()` defaults `welcome_on_start` to `true`, schema says `false` |
| B10 | Live ModWorkshop `desc` field diff vs local README.md | MW has a paragraph the README doesn't |
| B11 | Live ModWorkshop `changelog` field diff vs local CHANGELOG.md | MW is N entries behind |
| B12 | CHANGELOG.md has no entries below first-published-version threshold | Pre-1.0 entries reappeared after pruning |

Output: full report, exit 1 on any failure, `--force` to override.

### Why two gates

Local iteration tempo for CatAutoFeed averaged a release-per-day. A
heavyweight audit on every test build is friction. A lightweight gate catches
the cheap mistakes (version mismatches, missing files) without slowing
iteration; the heavy gate fires only when something's actually about to ship
to players.

---

## 3. Tooling layout

### New files (all under `tools/`)

| File | Purpose |
|---|---|
| `tools/audit_release.py` | Main script. Discovers mods, runs checks, emits report. |
| `tools/prune_changelogs.py` | One-shot bulk cleanup. Moves pre-cutoff entries to archive. |
| `audit.bat` | Workspace-root wrapper for `audit_release.py`, matches `publish.bat` style. |

### Modified files

| File | Change |
|---|---|
| `tools/publish.py` | Invokes `audit_release.py` automatically. Gate A on `--no-open`, Gate B otherwise. Honours `--force` to skip on Gate B. |
| `tools/modworkshop.py` | New `--field desc`/`--field changelog` flag on `info` to expose the two body fields (currently it only prints `short_desc`). Required for B10/B11. |

### Command surface

```bash
# Audit a single mod (Gate A)
audit.bat CatAutoFeed

# Audit a single mod for release (Gate B)
audit.bat CatAutoFeed --release

# Audit all discovered mods
audit.bat --all

# Audit all mods at release-grade (sanity sweep)
audit.bat --all --release

# Force-publish despite audit failures
publish.bat CatAutoFeed --version 1.1.7 --force
```

### Output style

Text. No HTML, no JSON, no sidecar files. Mirrors `analyze_mods.bat` /
`snapshot.bat` ergonomics — read it in the terminal, no parsing needed.

```
audit.bat CatAutoFeed --release

CatAutoFeed @ 1.1.6 — release audit

  PASS  A1   mod.txt 1.1.6 == CHANGELOG ## 1.1.6
  PASS  A2   workspace README row matches
  PASS  A3   config.gd 9 vars == README MCM 9 rows
  PASS  A4   all autoload paths exist
  PASS  B1   git tag CatAutoFeed-v1.1.6 found
  PASS  B2   all 8 boolean toggles mentioned in Features
  PASS  B3   MCM table order matches menu_pos
  PASS  B4   MCM defaults match config schema
  FAIL  B5   PUBLISH_NOTES.md has 2 unchecked TODOs:
              line 32: [ ] First publish via ModWorkshop
              line 33: [ ] Post-publish: write mod id...
  PASS  B6   NOTICES covers all assets/ entries
  PASS  B7   LICENSE has third-party carve-out
  PASS  B8   [registry] block has comment
  PASS  B9   config.gd runtime defaults match schema
  WARN  B10  live MW desc 4 lines ahead of README (added MCM row)
  PASS  B11  live MW changelog == local CHANGELOG
  PASS  B12  no pre-1.0 entries in CHANGELOG

1 fail, 1 warn, 13 pass. Use --force to publish anyway.
```

---

## 4. Check implementation notes

A handful of these need design care:

### A3 / B3 — counting MCM vars from `config.gd`

Each mod's `config.gd` registers vars via a schema dict (typically with
`menu_pos`, `category`, `type`, `value` keys, or via `_config.set_value(...)`
calls). The audit needs to parse the schema. **No regex hairshirt** —
parse `config.gd` AST via Python's `ast`-equivalent for GDScript? GDScript
isn't Python; we don't have an AST library. Instead: each `config.gd` follows
a workspace convention defined by `scaffold_mod.py`. The audit relies on that
convention (a `SCHEMA` const dict at module level) and reports a clear
"can't parse — non-standard config.gd shape" error if a mod deviates.

This means: **scaffold_mod.py becomes a soft contract** for new mods. Existing
mods either match it (CatAutoFeed, RTVWallets, RTVModLogger, PunisherGuarantee
look like they do) or get a one-time tweak to match. RTVHideoutLights will
match by virtue of being scaffolded that way.

### B6 — "third-party-looking" asset detection

Heuristic, not certain:
- `.glb` / `.gltf` / `.fbx` / `.obj` files under `assets/models/` → almost
  always third-party (we don't author 3D)
- `.png` files under `assets/icons/` → mixed. Could be authored
  (`Icon_Combine_Euro.png`) or extracted (the RTVHideoutLights icons).
  Heuristic: if filename matches a vanilla `Icon_*.png` or `MS_*.png` pattern
  from the decompiled game, treat as game-extracted (different attribution
  rule than CC BY 4.0). Otherwise prompt for attribution.
- `.png` files where filename ends in `_<digit>.png` → texture bundled with a
  GLB; covered by the GLB's NOTICES entry, no separate line needed.

The audit reports unattributed candidates and lets the human decide. It does
NOT auto-add NOTICES entries.

### B10 / B11 — ModWorkshop body diff

**Operational reality (confirmed during the 1.1.7 ship cycle, 2026-05-01):**
the MW `desc` and `changelog` body fields DO NOT auto-update when a new
`.vmz` is uploaded. Every release upload is a three-step manual flow on the
web form:

1. Drag the new `.vmz` into the upload area
2. Click **Clear Primary Download** (so Metro auto-update points at the new
   file slot — confirmed: this rotates `file_id`, e.g. `96249 → 96311`, and
   resets the per-file download counter)
3. **Paste both bodies** — copy local `README.md` into the Description tab,
   copy local `CHANGELOG.md` into the Changelog tab. If you skip this, the
   live MW page keeps showing the previous version's text even though the
   `.vmz` is current.

This means the audit cannot infer "live MW = local repo" from a successful
.vmz upload. The body fields drift forward only when the human pastes them.
Audit is therefore most useful **just before** the upload (it tells the user
exactly which body fields need re-pasting and what the new content is).

**Tooling extension required.** Today `modworkshop.bat info` prints metadata
but not the two body fields (the `info` command only exposes `short_desc`
which is empty for all our mods). Add:

```bash
modworkshop.bat info 56407 --field desc
modworkshop.bat info 56407 --field changelog
```

Both fields are returned by the public API at
`GET https://api.modworkshop.net/mods/<id>` as the `desc` and `changelog`
keys. No auth needed.

**Audit logic** — the audit captures stdout from the two field commands,
runs `difflib.unified_diff` against `mods/<Mod>/README.md` and
`mods/<Mod>/CHANGELOG.md` respectively, reports added/removed lines.
Thresholds:

- `live MW == local`: PASS, no action needed.
- `live MW behind local by content the user just edited`: WARN, with a
  clear message like *"upload pending: paste new README into Description
  tab"* — this is the normal pre-upload state.
- `live MW behind local by an entire CHANGELOG entry whose version is
  below `mod.txt` version`: FAIL — the user shipped the .vmz but forgot
  the body re-paste; the live page is misleading users about what's in
  the new version.
- `live MW ahead of local`: WARN — happens when the user edits the body
  directly on MW (as they did with CatAutoFeed's MCM table row pre-1.1.7)
  without backporting to the repo.

**Bonus tooling idea (Phase 3 stretch):** `audit.bat <Mod> --release
--paste-bodies` could print the local `README.md` and `CHANGELOG.md`
content (or copy to clipboard via `pyperclip` if installed) so the user
can paste straight from terminal output into the MW form without
hopping back to the file. Skip if `pyperclip` not installed; just print.

### B12 — pruning enforcement

The audit reads each mod's `.changelog_cutoff` file (one line, e.g. `1.0.0`).
Any CHANGELOG entry with a header version `< cutoff` triggers FAIL. If the
file doesn't exist, the check is skipped (audit doesn't enforce on mods that
opted out of pruning).

---

## 5. CHANGELOG pruning policy

### Cutoff per mod

| Mod | First published version (cutoff) | Pre-cutoff entries to archive | Lines saved |
|---|---|---|---|
| CatAutoFeed | `1.0.0` | 0.1.0, 0.2.0, 0.3.0 | ~83 |
| RTVWallets | `1.0.0` | 0.1.0, 0.2.0, 0.3.0 | ~43 |
| RTVModLogger | n/a (only 3 entries) | — | 0 |
| PunisherGuarantee | n/a (single 0.1.0) | — | 0 |
| RTVHideoutLights | n/a (unpublished) | — | 0 |

### Mechanics

For each mod where the cutoff is meaningful:

1. `tools/prune_changelogs.py CatAutoFeed --cutoff 1.0.0 --dry-run` shows what
   would move.
2. Without `--dry-run`, the script:
   - Reads `CHANGELOG.md`
   - Splits into entries by `## <version>` headers
   - Moves entries with version `< 1.0.0` to a new `CHANGELOG_archive.md` at
     the front (most recent first, matching CHANGELOG.md ordering)
   - Writes a new `CHANGELOG.md` containing only entries `>= 1.0.0`
   - Adds a footer line to `CHANGELOG.md`: `*Earlier history archived in
     [CHANGELOG_archive.md](CHANGELOG_archive.md).*`
   - Writes `.changelog_cutoff` containing the cutoff version
3. Human commits the cleanup as one PR per mod (so we can revert one without
   touching the others).

### Going forward

Audit check B12 enforces the cutoff. If a future PR re-introduces a 0.x
entry, audit fails on the next release. Adding entries above the cutoff is
unaffected.

### Why preserve in-repo (not just rely on git history)

User feedback: "yes preserve the old changelog." Reasons that match:
- Browsable on GitHub without `git log` archaeology.
- Continues to be referenced from the live in-repo CHANGELOG via the footer
  link, so consumers can still find historical context.
- No stale links break (existing tag-bound release pages still resolve to
  pre-prune CHANGELOG snapshots in git history; only `main` HEAD changes).

### What lands on ModWorkshop after pruning

The user posts the full body of `CHANGELOG.md` to ModWorkshop's changelog tab
on every update. After pruning:

- CatAutoFeed: 272 → ~189 lines (~30% lighter)
- RTVWallets: 102 → ~59 lines (~42% lighter)
- RTVModLogger: unchanged

The archive file is **not** posted to ModWorkshop. It's just for in-repo
historical reading.

---

## 6. Immediate fix punch-list (precedes audit build)

These are drift findings already in flight. Cleanest order: fix these now in
small PRs so the first audit run shows mostly green.

### 🔴 Player-visible (worth shipping as `CatAutoFeed 1.1.7` patch)

1. **CatAutoFeed `config.gd` line 77 tooltip** still says `"rarity Legendary,
   ~1 in 120 containers"`. Demote tooltip to match 1.1.6's actual rarity
   change. One-line fix + CHANGELOG entry.

### 🟡 Doc-only (one PR, all mods)

2. **Workspace-root README** `Mod Releases` table: bump CatAutoFeed row from
   `1.1.4` → `1.1.6` and update tag link.
3. **CatAutoFeed README MCM table** missing `Auto-Feed Even In Cat's Shelter`
   row. (Already added on `docs/cat-readme-shelter-toggle` branch — Features
   bullet only. The MCM table row addition needs to ride with it.)
4. **All three published mods' `PUBLISH_NOTES.md`**: check off completed
   post-publish TODOs (`[x] First publish via ModWorkshop`, `[x] write mod id
   to .publish`).
5. **CatAutoFeed `PUBLISH_NOTES.md`**: update "Pre-publish state: v1.1.0
   frozen" → 1.1.6, fix screenshot count "8 MCM toggles" → 9.
6. **RTVModLogger `config.gd`** `_apply()` fallback default for
   `welcome_on_start`: `true` → `false` to match schema and README.
7. **RTVHideoutLights `mod.txt`**: add descriptive comment to bare
   `[registry]` block to match CatAutoFeed/RTVWallets convention.

### 🟢 In-progress (defer until RTVHideoutLights is publish-ready)

8. RTVHideoutLights NOTICES.txt: fill out attributions for any third-party
   icons; document game-extracted asset convention.
9. RTVHideoutLights README: replace TODO placeholders in intro / Features /
   Compatibility sections.
10. RTVHideoutLights orphan icons: 7 PNGs in `assets/icons/` with no matching
    `.tres` item. Either implement the items or delete the orphans before
    publish (they bloat the `.vmz`).

---

## 7. Phased build order

Each phase delivers value standalone. Stop at any phase boundary if priorities
shift.

| Phase | Deliverable | Effort | Dep on prev? |
|---|---|---|---|
| **0** | Land §6 fixes 1–7 (manual cleanup) | ~1 hr | — |
| **1** | `tools/audit_release.py` with checks A1–A4, B1–B9 (in-repo only) + `audit.bat` wrapper | ~3 hrs | — |
| **2** | Wire `audit_release.py` into `publish.bat` (Gate A on no-open, Gate B on default, `--force` honoured) | ~30 min | Phase 1 |
| **3** | Extend `modworkshop.py` with `info --field desc`/`--field changelog` (returns the raw API body fields), add audit checks B10/B11 with directional drift handling, optionally `--paste-bodies` to print local README+CHANGELOG ready for the MW upload form | ~2-3 hrs | Phase 1 |
| **4** | `tools/prune_changelogs.py` + run it once on CatAutoFeed and RTVWallets, write `.changelog_cutoff` files | ~2 hrs | — (parallel with Phase 1) |
| **5** | Add audit check B12 (enforce `.changelog_cutoff`) | ~30 min | Phase 1 + Phase 4 |
| **6** | RTVHideoutLights doc cleanup (§6 items 8–10) when mod approaches publish | ~? | RTVHideoutLights ready |

Total core build: roughly one focused session (Phases 1–5). Phase 0 should
land before Phase 1 so the first audit run is green-by-default.

---

## 8. Design principles

- **Discovery-driven, not config-driven.** Walk `mods/*/mod.txt`. Adding a
  new mod requires zero changes to audit_release.py.
- **Read-only by default.** Audit reports problems. Auto-fix is opt-in per
  category via future flags (e.g. `--fix-publish-notes` could check off TODOs
  the audit identified). Never silent edits.
- **Conventions, not config.** Where checks need structural assumptions
  (config.gd `SCHEMA` dict, NOTICES line format), the convention is documented
  in CLAUDE.md and enforced by `scaffold_mod.py`. Mods that break the
  convention get a clear "non-standard shape" message, not a silent skip.
- **Idempotent.** Re-running audit with no changes between produces identical
  output. Easy to wire into git hooks or CI later.
- **One-shot scripts and re-runnable scripts are different files.**
  `prune_changelogs.py` is one-shot per mod (re-running on a pruned
  CHANGELOG is a no-op). `audit_release.py` is re-runnable forever.
- **No emoji-as-status without a fallback.** Audit output uses `PASS / FAIL /
  WARN` text labels; CI / log-file readers don't always render emoji
  reliably.

---

## 9. Out of scope (deliberate non-goals)

- **Auto-pushing audit-fix commits.** Per memory: don't auto-push branches.
  Audit reports problems; fixes are the user's call.
- **Auto-uploading to ModWorkshop.** Already manual per ModWorkshop API
  (GET-only). The audit just makes sure local state is publish-ready.
- **Cross-mod consistency checks** (e.g. "all CHANGELOGs use the same
  date format"). Each mod is audited independently. If a cross-mod convention
  is worth enforcing, it goes in `scaffold_mod.py`, not the auditor.
- **Code-quality checks** (style, type hints, GDScript linting). The audit is
  about doc and metadata drift, not code health.
- **Game-side checks** (does the mod actually run, do textures load). Game
  testing is out of band; the audit is documentation hygiene.

---

## 10. Open questions to resolve when building

These are punted intentionally. Don't block the plan on them; revisit during
the relevant phase.

- **Phase 1 — "non-standard config.gd shape" fallback.** When the auditor
  can't parse a config.gd schema, do we (a) skip MCM checks for that mod with
  a clear message, or (b) fail the audit? Default plan: (a), with a
  one-line WARN noting the parser couldn't read it.
- **Phase 2 — `publish.bat --release` vs default.** Does Gate B fire by
  default (omitting `--no-open`), or does it require an explicit `--release`
  flag? Default plan: fire by default, keep the existing flag surface clean.
- **Phase 3 — ModWorkshop API rate limits.** If the audit fetches `desc` and
  `changelog` for every published mod on every Gate B run, are we polite to
  the API? Likely fine (3 mods × 2 fields = 6 GETs per run, not a sweep), but
  cache the responses for the run duration to avoid double-fetching the same
  field across checks B10 and B11.
- **Phase 4 — pruning the GitHub Releases page descriptions.** GitHub
  releases for v0.x tags exist with their own copy of the old CHANGELOG
  excerpt. Do we edit those? Default plan: no — they're frozen historical
  artefacts, and the new in-repo `CHANGELOG_archive.md` is the canonical
  archive going forward.

---

## 11. What success looks like

After Phase 5:

- `audit.bat --all --release` reports green across all 4 published mods.
- `publish.bat <Mod> --version X.Y.Z` runs Gate B automatically before
  opening ModWorkshop. If anything's drifted, you see it before clicking
  upload.
- Every new mod scaffolded via `scaffold_mod.py` is audit-ready by default.
- CatAutoFeed CHANGELOG is ~30% shorter on ModWorkshop. RTVWallets ~42%.
  RTVModLogger unchanged. Old history is preserved at
  `mods/<Mod>/CHANGELOG_archive.md`.
- The next time we ship a CatAutoFeed patch (1.1.7 for the rarity-tooltip
  fix), the audit catches the workspace-README row before it goes stale.

---

## 12. Research provenance

Findings backed by two research agents on 2026-05-01:

- **In-repo drift agent** (Explore subagent): scanned all 5 mods across 8
  check categories. Output: per-mod findings + top-10 list. Surfaced the
  CatAutoFeed Legendary tooltip bug, workspace README staleness, MCM
  table/Features gap, PUBLISH_NOTES staleness, RTVModLogger fallback default
  mismatch, RTVHideoutLights NOTICES void.
- **ModWorkshop body agent** (general-purpose subagent): pulled `desc` and
  `changelog` fields for the 3 published mods via `modworkshop.bat info`.
  Surfaced the two-field structure (the body is split across `desc` and
  `changelog` tabs, not concatenated), bidirectional drift direction
  (CatAutoFeed live ahead of repo, RTVWallets repo ahead of live), and the
  `modworkshop.bat info` blind spot.

Both reports archived in conversation history, not committed to the repo.
