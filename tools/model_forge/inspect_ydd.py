#!/usr/bin/env python3
"""inspect_ydd.py — show drawables inside a YDD and what forge.py would extract.

Usage:
    python inspect_ydd.py --file p_head_005.ydd --drawable 5 --sex male
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

from forge import DEFAULT_GAME, build_index, find_in_rpf, load_index
from szio import VPath, try_load_asset


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--game", default=DEFAULT_GAME)
    ap.add_argument("--file", required=True, help="YDD filename, e.g. p_head_005.ydd")
    ap.add_argument("--drawable", type=int, default=0, help="drawable index forge.py would extract")
    ap.add_argument("--sex", choices=("male", "female"), default="male")
    ap.add_argument("--reindex", action="store_true")
    args = ap.parse_args()

    game = Path(args.game)
    index = load_index(game, force=args.reindex)
    prefer = "mp_m_freemode_01" if args.sex == "male" else "mp_f_freemode_01"
    path = find_in_rpf(index, args.file.lower(), prefer)
    if path is None:
        print(f"[error] {args.file} not found", file=sys.stderr)
        return 2

    loaded = try_load_asset(path, return_target=True)
    if not loaded:
        print(f"[error] cannot load {path}", file=sys.stderr)
        return 3
    asset, target = loaded
    drawables = getattr(asset, "drawables", None) or {}
    keys = list(drawables.keys())
    print(f"[ydd] {path}")
    print(f"[ydd] target={target.version.name} drawables={len(keys)}")
    for i, key in enumerate(keys):
        d = drawables[key]
        name = getattr(d, "name", "?")
        marker = " <== forge.py extracts this" if i == args.drawable else ""
        print(f"  [{i}] key={key!r} name={name!r}{marker}")
    if args.drawable < len(keys):
        selected = drawables[keys[args.drawable]]
        print(f"[select] index={args.drawable} name={getattr(selected, 'name', '?')!r}")
    else:
        print(f"[select] index={args.drawable} out of range: forge.py falls back to index 0")
        selected = drawables[keys[0]]
        print(f"[fallback] name={getattr(selected, 'name', '?')!r}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
