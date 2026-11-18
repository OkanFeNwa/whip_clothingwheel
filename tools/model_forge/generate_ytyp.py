#!/usr/bin/env python3
"""generate_ytyp.py — register extracted .ydr files as spawnable FiveM objects.

A .ydr on its own is only geometry.  To spawn it by name with CreateObject the
game needs a CBaseArchetypeDef in a .ytyp, loaded through DLC_ITYP_REQUEST.
This script builds one archetype per .ydr using the model's own vertex bounds.

Usage
-----
    python generate_ytyp.py --from ..\\..\\stream --name cw_drops

The output is <name>.ytyp written in the same folder as the models.
"""

from __future__ import annotations

import argparse
import math
from pathlib import Path

import numpy as np
from szio import save_asset, try_load_asset
from szio.gta5.archetypes import Archetype, ArchetypeAssetType, ArchetypeType, AssetMapTypes
from szio.gta5.assets import AssetFormat, AssetTarget, AssetVersion, SaveOptions
from szio.types import Vector

NATIVE_G8 = [AssetTarget(AssetFormat.NATIVE, AssetVersion.GEN8)]


def drawable_bounds(ydr: Path) -> tuple[np.ndarray, np.ndarray]:
    """Return the axis-aligned min/max corners from every LOD vertex buffer."""
    loaded = try_load_asset(str(ydr), return_target=False)
    if not loaded:
        raise RuntimeError(f"cannot load {ydr}")

    lo = np.array([np.inf, np.inf, np.inf], dtype=np.float32)
    hi = np.array([-np.inf, -np.inf, -np.inf], dtype=np.float32)
    found = False
    for models in loaded.models.values():
        for model in models:
            for geom in model.geometries:
                pos = np.asarray(geom.vertex_buffer["Position"][:, :3], dtype=np.float32)
                if pos.size == 0:
                    continue
                found = True
                lo = np.minimum(lo, pos.min(axis=0))
                hi = np.maximum(hi, pos.max(axis=0))
    if not found:
        raise RuntimeError(f"no vertices in {ydr}")
    return lo, hi


def archetype_for(ydr: Path, lod: float, flags: int) -> Archetype:
    name = ydr.stem
    lo, hi = drawable_bounds(ydr)
    center = (lo + hi) * 0.5
    radius = float(np.linalg.norm(hi - lo) * 0.5)
    return Archetype(
        name=name,
        type=ArchetypeType.BASE,
        flags=flags,
        lod_dist=lod,
        special_attribute=0,
        hd_texture_dist=min(lod, 5.0),
        texture_dictionary=name,
        clip_dictionary="",
        drawable_dictionary="",
        physics_dictionary="",
        bb_min=Vector(lo),
        bb_max=Vector(hi),
        bs_center=Vector(center),
        bs_radius=radius,
        asset_name=name,
        asset_type=ArchetypeAssetType.DRAWABLE,
        extensions=[],
    )


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--from", dest="source", required=True, help="folder containing the .ydr files")
    ap.add_argument("--name", default="cw_drops", help="name of the generated .ytyp (default: cw_drops)")
    ap.add_argument("--lod", type=float, default=100.0, help="archetype LOD distance in metres")
    ap.add_argument("--flags", type=int, default=32, help="archetype flags (32 = static)")
    ap.add_argument("--limit", type=int, default=0, help="only include the first N models (0 = all)")
    args = ap.parse_args()

    source = Path(args.source)
    ydrs = sorted(source.glob("*.ydr"))
    if args.limit:
        ydrs = ydrs[: args.limit]
    if not ydrs:
        print(f"[error] no .ydr files in {source}")
        return 2

    types = AssetMapTypes(name=args.name)
    failed: list[str] = []
    for ydr in ydrs:
        try:
            types.archetypes.append(archetype_for(ydr, args.lod, args.flags))
        except Exception as exc:
            failed.append(f"{ydr.name}: {exc}")
    if failed:
        print(f"[warn] skipped {len(failed)} models:")
        for line in failed[:20]:
            print("  " + line)
        if len(failed) > 20:
            print(f"  ... and {len(failed) - 20} more")

    save_asset(types, NATIVE_G8, source, args.name, SaveOptions())
    out = source / f"{args.name}.ytyp"
    print(f"[done] {len(types.archetypes)} archetypes -> {out} ({out.stat().st_size} bytes)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
