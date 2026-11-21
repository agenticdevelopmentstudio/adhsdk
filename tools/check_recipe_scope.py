#!/usr/bin/env python3
"""No recipe may name a retired package scope.

A recipe that still says @agentic-toolkit/ or @agenticdevelopertoolkit/ points a reader at a package this repo
does not have, in a repo whose whole purpose is being readable by strangers.

The default root is `cookbook/`, where the legacy `recipes/` specs now live (AGENTS.md); run-local-ci
also points it at `docs/`. Files under a `sessions/` directory are skipped: they are dated history,
recording what was true at the time — the same exception check_no_retired_names.py makes.
"""
import argparse
import re
import sys
from pathlib import Path

STALE = re.compile(r"@(?:agentic-toolkit|agenticdevelopertoolkit)/[a-z0-9-]+")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1] / "cookbook")
    args = parser.parse_args()

    if not args.root.is_dir():
        print(f"error: root not found: {args.root}", file=sys.stderr)
        return 2

    files = sorted(
        p for p in args.root.rglob("*.md") if "sessions" not in p.relative_to(args.root).parts[:-1]
    )
    if not files:
        print(f"error: no recipes found under {args.root}", file=sys.stderr)
        return 2

    violations = []
    for path in files:
        for lineno, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            for hit in STALE.findall(line):
                violations.append((path, lineno, hit))

    for path, lineno, hit in violations:
        print(f"{path}:{lineno}: names the private scope: {hit}", file=sys.stderr)

    if violations:
        print(f"{len(violations)} stale reference(s) in {len(files)} recipes", file=sys.stderr)
        return 1

    print(f"check_recipe_scope: {len(files)} recipes, none name the private scope")
    return 0


if __name__ == "__main__":
    sys.exit(main())
