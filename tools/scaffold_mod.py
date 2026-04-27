#!/usr/bin/env python3
"""Scaffold a new mod folder with the workspace's standard layout.

Drops a complete `mods/<MOD_ID>/` folder containing mod.txt, Main.gd,
config.gd, Logger.gd stub (synced via sync_logger.py at the end), build.py
matching the canonical workspace pattern, README.md, CHANGELOG.md, LICENSE,
PUBLISH_NOTES.md, and screenshots/README.md. Optionally adds an `assets/`
folder + NOTICES.txt template (--assets) and a DatabaseInject.gd stub +
registry-aware Main.gd injection (--items).

Usage:
    python tools/scaffold_mod.py "My New Mod"
    python tools/scaffold_mod.py "Cat Tower" --assets
    python tools/scaffold_mod.py "Better Loot" --items --desc "Smarter loot tables"
    python tools/scaffold_mod.py "Mega Mod" --id MegaMod --assets --items

Inputs:
    NAME              Display name (e.g. "RTV Wallets"). Required.
    --id ID           Folder/autoload id. Defaults to NAME with spaces stripped.
    --desc TEXT       One-liner tagline. Defaults to "TODO: one-line tagline."
    --assets          Create assets/ folder + NOTICES.txt template.
                      Adds NOTICES.txt to build.py's ROOT_FILES.
    --items           Create DatabaseInject.gd stub + registry-aware Main.gd.
                      For mods that add new items to the vanilla Database.
    --dry-run         Print what would be created without writing.
    --no-sync-logger  Skip auto-invoking sync_logger.py at the end.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
MODS_DIR = REPO_ROOT / "mods"
SYNC_LOGGER = REPO_ROOT / "tools" / "sync_logger.py"
SHARED_LOGGER = REPO_ROOT / "shared" / "Logger.gd"


# ---------- templates -------------------------------------------------------

MOD_TXT = """\
[mod]
name="__MOD_NAME__"
id="__MOD_ID__"
version="0.1.0"

[autoload]
__MOD_ID__Log="res://mods/__MOD_ID__/Logger.gd"
__MOD_ID__Config="res://mods/__MOD_ID__/config.gd"
__MOD_ID__="res://mods/__MOD_ID__/Main.gd"
"""


# Appended to mod.txt when --items is set. Opts the mod into Metro Mod
# Loader v3.x's registry: Metro wraps Database.gd at loader startup so
# lib.register(lib.Registry.SCENES, ...) calls in Main.gd take effect.
MOD_TXT_REGISTRY_SUFFIX = """\

[registry]
"""


# Stub Logger.gd: sync_logger.py keeps the three identity vars in _init()
# and replaces the rest with the canonical body from shared/Logger.gd.
LOGGER_STUB = """\
extends Node

# Identity for this mod's logger instance. The body of this file is synced
# from shared/Logger.gd by tools/sync_logger.py — these three vars in
# _init() are the only thing preserved across syncs.

var mod_id: String
var mod_display_name: String
var log_filename: String

func _init() -> void:
\tmod_id = "__MOD_ID__"
\tmod_display_name = "__MOD_NAME__"
\tlog_filename = "__LOG_FILENAME__.log"
"""


MAIN_GD_BASIC = """\
extends Node

var _log_node: Node = null

func _ready() -> void:
\tname = "__MOD_ID__"
\t_log("debug", "__MOD_NAME__ mod loaded")
\t# TODO: add your mod's startup logic here.

func _log(lvl: String, msg: String) -> void:
\tif _log_node == null or !is_instance_valid(_log_node):
\t\t_log_node = get_node_or_null("/root/__MOD_ID__Log")
\t\tif _log_node == null:
\t\t\t_log_node = get_tree().root.find_child("__MOD_ID__Log", true, false)
\tif _log_node:
\t\t_log_node.call(lvl, msg)
\telse:
\t\tprint("[__MOD_ID__] [", lvl.to_upper(), "] ", msg)
"""


MAIN_GD_ITEMS = """\
extends Node

