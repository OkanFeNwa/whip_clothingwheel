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

Output schema:

  {
    "byIdentity": {
      "hat": { "np":    { "14": { "male": { "3": "male_p0_np_014_03" } } },
               "npnew": { "5":  { "male": { "0": "male_p0_npnew_005_00" } } } }
    },
    "hat": { "14": { "male": { "3": "male_p0_np_014_03" } } }
  }

``byIdentity`` keys on (slot, collection token, LOCAL drawable, sex, texture).
It is authoritative when the client supplies the runtime collection identity.
The top-level form is kept for the base collection and for older saves.
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
    r"^(male|female)_p(\d+)_([a-z0-9]+)_(\d{2,3})_(\d{2})\.ydr$", re.IGNORECASE
)


def add(registry: dict, slot: str, collection: str, drawable: int, sex: str,
        texture: int, model: str) -> None:
    """Write both the stable identity key and the legacy drawable key.

    ``GetPedPropIndex`` returns a GLOBAL drawable number that shifts whenever a
    clothing pack is loaded. The runtime resolves it to
    (collection name, LOCAL index) with whip_core's collection natives, so the
    identity branch is authoritative. The legacy branch is kept for the base
    collection (`np`) and for older saves where no identity was recorded.
    """
    identity = registry.setdefault("byIdentity", {})
    identity.setdefault(slot, {}).setdefault(collection, {}).setdefault(
        str(drawable), {}
    ).setdefault(sex, {})[str(texture)] = model
    if collection == "np":
        registry.setdefault(slot, {}).setdefault(str(drawable), {}).setdefault(
            sex, {}
        )[str(texture)] = model


def infer_cw(path: Path) -> tuple[str, str, int, str, int] | None:
    """Infer (slot, collection, drawable, sex, texture) from cw_* names."""
    m = CW_PATTERN.match(path.name)
    if not m:
        return None
    slot = PREFIX_SLOT.get(m.group(1).lower())
    return (slot, "np", int(m.group(2)), "any", int(m.group(3))) if slot else None


def infer_np(path: Path) -> tuple[str, str, int, str, int] | None:
    """Infer identity from <sex>_p<anchor>_<collection>_<drawable>_<texture>.ydr.

    ``collection`` is the token produced by the exporter from the ped collection
    name: ``np`` for the base freemode collection, otherwise a stable token such
    as ``bikerdlc01`` or ``npnew``. Different collections can reuse the same
    local drawable number for different items, so the token is part of the key.
    """
    m = NP_PATTERN.match(path.name)
    if not m:
        return None
    slot = ANCHOR_SLOT.get(m.group(2))
    if not slot:
        return None
    return slot, m.group(3).lower(), int(m.group(4)), m.group(1).lower(), int(m.group(5))


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
        collection = str(data.get("collection") or "np").lower()
        add(registry, slot, collection, drawable, sex, texture, model)

    # Fallback for .ydr files without a manifest.
    for ydr in ydrs:
        if ydr.stem in manifest_stems:
            continue
        inferred = infer_np(ydr) or infer_cw(ydr)
        if not inferred:
            warnings.append(f"ydr {ydr.name}: cannot infer slot/identity (no manifest)")
            continue
        slot, collection, drawable, sex, texture = inferred
        add(registry, slot, collection, drawable, sex, texture, ydr.stem)

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

    def count(tree: dict) -> int:
        # Leaves are model strings. The legacy tree is 4 levels deep and the
        # identity tree 5, so count leaves instead of assuming a fixed depth.
        total = 0
        stack = list(tree.values())
        while stack:
            node = stack.pop()
            if isinstance(node, str):
                total += 1
            elif isinstance(node, dict):
                stack.extend(node.values())
        return total

    identity = registry.get("byIdentity", {})
    # The whole registry contains the identity tree too, so exclude it from the
    # legacy count or the number would include every identity model as well.
    legacy_tree = {k: v for k, v in registry.items() if k != "byIdentity"}
    print(f"[info] {count(legacy_tree)} legacy models, {count(identity)} identity models "
          f"in {len(identity)} slots")

    if args.dry_run:
        for slot in sorted(identity):
            for collection in sorted(identity[slot]):
                for drawable in sorted(identity[slot][collection], key=int):
                    for sex, textures in sorted(identity[slot][collection][drawable].items()):
                        for texture, model in sorted(textures.items(), key=lambda kv: int(kv[0])):
                            print(f"  {slot}/{collection}[{drawable}] {sex}/{texture} = {model}")
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
