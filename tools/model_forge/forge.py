#!/usr/bin/env python3
"""forge.py — turn GTA V (Legacy) clothing drawables into FiveM-streamable models.

Reads the game's RPF archives directly through szio/PyMateria, extracts one
drawable from a .ydd, writes it as a .ydr, and copies the matching diffuse .ytd
next to it under the output name the engine will look for.

Usage examples
--------------
  # Scan the indexed archives once (base game + every DLC)
  python forge.py --reindex

  # List available models for a slot (drawable/texture combinations)
  python forge.py --list --slot hat

  # A vanilla male jacket: component "jbib", drawable 0, texture 0
  python forge.py --slot tops --drawable 0 --texture 0 --resource ..\\whip_clothingwheel

  # A female mask, written to an explicit stream/ folder
  python forge.py --slot mask --drawable 3 --texture 1 --sex female --out .\\stream

  # A DLC hat whose .ydd filename is p_head_012_a.ydd
  python forge.py --slot hat --file p_head_012_a.ydd --texture 2 --resource ...

The tool never writes inside the game folder. Output is a .ydr + .ytd pair plus
a manifest.json, ready to be copied into a FiveM resource's stream/ directory.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import time
from pathlib import Path

from szio import VPath, save_asset, try_load_asset
from szio.gta5.assets import AssetFormat, AssetTarget, AssetVersion, SaveOptions

DEFAULT_GAME = r"G:\Games\Epic Games\GTAV"
HERE = Path(__file__).resolve().parent
INDEX_PATH = HERE / "rpf_index.json"

# Slot id -> (kind, ydd prefix, ytd prefix).
# `kind` is "component" or "prop" and is only informational for the manifest.
# Prefixes are the vanilla freemode naming; override with --prefix/--texprefix.
SLOT_PREFIX = {
    "hat": ("prop", "p_head", "p_head"),
    "glasses": ("prop", "p_eyes", "p_eyes"),
    "ear": ("prop", "p_ears", "p_ears"),
    "watch": ("prop", "p_rwrist", "p_rwrist"),
    "bracelet": ("prop", "p_lwrist", "p_lwrist"),
    "mask": ("component", "berd", "berd"),
    "tops": ("component", "jbib", "jbib"),
    "undershirt": ("component", "uppr", "uppr"),
    "shoes": ("component", "feet", "feet"),
    "accessory": ("component", "accs", "accs"),
    "armor": ("component", "task", "task"),
    "decal": ("component", "decl", "decl"),
    "bag": ("component", "hand", "hand"),
    "legs": ("component", "lowr", "lowr"),
    "arms": ("component", "jbib", "jbib"),
}

# GTA texture-variation index -> filename letter (a=0, b=1, ...).
TEX_LETTERS = "abcdefghijklmnopqrstuvwxyz"


def build_index(game: Path) -> dict[str, list[str]]:
    """Scan every RPF once and remember where each YDD/YTD lives."""
    print(f"[index] scanning {game}", flush=True)
    index: dict[str, list[str]] = {}
    t0 = time.time()
    rpf_files = sorted(str(p.relative_to(game)).replace("\\", "/") for p in game.rglob("*.rpf"))
    print(f"[index] {len(rpf_files)} RPF archives", flush=True)
    for rel in rpf_files:
        root = VPath(str(game), rel)
        try:
            for entry in root.rglob("*"):
                if not entry.is_file():
                    continue
                name = entry.name.lower()
                if name.endswith((".ydd", ".ytd")):
                    index.setdefault(name, []).append(str(entry))
        except Exception as exc:  # a corrupt/optional RPF should not kill the scan
            print(f"[index] skipped {rel}: {exc}", flush=True)
    index = {k: sorted(v) for k, v in index.items()}
    INDEX_PATH.write_text(json.dumps(index, indent=1, sort_keys=True), encoding="utf-8")
    print(f"[index] {len(index)} files in {round(time.time() - t0, 1)}s -> {INDEX_PATH}", flush=True)
    return index


def load_index(game: Path, force: bool = False) -> dict[str, list[str]]:
    if force or not INDEX_PATH.exists():
        return build_index(game)
    return json.loads(INDEX_PATH.read_text(encoding="utf-8"))


def find_in_rpf(index: dict[str, list[str]], filename: str, prefer: str = "") -> VPath | None:
    """Find a file, preferring freemode ped paths over NPC/DLC duplicates."""
    key = filename.lower()
    matches = list(index.get(key, []))
    if not matches:
        matches = [p for k, paths in index.items() if k.endswith(key) for p in paths]
    if not matches:
        return None

    needle = prefer.lower().replace("\\", "/")

    def score(path: str) -> tuple[int, str]:
        p = path.lower().replace("\\", "/")
        s = 0
        if needle and needle in p:
            s -= 1000
        if "mp_m_freemode_01" in p:
            s -= 500
        if "mp_f_freemode_01" in p:
            s -= 500
        if "streamedpeds_mp.rpf" in p or "streamedpedprops.rpf" in p:
            s -= 200
        if "/ig_" in p or "_ig.rpf" in p:
            s += 100
        if "_g9ec" in p:
            s += 50
        return (s, p)

    return VPath(sorted(matches, key=score)[0])


def drawable_index_from_filename(filename: str) -> int | None:
    """Extract the 3-digit drawable index from e.g. p_head_012_a.ydd."""
    m = re.search(r"_(\d{2,3})(?:_[a-z])?\.ydd$", filename.lower())
    return int(m.group(1)) if m else None


def list_models(index: dict[str, list[str]], prefix: str, kind: str, sex: str) -> None:
    """Print sorted drawable filenames for a slot prefix."""
    prefer = "mp_m_freemode_01" if sex == "male" else "mp_f_freemode_01"
    needle = "mp_f_" if sex == "female" else "mp_m_"
    files: dict[str, list[str]] = {}
    for name, paths in index.items():
        if not name.endswith(".ydd"):
            continue
        stem = name[:-4]
        if kind == "prop":
            matched = (
                stem.startswith(f"{prefix}_")
                or re.match(rf"^{re.escape(prefix)}_\d{{2,3}}(?:_[a-z])?$", stem)
            )
        else:
            matched = stem.startswith(f"{prefix}_")
        if matched:
            files[name] = paths

    def score(path: str) -> tuple[int, str]:
        p = path.lower().replace("\\", "/")
        s = 0
        if needle in p:
            s -= 1000
        if "mp_m_freemode_01" in p or "mp_f_freemode_01" in p:
            s -= 500
        if "streamedpeds_mp.rpf" in p or "streamedpedprops.rpf" in p:
            s -= 200
        if "/ig_" in p or "_ig.rpf" in p:
            s += 100
        if "_g9ec" in p:
            s += 50
        return (s, p)

    print(f"[list] {len(files)} .ydd files for prefix={prefix} kind={kind} sex={sex}")
    for name in sorted(files, key=lambda n: (drawable_index_from_filename(n) or 0, n)):
        best = sorted(files[name], key=score)[0]
        idx = drawable_index_from_filename(name)
        print(f"  {name:32s} drawable={idx if idx is not None else '?':>4}  {best}")


def extract_drawable(path: VPath, wanted: int, out: Path, model_name: str) -> Path | None:
    loaded = try_load_asset(path, return_target=True)
    if not loaded:
        print(f"[error] cannot load {path}", flush=True)
        return None
    asset, target = loaded
    drawables = getattr(asset, "drawables", None)
    if not drawables:
        print(f"[error] no drawables in {path}", flush=True)
        return None

    keys = list(drawables.keys())
    if len(keys) == 1:
        # I .ydd dei prop freemode (p_head_005.ydd, p_eyes_000.ydd, ...) hanno
        # una sola entry: il numero nel nome file È il drawable index. Prendere
        # l'entry [wanted] qui sarebbe un errore (wanted=5 su un file con 1
        # drawable): il vecchio export creava così caschi DLC al posto dei
        # cappelli base.
        key = keys[0]
    elif wanted < len(keys):
        key = keys[wanted]
    else:
        key = keys[0]
        print(f"[warn] drawable {wanted} not found, using {key}", flush=True)
    drawable = drawables[key]
    print(
        f"[ydr] source={path.name} entry={key} name={getattr(drawable, 'name', '?')} "
        f"target={target.version.name}",
        flush=True,
    )
    save_asset(
        drawable,
        [AssetTarget(AssetFormat.NATIVE, AssetVersion.GEN8)],
        out,
        model_name,
        SaveOptions(),
    )
    return out / f"{model_name}.ydr"


def extract_texture(
    index: dict[str, list[str]], filename: str, out: Path, model_name: str, prefer: str = ""
) -> Path | None:
    path = find_in_rpf(index, filename, prefer)
    if path is None:
        print(f"[warn] texture {filename} not found; model may render pink", flush=True)
        return None
    loaded = try_load_asset(path, return_target=True)
    if not loaded:
        print(f"[warn] cannot load texture {path}", flush=True)
        return None
    asset, _ = loaded
    save_asset(
        asset,
        [AssetTarget(AssetFormat.NATIVE, AssetVersion.GEN8)],
        out,
        model_name,
        SaveOptions(),
    )
    print(f"[ytd] source={path.name} -> {model_name}.ytd", flush=True)
    return out / f"{model_name}.ytd"


def append_config(resource: Path, slot: str, drawable: int, model: str) -> None:
    """Add or replace the model entry for a slot in Config.DropModels."""
    config = resource / "config.lua"
    if not config.exists():
        print(f"[warn] {config} not found; skipping config update", flush=True)
        return
    text = config.read_text(encoding="utf-8")
    marker = "Config.DropModels = {"
    start = text.find(marker)
    if start == -1:
        print(f"[warn] {marker} not found in config.lua", flush=True)
        return
    # Find the matching closing brace of the DropModels table.
    depth = 0
    end = -1
    for i in range(start + len(marker) - 1, len(text)):
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
            if depth == 0:
                end = i + 1
                break
    if end == -1:
        print("[warn] cannot find end of Config.DropModels", flush=True)
        return

    block = text[start:end]
    key = f"['{drawable}']"
    pattern = re.compile(
        rf"(?m)^([ \t]*){re.escape(slot)}\s*=\s*\{{(.*?)^\1\}}",
        re.DOTALL,
    )

    def repl(match: re.Match[str]) -> str:
        indent = match.group(1)
        body = match.group(2)
        if match.group(0).lstrip().startswith("--"):  # commented example
            return match.group(0)
        if re.search(re.escape(key) + r"\s*=", body):
            body = re.sub(
                re.escape(key) + r"(\s*=\s*)'[^']*'",
                lambda m: key + m.group(1) + f"'{model}'",
                body,
            )
        else:
            body = body.rstrip() + f"\n{indent}    {key} = '{model}',\n{indent}"
        return f"{indent}{slot} = {{{body}}}"

    new_block, count = pattern.subn(repl, block)
    if count == 0:
        close = block.rfind("}")
        new_block = block[:close] + f"    {slot} = {{\n        {key} = '{model}',\n    }},\n" + block[close:]
    new_text = text[:start] + new_block + text[end:]
    if new_text != text:
        config.write_text(new_text, encoding="utf-8")
        print(f"[config] {slot}{key} = '{model}' -> {config}", flush=True)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--game", default=DEFAULT_GAME, help="GTA V Legacy install folder")
    ap.add_argument("--slot", choices=sorted(SLOT_PREFIX), help="whip_clothingwheel slot id")
    ap.add_argument("--prefix", help="YDD prefix, e.g. jbib / berd / p_head (overrides --slot)")
    ap.add_argument("--file", help="explicit source .ydd filename (e.g. p_head_012_a.ydd)")
    ap.add_argument("--texprefix", help="YTD prefix (defaults to the YDD prefix)")
    ap.add_argument("--drawable", type=int, default=0, help="drawable index inside the YDD")
    ap.add_argument("--texture", type=int, default=0, help="texture variation index")
    ap.add_argument("--sex", choices=("male", "female"), default="male")
    ap.add_argument("--out", help="output stream/ directory (explicit)")
    ap.add_argument("--resource", help="whip_clothingwheel root: writes stream/ and updates config.lua")
    ap.add_argument("--model", help="output model name (default: cw_<prefix>_<drawable>_<texture>)")
    ap.add_argument("--reindex", action="store_true", help="rebuild the RPF file index")
    ap.add_argument("--list", action="store_true", help="list available drawables for --slot/--prefix")
    args = ap.parse_args()

    game = Path(args.game)
    if not (game / "GTA5.exe").exists():
        print(f"[error] GTA5.exe not found in {game}", file=sys.stderr)
        return 2
    index = load_index(game, force=args.reindex)

    if args.reindex and not (args.slot or args.prefix or args.file):
        return 0

    if not (args.slot or args.prefix or args.file):
        print("[error] pass --slot, --prefix, --file, --list or --reindex", file=sys.stderr)
        return 2

    if args.file:
        prefix = re.sub(r"_\d{2,3}(?:_[a-z])?\.ydd$", "", args.file.lower())
        if args.slot:
            kind = SLOT_PREFIX[args.slot][0]
        else:
            kind = "prop" if prefix.startswith("p_") else "component"
        texprefix = args.texprefix or prefix
        slot = args.slot or ""
    elif args.prefix:
        kind, prefix, texprefix = "custom", args.prefix, args.texprefix or args.prefix
        slot = args.slot or ""
    elif args.slot:
        kind, prefix, texprefix = SLOT_PREFIX[args.slot]
        if args.texprefix:
            texprefix = args.texprefix
        slot = args.slot

    if args.list:
        list_models(index, prefix, kind, args.sex)
        return 0

    if not args.out and not args.resource:
        print("[error] pass --out or --resource", file=sys.stderr)
        return 2

    prefer = "mp_m_freemode_01" if args.sex == "male" else "mp_f_freemode_01"
    if args.file:
        ydd_name = args.file.lower()
        ydd_path = find_in_rpf(index, ydd_name, prefer)
        if ydd_path is None:
            print(f"[error] {ydd_name} not found. Try --reindex.", file=sys.stderr)
            return 3
        inferred = drawable_index_from_filename(ydd_name)
        if inferred is not None and args.drawable == 0:
            args.drawable = inferred
    else:
        if kind == "prop":
            # Per i prop freemode il drawable N è SEMPRE `p_head_005.ydd` ecc.
            # dentro streamedpedprops.rpf/<sex>_p/. Non prendere il primo file
            # omonimo di una DLC: è un altro cappello con lo stesso numero.
            ydd_name = f"{prefix}_{args.drawable:03d}.ydd"
        else:
            ydd_name = f"{prefix}_{args.drawable:03d}_u.ydd"
        ydd_path = find_in_rpf(index, ydd_name, prefer)
        if ydd_path is None and kind != "prop":
            alt = f"{prefix}_{args.drawable:03d}_r.ydd"
            ydd_path = find_in_rpf(index, alt, prefer)
            if ydd_path:
                ydd_name = alt
        if ydd_path is None:
            print(f"[error] {ydd_name} not found. Try --reindex or --list.", file=sys.stderr)
            return 3

    model_name = args.model or f"cw_{prefix}_{args.drawable:03d}_{args.texture:02d}"
    if args.resource:
        out = Path(args.resource) / "stream"
    else:
        out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)

    letter = TEX_LETTERS[args.texture] if 0 <= args.texture < len(TEX_LETTERS) else "a"
    if kind == "prop":
        ytd_names = [
            f"{texprefix}_diff_{args.drawable:03d}_{letter}.ytd",
            f"{texprefix}_diff_{args.drawable:03d}_{letter}_uni.ytd",
        ]
    else:
        ytd_names = [f"{texprefix}_diff_{args.drawable:03d}_{letter}_uni.ytd"]
    ytd_name = next((n for n in ytd_names if find_in_rpf(index, n, prefer)), ytd_names[0])

    ydr = extract_drawable(ydd_path, args.drawable, out, model_name)
    if ydr is None:
        return 4
    ytd = extract_texture(index, ytd_name, out, model_name, prefer)

    manifest = {
        "model": model_name,
        "slot": slot,
        "kind": kind,
        "sex": args.sex,
        "drawable": args.drawable,
        "texture": args.texture,
        "source_ydd": str(ydd_path),
        "source_ytd": str(find_in_rpf(index, ytd_name, prefer)) if ytd else None,
        "outputs": [p.name for p in (ydr, ytd) if p],
        "note": "Copy .ydr and .ytd into the FiveM resource stream/ folder. Requires restart + refresh.",
    }
    (out / f"{model_name}.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print(f"[done] {model_name}: {', '.join(manifest['outputs'])}", flush=True)

    if args.resource:
        append_config(Path(args.resource), slot, args.drawable, model_name)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