# Paths to .tres ItemData resources for any loot-table integration you do.
const ITEM_PATHS := [
\t# "res://mods/__MOD_ID__/MyItem.tres",
]

var _log_node: Node = null

func _ready() -> void:
\tname = "__MOD_ID__"
\t_log("debug", "__MOD_NAME__ mod loaded")
\t_register_with_metro()

# Registers each item scene as a SCENES entry via Metro's registry API.
# Metro v3.x wraps Database.gd at loader startup when [registry] is declared
# in mod.txt, so Database.get("<name>") resolves to the registered scene.
# Requires Metro Mod Loader v3.0.0 or later — without it, items will not
# resolve and the mod will warn at startup.
func _register_with_metro() -> void:
\tvar lib = Engine.get_meta("RTVModLib") if Engine.has_meta("RTVModLib") else null
\tif lib == null:
\t\t_log("error", "Metro Mod Loader not detected — items will not be registered. Install Metro v3.x or newer.")
\t\treturn
\tawait lib.frameworks_ready

\t# TODO: register each item here, e.g.:
\t# var ok := lib.register(lib.Registry.SCENES, "MyItem", preload("res://mods/__MOD_ID__/MyItem.tscn"))
\t# if ok:
\t#\t_log("debug", "MyItem registered with Metro (SCENES)")
\t# else:
\t#\t_log("warn", "Metro rejected MyItem SCENES registration (id collision?)")
\t#
\t# Optional: also register an item in a loot table so it spawns in the world:
\t# var item_data = load("res://mods/__MOD_ID__/MyItem.tres")
\t# lib.register(lib.Registry.LOOT, "__MOD_ID___myitem_master", {
\t#\t"item": item_data,
\t#\t"table": "LT_Master",
\t# })
\tpass

func _log(lvl: String, msg: String) -> void:
\tif _log_node == null or !is_instance_valid(_log_node):
\t\t_log_node = get_node_or_null("/root/__MOD_ID__Log")
\t\tif _log_node == null:
\t\t\t_log_node = get_tree().root.find_child("__MOD_ID__Log", true, false)
\tif _log_node:
\t\t_log_node.call(lvl, msg)
\telse:
\t\tprint("[__MOD_ID__] [", lvl.to_upper(), "] ", msg)
"""


CONFIG_GD = """\
extends Node

const MOD_ID := "__MOD_ID__"
const MOD_NAME := "__MOD_NAME__"
const FILE_PATH := "user://MCM/__MOD_ID__"

var enabled := true

var _mcm_helpers = null

func _ready() -> void:
\tname = "__MOD_ID__Config"

\t_mcm_helpers = load("res://ModConfigurationMenu/Scripts/Doink Oink/MCM_Helpers.tres")

\tvar config := ConfigFile.new()

\tconfig.set_value("Category", "General", { "menu_pos": 1 })

\tconfig.set_value("Bool", "enabled", {
\t\t"name" = "Enable __MOD_NAME__",
\t\t"tooltip" = "Master toggle for the __MOD_NAME__ mod.",
\t\t"default" = true,
\t\t"value" = true,
\t\t"category" = "General",
\t\t"menu_pos" = 1,
\t})

\tvar logger = _resolve_logger()
\tif logger:
\t\tlogger.attach_to_mcm_config(config, "Logging", 100)

\t_merge_schema(config, FILE_PATH + "/config.ini")

\tif _mcm_helpers == null:
\t\t_apply(config)
\t\treturn

\t_mcm_helpers.CheckConfigurationHasUpdated(MOD_ID, config, FILE_PATH + "/config.ini")
\t_apply(config)

\t_mcm_helpers.RegisterConfiguration(
\t\tMOD_ID,
\t\tMOD_NAME,
\t\tFILE_PATH,
\t\t"__DESCRIPTION__",
\t\t{ "config.ini" = _apply }
\t)

