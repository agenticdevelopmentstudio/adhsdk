#!/usr/bin/env python3
"""Build entry point for `websites/demo/`.

The demo site consumes `@adh-sdk/*` packages via their
`file:` references. Those packages ship prebuilt `dist/` (compiled JS with
`"use client"` preserved) — the Model A contract every consumer of these
packages relies on — so the consumer needs no `transpilePackages`, but
`dist/` is gitignored and must be built before `next build`.

This installs the toolkit's pnpm workspace under `packages/web/`, builds every
package's `dist/`, then runs `next build`. It mirrors the build wrapper used by
this toolkit's other consumer, so both build the same way.
"""
from __future__ import annotations

import os
import shutil
import subprocess
import sys
from pathlib import Path

SITE_DIR = Path(__file__).resolve().parent.parent
REPO_ROOT = SITE_DIR.parent.parent
WEB_WORKSPACE = REPO_ROOT / "packages" / "web"


def pnpm(args: list[str]) -> list[str]:
    """Prefer a system pnpm >= 9; otherwise fall back to a pinned npx pnpm."""
    found = shutil.which("pnpm")
    if found:
        result = subprocess.run([found, "--version"], capture_output=True, text=True)
        try:
            if int(result.stdout.strip().split(".")[0]) >= 9:
                return [found, *args]
        except (ValueError, IndexError):
            pass
    return ["npx", "--yes", "pnpm@9.15.9", *args]


def run(cmd: list[str], cwd: Path, env: dict[str, str] | None = None) -> None:
    print(f"==> {' '.join(cmd)}  (cwd={cwd})", flush=True)
    subprocess.run(cmd, cwd=cwd, check=True, env=env)


def main() -> int:
    # Unset NODE_ENV so pnpm installs devDependencies (tsup, typescript,
    # @types/react) needed to build the toolkit dist — production builds set
    # NODE_ENV=production, which would otherwise skip them.
    env = {k: v for k, v in os.environ.items() if k != "NODE_ENV"}
    run(pnpm(["install", "--frozen-lockfile"]), cwd=WEB_WORKSPACE, env=env)
    run(pnpm(["build"]), cwd=WEB_WORKSPACE, env=env)
    run(["npm", "run", "build:next"], cwd=SITE_DIR)
    return 0


if __name__ == "__main__":
    sys.exit(main())
