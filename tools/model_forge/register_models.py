#!/usr/bin/env python3
"""register_models.py — build data/drop_models.json from generated model files.

The FiveM server cannot enumerate stream/ at runtime, so generated models need a
small registry that says which (slot, sex, drawable, texture) maps to which .ydr
name. This tool reads forge.py manifests when present and otherwise infers the
identity from the filename. It supports both naming schemes in use:

  cw_<prefix>_<drawable>_<texture>.ydr      (forge.py default)
  <male|female>_p<slot>_np_<drawable>_<texture>.ydr  (WHIP media dump)

Usage
-----
  python register_models.py --from .\\stream --resource ..\\..
  python register_models.py --from E:\\whip\\output\\models --resource ..\\.. --dry-run

Output schema (slot -> drawable -> sex -> texture -> model):

  { "hat": { "14": { "male": { "3": "male_p0_np_014_03" },
                     "female": { "3": "female_p0_np_014_03" } } } }

The server loader also accepts the older flat form slot -> drawable -> model.
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

# Slot id -> YDD prefixes seen in forge.py. Used only for cw_* filename inference.
PREFIX_SLOT = {
    "p_head": "hat",
    "p_eyes": "glasses",
    "p_ears": "ear",
    "p_rwrist": "watch",
    "p_lwrist": "bracelet",
    "berd": "mask",
    "jbib": "tops",
    "uppr": "undershirt",
    "feet": "shoes",
    "accs": "accessory",
    "task": "armor",
    "decl": "decal",
    "hand": "bag",
    "lowr": "legs",
}

# p<prop anchor>/p<component id> -> whip_clothingwheel slot id.
ANCHOR_SLOT = {
    "0": "hat",
    "1": "glasses",
    "2": "ear",
    "6": "watch",
    "7": "bracelet",
    "1c": "mask",
    "3": "arms",
    "4": "legs",
    "5": "bag",
    "6c": "shoes",
    "7c": "accessory",
    "8": "undershirt",
    "9": "armor",
    "10": "decal",
    "11": "tops",
}

KNOWN_SLOTS = set(PREFIX_SLOT.values()) | set(ANCHOR_SLOT.values()) | {"arms"}

CW_PATTERN = re.compile(r"^cw_(.+?)_(\d{2,3})_(\d{2})\.ydr$", re.IGNORECASE)
NP_PATTERN = re.compile(
    r"^(male|female)_p(\d+)_np_(\d{2,3})_(\d{2})\.ydr$", re.IGNORECASE
)


def add(registry: dict, slot: str, drawable: int, sex: str, texture: int, model: str) -> None:
    registry.setdefault(slot, {}).setdefault(str(drawable), {}).setdefault(sex, {})[str(texture)] = model


def infer_cw(path: Path) -> tuple[str, int, str, int] | None:
    """Infer (slot, drawable, sex, texture) from cw_<prefix>_<drawable>_<texture>.ydr."""
    m = CW_PATTERN.match(path.name)
    if not m:
        return None
    slot = PREFIX_SLOT.get(m.group(1).lower())
    return (slot, int(m.group(2)), "any", int(m.group(3))) if slot else None


def infer_np(path: Path) -> tuple[str, int, str, int] | None:
    """Infer (slot, drawable, sex, texture) from <sex>_p<anchor>_np_<drawable>_<texture>.ydr."""
    m = NP_PATTERN.match(path.name)
    if not m:
        return None
    slot = ANCHOR_SLOT.get(m.group(2))
    if not slot:
        return None
    return slot, int(m.group(3)), m.group(1).lower(), int(m.group(4))


def collect(source: Path) -> tuple[dict, list[str]]:
    """Return (registry, warnings)."""
    registry: dict = {}
    warnings: list[str] = []

    manifests = sorted(source.rglob("*.json"))
    ydrs = sorted(source.rglob("*.ydr"))
    manifest_stems = {m.stem for m in manifests}

    for manifest in manifests:
        try:
            # utf-8-sig tollera i manifest scritti da forge.py e quelli con BOM.
            data = json.loads(manifest.read_text(encoding="utf-8-sig"))
        except Exception as exc:
            warnings.append(f"manifest {manifest.name}: {exc}")
            continue
        if not isinstance(data, dict):
            continue

        model = data.get("model")
        slot = data.get("slot")
        drawable = data.get("drawable")
        if not isinstance(model, str) or not model:
            continue
        if slot not in KNOWN_SLOTS or not isinstance(drawable, int) or drawable < 0:
            continue

        sex = str(data.get("sex") or "any").lower()
        if sex.startswith("male"):
            sex = "male"
        elif sex.startswith("female"):
            sex = "female"
        else:
            sex = "any"

        texture = data.get("texture")
        texture = int(texture) if isinstance(texture, int) and texture >= 0 else 0
        add(registry, slot, drawable, sex, texture, model)

    # Fallback for .ydr files without a manifest.
    for ydr in ydrs:
        if ydr.stem in manifest_stems:
            continue
        inferred = infer_np(ydr) or infer_cw(ydr)
        if not inferred:
            warnings.append(f"ydr {ydr.name}: cannot infer slot/sex/drawable/texture (no manifest)")
            continue
        slot, drawable, sex, texture = inferred
        add(registry, slot, drawable, sex, texture, ydr.stem)

    return registry, warnings


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--from", dest="source", required=True, help="folder with .ydr files and/or forge.py manifests")
    ap.add_argument("--resource", required=True, help="whip_clothingwheel root (writes data/drop_models.json)")
    ap.add_argument("--dry-run", action="store_true", help="print the registry without writing")
    args = ap.parse_args()

    source = Path(args.source)
    if not source.is_dir():
        print(f"[error] not a folder: {source}")
        return 2

    registry, warnings = collect(source)
    for warning in warnings[:40]:
        print(f"[warn] {warning}")
    if len(warnings) > 40:
        print(f"[warn] ... and {len(warnings) - 40} more")

    entries = 0
    for slot, draws in registry.items():
        for drawable, sexes in draws.items():
            for sex, textures in sexes.items():
                entries += len(textures)
    print(f"[info] {entries} models in {len(registry)} slots")

    if args.dry_run:
        for slot in sorted(registry):
            for drawable in sorted(registry[slot], key=int):
                for sex, textures in sorted(registry[slot][drawable].items()):
                    for texture, model in sorted(textures.items(), key=lambda kv: int(kv[0])):
                        print(f"  {slot}[{drawable}] {sex}/{texture} = {model}")
        return 0

    resource = Path(args.resource)
    out = resource / "data" / "drop_models.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(registry, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(f"[done] {out}")
    print("[done] in game: /cwmodel reload (or refresh + restart whip_clothingwheel)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