# Silent schema migration — see mods/RTVModLogger/LOGGER.md "Handling schema changes".
func _merge_schema(fresh: ConfigFile, path: String) -> void:
\tvar dir := path.get_base_dir()
\tif !DirAccess.dir_exists_absolute(dir):
\t\tDirAccess.make_dir_recursive_absolute(dir)

\tif !FileAccess.file_exists(path):
\t\tfresh.save(path)
\t\treturn

\tvar disk := ConfigFile.new()
\tif disk.load(path) != OK:
\t\tfresh.save(path)
\t\treturn

\tfor section in fresh.get_sections():
\t\tfor key in fresh.get_section_keys(section):
\t\t\tif !disk.has_section_key(section, key):
\t\t\t\tcontinue
\t\t\tvar schema_entry = fresh.get_value(section, key)
\t\t\tvar disk_entry = disk.get_value(section, key)
\t\t\tif schema_entry is Dictionary and disk_entry is Dictionary and disk_entry.has("value"):
\t\t\t\tschema_entry["value"] = disk_entry["value"]
\t\t\t\tfresh.set_value(section, key, schema_entry)
\t\t\telif !(schema_entry is Dictionary):
\t\t\t\tfresh.set_value(section, key, disk_entry)

\tfresh.save(path)

func _apply(config: ConfigFile) -> void:
\tvar fresh := ConfigFile.new()
\tvar err := fresh.load(FILE_PATH + "/config.ini")
\tif err == OK:
\t\tconfig = fresh

\tenabled = config.get_value("Bool", "enabled", {"value": true})["value"]

\tvar logger = _resolve_logger()
\tif logger:
\t\tlogger.apply_from_config(config)

func _resolve_logger():
\tvar n = get_node_or_null("/root/__MOD_ID__Log")
\tif n == null:
\t\tn = get_tree().root.find_child("__MOD_ID__Log", true, false)
\treturn n
"""


BUILD_PY = '''\
#!/usr/bin/env python3
"""Package the __MOD_NAME__ mod into a .vmz archive.

Usage:
    python build.py                 # builds __MOD_ID__.vmz next to this script
    python build.py --install       # also copies to the game\'s mods/ folder
    python build.py --version 1.0.0 # bump mod.txt version before building
