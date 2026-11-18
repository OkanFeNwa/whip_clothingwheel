#!/usr/bin/env python3
"""fix_texture_refs.py — bake the right texture variation into extracted .ydr files.

A GTA drawable (.ydd) stores one shader group with a *default* diffuse texture,
usually `<prefix>_diff_<drawable>_a`. When a ped wears texture variation N the
game swaps that sampler at runtime. A world object created with CreateObject has
no ped variation system, so the sampler must be baked into the .ydr.

This tool pairs each .ydr with its .ytd, reads the real texture names inside the
dictionary, and rewrites stale texture samplers to the matching entry. Files are
written to a separate output folder: the source models are never modified.

Usage
-----
  python fix_texture_refs.py --from E:\\whip\\output\\models --out .\\stream
  python fix_texture_refs.py --from .\\stream --out .\\stream_fixed
"""

from __future__ import annotations

import argparse
import shutil
from pathlib import Path

from szio import save_asset, try_load_asset
from szio.gta5.assets import AssetFormat, AssetTarget, AssetVersion, SaveOptions

GEN8 = [AssetTarget(AssetFormat.NATIVE, AssetVersion.GEN8)]


def texture_names(ytd: Path) -> list[str]:
    asset = try_load_asset(str(ytd), return_target=False)
    if not asset:
        return []
    return [str(name) for name in (getattr(asset, "textures", {}) or {}).keys()]


def samplers(asset) -> list:
    group = getattr(asset, "shader_group", None)
    return list(getattr(group, "shaders", []) or [])


def diffuse_target(names: list[str], current) -> str | None:
    """Pick the texture the diffuse sampler must point at for this variant.

    The paired .ytd contains the exact texture used by this (drawable, texture)
    combination. Its name is the source of truth; the .ydr's sampler may hold a
    stale default (`p_head_diff_014_a`), a placeholder (`T4`) or a name from a
    different drawable. Only `diffusesampler` is rewritten: normal/specular and
    volume textures are either embedded in the .ydr or engine built-ins.
    """
    if isinstance(current, str) and current in names:
        return current
    preferred = [n for n in names if "_diff_" in n]
    if preferred:
        return preferred[0]
    if len(names) == 1:
        return names[0]
    return None


def fix_one(ydr: Path, ytd: Path, out: Path) -> str:
    """Return 'fixed', 'ok' or 'unresolved'."""
    names = texture_names(ytd)
    loaded = try_load_asset(str(ydr), return_target=False)
    if not loaded or not names:
        shutil.copy2(ydr, out / ydr.name)
        return "unresolved"

    # FiveM registra il modello con il nome INTERNO del drawable, non con il nome
    # del file. I dump hanno nomi tipo `p_head_014.#dd` o `mp_m_...^p_head_001`:
    # per questo GetHashKey('male_p0_np_014_03') non trovava nulla e il client
    # cadeva sul prop generico. Allineiamo sempre il nome interno al file.
    internal_name = getattr(loaded, "name", None)
    name_changed = internal_name != ydr.stem
    if name_changed:
        loaded.name = ydr.stem

    changed = False
    unresolved = False
    for shader in samplers(loaded):
        for param in getattr(shader, "parameters", []) or []:
            if str(getattr(param, "name", "")) != "diffusesampler":
                continue
            target = diffuse_target(names, getattr(param, "value", None))
            if not target:
                unresolved = True
                continue
            if getattr(param, "value", None) != target:
                param.value = target
                changed = True

    if changed or name_changed:
        save_asset(loaded, GEN8, out, ydr.stem, SaveOptions())
        return "fixed"
    if unresolved:
        shutil.copy2(ydr, out / ydr.name)
        return "unresolved"

    shutil.copy2(ydr, out / ydr.name)
    return "ok"


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--from", dest="source", required=True, help="folder tree with .ydr and .ytd files")
    ap.add_argument("--out", required=True, help="destination folder (flat); receives patched .ydr + all .ytd")
    ap.add_argument("--limit", type=int, default=0, help="process only the first N models (0 = all)")
    args = ap.parse_args()

    source = Path(args.source)
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    if not source.is_dir():
        print(f"[error] not a folder: {source}")
        return 2

    ydrs = sorted(source.rglob("*.ydr"))
    if args.limit:
        ydrs = ydrs[: args.limit]

    stats = {"fixed": 0, "ok": 0, "unresolved": 0, "missing_ytd": 0}
    copied_ytd = set()
    for i, ydr in enumerate(ydrs, 1):
        ytd = ydr.with_suffix(".ytd")
        if not ytd.exists():
            stats["missing_ytd"] += 1
            print(f"[warn] no ytd for {ydr.name}")
            continue
        result = fix_one(ydr, ytd, out)
        stats[result] += 1

        if ytd not in copied_ytd:
            shutil.copy2(ytd, out / ytd.name)
            copied_ytd.add(ytd)

        if i % 250 == 0:
            print(f"[info] {i}/{len(ydrs)} ...", flush=True)

    print(f"[done] fixed={stats['fixed']} ok={stats['ok']} "
          f"unresolved={stats['unresolved']} missing_ytd={stats['missing_ytd']}")
    print(f"[done] ytd copied: {len(copied_ytd)}  output: {out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
