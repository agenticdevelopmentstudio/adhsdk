#!/usr/bin/env python3
"""Every web feature package must belong to exactly one abstractr tier.

`.abstractr.json` names the `web-features` tier's packages one by one
(`packages/web/packages/features/<name>/`) rather than by the
`packages/web/packages/features/` prefix. It has to: `web-support-access` is a
tier of its own nested under that prefix, and abstractr's export index counted
its files twice when both tiers claimed them.

The cost of listing by name is that the map no longer grows on its own. A package
added under `packages/web/packages/features/` later matches no feature tier at
all. It falls through to the `web-workspace` catch-all (`packages/web`) and
quietly escapes every dependency rule `web-features` carries. Nothing fails; the
new package is just unguarded.

This guard closes that gap. For every directory directly under
`packages/web/packages/features/` (skipping `node_modules` and dot-directories;
loose files such as `tsup.preset.ts` are not packages) it checks that exactly one
tier lists `packages/web/packages/features/<name>/` as a path. It also reports a
tier path naming a feature directory that no longer exists, so a removed or
renamed package does not leave a dead entry behind. A tier path that is a prefix
of a loose file there (`web-toolchain` lists `features/tsup.preset` for
`tsup.preset.ts`) is a file entry, not a package, and is left alone.

Run: python3 tools/check_feature_tiers.py   (exit 0 = clean, 1 = problems).
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
FEATURES_DIR = "packages/web/packages/features"
CONFIG_NAME = ".abstractr.json"
SKIP_DIRS = {"node_modules"}


def feature_dirs(features_root: Path) -> list[str]:
    """Names of the package directories directly under the features root."""
    if not features_root.is_dir():
        return []
    return sorted(
        entry.name
        for entry in features_root.iterdir()
        if entry.is_dir() and not entry.name.startswith(".") and entry.name not in SKIP_DIRS
    )


def loose_file_names(features_root: Path) -> list[str]:
    """Names of the plain files directly under the features root (presets)."""
    if not features_root.is_dir():
        return []
    return sorted(entry.name for entry in features_root.iterdir() if entry.is_file())


def feature_name_of(path: str) -> str | None:
    """The `<name>` in `packages/web/packages/features/<name>[/]`, else None.

    Only a path that names a single directory directly under the features root
    counts; the root itself and anything deeper are not feature-package entries.
    """
    prefix = FEATURES_DIR + "/"
    if not path.startswith(prefix):
        return None
    rest = path[len(prefix):].rstrip("/")
    if not rest or "/" in rest:
        return None
    return rest


def claims_by_feature(config: dict) -> dict[str, list[str]]:
    """Map each feature name a tier path names to the tiers naming it."""
    claims: dict[str, list[str]] = {}
    for tier in config.get("tiers", []):
        tier_name = tier.get("name", "<unnamed>")
        for path in tier.get("paths", []):
            name = feature_name_of(path)
            if name is not None:
                claims.setdefault(name, []).append(tier_name)
    return claims


def check(repo_root: Path) -> list[str]:
    config = json.loads((repo_root / CONFIG_NAME).read_text(encoding="utf-8"))
    dirs = feature_dirs(repo_root / FEATURES_DIR)
    claims = claims_by_feature(config)

    problems: list[str] = []
    for name in dirs:
        tiers = claims.get(name, [])
        path = f"{FEATURES_DIR}/{name}/"
        if not tiers:
            problems.append(
                f"{path} is in no tier, so it falls through to the web-workspace "
                f"catch-all and escapes web-features' rules.\n"
                f"  fix: add {path} to the web-features tier in {CONFIG_NAME}, "
                f"or give it its own tier"
            )
        elif len(tiers) > 1:
            problems.append(
                f"{path} is listed by {len(tiers)} tiers ({', '.join(tiers)}), "
                f"which double-counts it in abstractr's export index.\n"
                f"  fix: keep {path} in exactly one tier in {CONFIG_NAME}"
            )

    present = set(dirs)
    loose_files = loose_file_names(repo_root / FEATURES_DIR)
    for name in sorted(claims):
        # A tier path such as `features/tsup.preset` (web-toolchain) is a
        # prefix naming a loose file, `tsup.preset.ts`, not a package.
        if name not in present and not any(f.startswith(name) for f in loose_files):
            problems.append(
                f"{FEATURES_DIR}/{name}/ is listed by {', '.join(claims[name])} "
                f"but no such directory exists.\n"
                f"  fix: remove it from {CONFIG_NAME}, or restore the package"
            )
    return problems


def main(argv: "list[str] | None" = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument(
        "--root",
        type=Path,
        default=REPO_ROOT,
        help="repo root holding .abstractr.json (default: this repo)",
    )
    args = parser.parse_args(argv)
    repo_root = args.root.resolve()

    if not (repo_root / CONFIG_NAME).is_file():
        print(
            f"check_feature_tiers: FAILED TO CHECK — no {CONFIG_NAME} at {repo_root}.",
            file=sys.stderr,
        )
        return 2
    if not (repo_root / FEATURES_DIR).is_dir():
        print(
            f"check_feature_tiers: FAILED TO CHECK — no {FEATURES_DIR} under {repo_root}. "
            "The directory this guard exists to scan is not there.",
            file=sys.stderr,
        )
        return 2

    problems = check(repo_root)
    if problems:
        print(f"check_feature_tiers: {len(problems)} problem(s):\n", file=sys.stderr)
        for problem in problems:
            print(f"- {problem}", file=sys.stderr)
        return 1

    count = len(feature_dirs(repo_root / FEATURES_DIR))
    print(f"check_feature_tiers: OK — {count} feature package(s), each in exactly one tier")
    return 0


if __name__ == "__main__":
    sys.exit(main())