"""

from __future__ import annotations

import argparse
import re
import shutil
import sys
import zipfile
from pathlib import Path

MOD_ID = "__MOD_ID__"
ROOT_FILES = __ROOT_FILES__
MOD_FILES = __MOD_FILES__
__ASSET_DIRS_LINE__GAME_MODS_DIR = Path(r"C:\\Program Files (x86)\\Steam\\steamapps\\common\\Road to Vostok\\mods")
VERSION_RE = re.compile(r\'^(version\\s*=\\s*)"([^"]+)"\', re.MULTILINE)


def bump_version(mod_txt: Path, new_version: str) -> str:
    text = mod_txt.read_text()
    match = VERSION_RE.search(text)
    if not match:
        raise SystemExit(f"version= line not found in {mod_txt}")
    old_version = match.group(2)
    if old_version == new_version:
        print(f"Version already {new_version}, no change")
        return old_version
    new_text = VERSION_RE.sub(rf\'\\g<1>"{new_version}"\', text)
    mod_txt.write_text(new_text)
    print(f"Bumped version: {old_version} -> {new_version}")
    return old_version


def current_version(mod_txt: Path) -> str:
    match = VERSION_RE.search(mod_txt.read_text())
    return match.group(2) if match else "?"


def build(src_dir: Path, out_path: Path) -> None:
    mod_txt = src_dir / "mod.txt"
    if not mod_txt.exists():
        raise SystemExit(f"mod.txt not found at {mod_txt}")

    for f in MOD_FILES:
        if not (src_dir / f).exists():
            raise SystemExit(f"missing source file: {src_dir / f}")

    if out_path.exists():
        out_path.unlink()

    with zipfile.ZipFile(out_path, "w", zipfile.ZIP_DEFLATED) as z:
        for f in ROOT_FILES:
            path = src_dir / f
            if path.exists():
                z.write(path, arcname=f)
        for f in MOD_FILES:
            z.write(src_dir / f, arcname=f"mods/{MOD_ID}/{f}")
__ASSET_BUNDLE_BLOCK__
    print(f"Built {out_path} v{current_version(mod_txt)} ({out_path.stat().st_size} bytes)")


def install(vmz: Path) -> None:
    if not GAME_MODS_DIR.exists():
        raise SystemExit(f"game mods dir not found: {GAME_MODS_DIR}")
    dest = GAME_MODS_DIR / vmz.name
    shutil.copy2(vmz, dest)
    print(f"Installed to {dest}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--install", action="store_true", help="Copy the .vmz into the game\'s mods folder")
    parser.add_argument("--version", help="Bump mod.txt to this version before building (e.g. 1.0.0)")
    args = parser.parse_args()

    src = Path(__file__).resolve().parent
    out = src / f"{MOD_ID}.vmz"

    if args.version:
        bump_version(src / "mod.txt", args.version)

    build(src, out)
    if args.install:
        install(out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
'''


ASSET_BUNDLE_BLOCK = """\
        for asset_dir in ASSET_DIRS:
            asset_root = src_dir / asset_dir
            if not asset_root.is_dir():
                continue
            for path in sorted(asset_root.rglob("*")):
                if not path.is_file():
                    continue
                if path.name.startswith("."):
                    continue
                if "_1024" in path.name or "_master" in path.name:
                    continue
                if path.suffix.lower() in {".blend", ".blend1", ".psd", ".xcf"}:
                    continue
                rel = path.relative_to(src_dir)
                z.write(path, arcname=f"mods/{MOD_ID}/{rel.as_posix()}")

        # .godot/imported/ holds Godot's compiled textures and meshes.
        godot_imported = src_dir / ".godot" / "imported"
        if godot_imported.is_dir():
            for path in sorted(godot_imported.rglob("*")):
                if not path.is_file():
                    continue
                rel = path.relative_to(src_dir)
                z.write(path, arcname=rel.as_posix())
"""


README_MD = """\
# __MOD_NAME__

> __DESCRIPTION__

TODO: one or two paragraphs of player-facing context — what the mod does, why
it exists, the player's goal when using it.

## Installation

1. Drop `__MOD_ID__.vmz` into the game's `mods/` folder:
   `...\\steamapps\\common\\Road to Vostok\\mods\\`
2. Ensure a compatible mod loader is installed (e.g. [Metro Mod Loader](https://modworkshop.net/mod/55623), the most popular for Road to Vostok).
3. **Recommended:** also install Mod Configuration Menu (MCM) — needed to change settings in-game.
4. Launch the game.

## Features

- TODO: list the user-facing features.

## Configuration (MCM)

| Setting | Default | Description |
|---|---|---|
| Enable __MOD_NAME__ | On | Master toggle. |

Plus the standard Logger category (level, file output, overlay output). See [the RTV Mod Logger reference](../RTVModLogger/LOGGER.md) for details.

## Compatibility

- TODO: known conflicts and known compatibilities.
- **MCM is optional.** The mod runs with sensible defaults if MCM is absent.

## Credits

Built for the Road to Vostok modding ecosystem. In-game configuration via the [Mod Configuration Menu](https://modworkshop.net/mod/53713) by DoinkOink.

## License

[MIT](LICENSE)

## Source & Issues

Built in the [RoadToVostokMods workspace](https://github.com/dwoodruff83/RoadToVostokMods).
"""


CHANGELOG_MD = """\
# Changelog

All notable changes to the __MOD_NAME__ mod are documented here. Dates are
YYYY-MM-DD.

## 0.1.0 — __TODAY__

Initial scaffold.

- TODO: describe the first set of working features as you build them.
"""


LICENSE_TEXT = """\
MIT License

Copyright (c) 2026 Daniel Woodruff

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"""


# Variant used when --assets is set: includes a carve-out paragraph noting
# that bundled third-party assets retain their own (typically CC BY 4.0)
# licenses, with NOTICES.txt as the source of truth for attributions.
LICENSE_TEXT_WITH_CARVEOUT = """\
MIT License

Copyright (c) 2026 Daniel Woodruff

This MIT License applies to the mod's source code only (.gd, .tscn, .tres,
.md, .py, .txt files authored by the copyright holder). Third-party assets
bundled in this package — see NOTICES.txt — are licensed separately under
their respective terms (Creative Commons Attribution 4.0 International).

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"""


PUBLISH_NOTES_MD = """\
# __MOD_NAME__ — publish notes

> Notes for whichever session/agent picks up the ModWorkshop publish work for this mod.
> Captures positioning, metadata, and a TODO list for the upload form.

## Status

**Recommended sequence:** TODO — slot this mod into the publish queue when it's ready.

## TL;DR pitch

> __DESCRIPTION__

## Competitor landscape

TODO: search ModWorkshop for adjacent mods. Use `modworkshop.bat search <keyword>`.
Document any direct competitors and how this mod differs.

## Positioning

TODO: one paragraph on the angle to lead with on the mod page.

## Recommended ModWorkshop metadata

| Field | Value |
|---|---|
| **Category** | TODO (check the dropdown) |
| **Tags** | `Add-on (#13)` plus any specific to your mod |
| **Dependencies** | __DEPS_LINE__ |
| **Repo URL** | (set when public) |
| **License** | MIT |

## Conflict callout

TODO: any incompatibilities to flag explicitly in the description so users don't blame this mod.

## ModWorkshop description outline

Draft from `README.md` — it's already publish-shaped. Adjust per the positioning above.

## TODO before publish

- [ ] Verify `mods/__MOD_ID__/build.py` builds: `publish.bat __MOD_ID__ --no-open`
- [ ] Bump version to 1.0.0 if features are stable (currently 0.1.0)
- [ ] Capture screenshots (see `screenshots/README.md` for the naming convention)
- [ ] Test on a clean profile with only this mod installed
- [ ] First publish via web form
- [ ] **Post-publish:** write assigned mod id into `mods/__MOD_ID__/.publish` AND
      add `[updates]\\nmodworkshop=<id>` to `mod.txt`, then rebuild + re-upload
      so the shipped `.vmz` is update-aware (see "Update flow" section below)

## Update flow (Metro Mod Loader)

Metro Mod Loader has a built-in **Updates** tab that auto-checks ModWorkshop and offers a
one-click Download button per mod. To opt in, `mod.txt` must include both:

```
[mod]
version="1.0.0"

[updates]
modworkshop=<mod_id>
```

Then on each release:

1. Bump `version=` (or pass `--version X.Y.Z` to `publish.bat`)
2. Build the new `.vmz`
3. **Upload to the existing ModWorkshop mod page (replace the file, do NOT create a new mod)**
4. Users hit Check on the loader's Updates tab → see "update: vX.Y.Z" → click Download

No separate "submit" or external changelog log is required — the ModWorkshop page IS the
source of truth.

## References

- User-facing docs: [README.md](README.md)
- Changelog: [CHANGELOG.md](CHANGELOG.md)
- Source: [Main.gd](Main.gd)
- Workspace publish workflow: see `publish.bat` in workspace root
"""


SCREENSHOTS_README = """\
# Screenshots

Source images for the ModWorkshop upload. Not packaged into the `.vmz`.

## Naming convention

| File | Purpose |
|---|---|
| `01_overview.png` | Hero / featured image. The most representative single shot. |
| `02_mcm.png` | The mod's MCM page (Configuration Menu integration). |
| `03_…` onward | Specific features, in priority order. |

PNG preferred. Aim for 1280×720 or higher; ModWorkshop downscales automatically.
"""


NOTICES_TXT = """\
__MOD_NAME__ — Third-Party Asset Notices
__UNDERLINE__

This mod includes content created by third parties. Original license terms
are preserved below, verbatim.

---

3D Models
---------

(TODO: paste CC BY 4.0 attributions for each Sketchfab model used. Format:)

"<Model Name>" (https://skfb.ly/<id>) by <Author> is licensed under Creative Commons
Attribution (http://creativecommons.org/licenses/by/4.0/).

Modifications: model imported into Godot; <list any geometry/texture edits>.
"""


# ---------- helpers ---------------------------------------------------------


def derive_mod_id(name: str) -> str:
    """Default mod_id: strip non-alphanumeric chars from the display name."""
    cleaned = re.sub(r"[^A-Za-z0-9]", "", name)
    if not cleaned:
        raise SystemExit(f"Cannot derive a valid mod_id from '{name}'. Pass --id explicitly.")
    if not cleaned[0].isalpha():
        raise SystemExit(f"mod_id '{cleaned}' must start with a letter. Pass --id explicitly.")
    return cleaned


def derive_log_filename(mod_id: str) -> str:
    """CamelCase → snake_case for the .log filename."""
    s = re.sub(r"(.)([A-Z][a-z]+)", r"\1_\2", mod_id)
    s = re.sub(r"([a-z0-9])([A-Z])", r"\1_\2", s)
    return s.lower()


def render(template: str, replacements: dict[str, str]) -> str:
    out = template
    for key, value in replacements.items():
        out = out.replace(key, value)
    return out


def write_file(path: Path, content: str, dry_run: bool) -> None:
    if dry_run:
        print(f"[dry-run] would write {path} ({len(content)} bytes)")
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")
    print(f"  wrote {path.relative_to(REPO_ROOT)}")


# ---------- main ------------------------------------------------------------


def main() -> int:
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("name", help='Display name (e.g. "RTV Wallets")')
    parser.add_argument("--id", help="Folder/autoload id (default: name with spaces stripped)")
    parser.add_argument("--desc", default="TODO: one-line tagline.", help="One-line tagline")
    parser.add_argument("--assets", action="store_true", help="Create assets/ folder + NOTICES.txt template + LICENSE carve-out")
    parser.add_argument("--items", action="store_true", help="Use Metro v3.x's [registry] API in mod.txt + a Main.gd that registers items as SCENES")
    parser.add_argument("--dry-run", action="store_true", help="Print what would be created without writing")
    parser.add_argument("--no-sync-logger", action="store_true", help="Skip auto-invoking sync_logger.py")
    args = parser.parse_args()

    mod_id = args.id if args.id else derive_mod_id(args.name)
    mod_dir = MODS_DIR / mod_id

    if mod_dir.exists() and not args.dry_run:
        print(f"error: {mod_dir} already exists. Pick a different --id or remove the folder first.", file=sys.stderr)
        return 2

    log_filename = derive_log_filename(mod_id)

    from datetime import date
    today = date.today().isoformat()

    if args.items:
        deps_line = "**`Metro Mod Loader (#55623)` v3.0.0+ required** (uses Metro's `[registry]` API); `MCM (#53713)` recommended"
    else:
        deps_line = "`Metro Mod Loader (#55623)` required; `MCM (#53713)` recommended"

    repl = {
        "__MOD_ID__": mod_id,
        "__MOD_NAME__": args.name,
        "__DESCRIPTION__": args.desc,
        "__LOG_FILENAME__": log_filename,
        "__TODAY__": today,
        "__DEPS_LINE__": deps_line,
    }

    # Compose build.py with conditional ROOT_FILES / MOD_FILES / asset block.
    root_files = ["mod.txt", "README.md", "CHANGELOG.md", "LICENSE"]
    if args.assets:
        root_files.insert(-1, "NOTICES.txt")
    mod_files = ["Main.gd", "config.gd", "Logger.gd"]

    build_repl = dict(repl)
    build_repl["__ROOT_FILES__"] = repr(root_files)
    build_repl["__MOD_FILES__"] = repr(mod_files)
    if args.assets:
        build_repl["__ASSET_DIRS_LINE__"] = 'ASSET_DIRS = ["assets"]\n'
        build_repl["__ASSET_BUNDLE_BLOCK__"] = ASSET_BUNDLE_BLOCK
    else:
        build_repl["__ASSET_DIRS_LINE__"] = ""
        build_repl["__ASSET_BUNDLE_BLOCK__"] = ""

    print(f"\nScaffolding mod '{args.name}' at {mod_dir}")
    print(f"  id={mod_id}  log={log_filename}.log  assets={args.assets}  items={args.items}\n")

    main_gd = MAIN_GD_ITEMS if args.items else MAIN_GD_BASIC
    mod_txt_content = render(MOD_TXT, repl)
    if args.items:
        mod_txt_content += MOD_TXT_REGISTRY_SUFFIX
    license_text = LICENSE_TEXT_WITH_CARVEOUT if args.assets else LICENSE_TEXT

    files: list[tuple[Path, str]] = [
        (mod_dir / "mod.txt",                mod_txt_content),
        (mod_dir / "Logger.gd",              render(LOGGER_STUB,        repl)),
        (mod_dir / "Main.gd",                render(main_gd,            repl)),
        (mod_dir / "config.gd",              render(CONFIG_GD,          repl)),
        (mod_dir / "build.py",               render(BUILD_PY,           build_repl)),
        (mod_dir / "README.md",              render(README_MD,          repl)),
        (mod_dir / "CHANGELOG.md",           render(CHANGELOG_MD,       repl)),
        (mod_dir / "LICENSE",                license_text),
        (mod_dir / "PUBLISH_NOTES.md",       render(PUBLISH_NOTES_MD,   repl)),
        (mod_dir / "screenshots" / "README.md", SCREENSHOTS_README),
    ]

    if args.assets:
        underline_repl = dict(repl)
        underline_repl["__UNDERLINE__"] = "=" * (len(args.name) + len(" — Third-Party Asset Notices"))
        files.append((mod_dir / "NOTICES.txt", render(NOTICES_TXT, underline_repl)))
        # placeholder so git/IDE see the assets dir
        files.append((mod_dir / "assets" / ".gitkeep", ""))

    for path, content in files:
        write_file(path, content, args.dry_run)

    if args.dry_run:
        print("\n(dry-run, no files written)")
        return 0

    # Sync the canonical Logger.gd body in.
    if not args.no_sync_logger:
        if not SHARED_LOGGER.exists():
            print(f"\nwarning: {SHARED_LOGGER} not found; skipping sync_logger.py", file=sys.stderr)
        else:
            print("\nSyncing canonical Logger.gd body...")
            result = subprocess.run(
                [sys.executable, str(SYNC_LOGGER), mod_id],
                cwd=REPO_ROOT,
            )
            if result.returncode != 0:
                print("warning: sync_logger.py failed; Logger.gd is still a stub", file=sys.stderr)

    print(f"\nDone. Next steps for {mod_id}:")
    print(f"  1. Edit mods/{mod_id}/Main.gd and add your startup logic")
    print(f"  2. Edit mods/{mod_id}/config.gd to add MCM toggles for your features")
    if args.items:
        print(f"  3. Add your .tres / .tscn item files under mods/{mod_id}/")
        print(f"  4. Wire up lib.register(lib.Registry.SCENES, ...) calls in Main.gd._register_with_metro()")
        print(f"     (Metro v3.0+ required — the [registry] opt-in is already in mod.txt)")
    if args.assets:
        print(f"  5. Drop 3D models / icons into mods/{mod_id}/assets/")
        print(f"  6. Fill in NOTICES.txt with attributions for any third-party assets")
    print(f"  Build & install:  publish.bat {mod_id} --no-open")
    print(f"  When ready to publish: publish.bat {mod_id} --version 1.0.0")
    return 0


if __name__ == "__main__":
    sys.exit(main())
