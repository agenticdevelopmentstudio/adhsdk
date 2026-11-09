#!/usr/bin/env python3
"""Generate the typed Python API client into src/apt_terminal/generated/.

Wraps `openapi-python-client` (httpx + pydantic v2). Driven by the consolidated
orchestrator (tools/codegen/generate.py), which passes --spec; runnable
standalone with an explicit --spec path.

The input is the Stripe-style /v1 spec — `src/adh/openapi.v1.json` in adhbackend,
served live at https://api.agenticdeveloperhub.com/v1/openapi.json — not the legacy
unversioned `openapi.json`. The CLI's hand-written layer (resources.py, auth.py,
public.py) names /v1 operations only.

Usage:
  python3 scripts/generate.py --spec /abs/path/to/openapi.v1.json
"""
from __future__ import annotations

import argparse
import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CONFIG = ROOT / "openapi-python-client-config.yaml"
OUT_PARENT = ROOT / "src" / "apt_terminal"
OUT = OUT_PARENT / "generated"


def interpreter() -> str:
    """The python that has `openapi-python-client` installed.

    pyproject pins the generator in the `dev` extra, so the interpreter that can run it is
    normally this package's own `.venv` — not whatever python the consolidated orchestrator
    happened to start with (it invokes us as a bare `python3`). Prefer the local venv when
    it exists so `pnpm gen` works from a clean checkout after `pip install -e '.[dev]'`,
    and fall back to the running interpreter for anyone who installed the extra globally.
    """
    venv = ROOT / ".venv" / "bin" / "python"
    return str(venv) if venv.exists() else sys.executable


def hook_env() -> dict[str, str]:
    """The environment the generator's POST-HOOKS run in, with the venv's bin first on PATH.

    `interpreter()` above pins the generator itself, and that used to be the whole story —
    but generation does not end when openapi-python-client returns. Its `post_hooks` are
    shell commands (`ruff check --fix`, `ruff format .`), and a bare `ruff` resolves from
    PATH, so the LAST stage of generation ran under whatever ruff the machine happened to
    have installed rather than the `ruff==0.13.3` pyproject pins beside the generator.

    That is not hypothetical: the committed tree under `src/apt_terminal/generated/` is
    0.16.0 output while the venv holds 0.13.3, because a Homebrew ruff sat ahead of the
    venv on PATH. The pin was real, the venv was correct, and the hook walked straight past
    both — which is exactly the drift the pin exists to prevent, arriving through the one
    door it did not cover.

    Prepending the venv's bin closes it for every hook tool at once, so the config file can
    go on naming plain `ruff` (it is also what the hook would resolve to inside an activated
    venv, which is how anyone running this by hand would expect it to behave).
    """
    env = dict(os.environ)
    bindir = ROOT / ".venv" / "bin"
    if bindir.exists():
        env["PATH"] = f"{bindir}{os.pathsep}{env.get('PATH', '')}"
    return env


def build_cmd(spec: Path) -> list[str]:
    return [
        interpreter(), "-m", "openapi_python_client", "generate",
        "--path", str(spec),
        "--meta", "none",
        "--output-path", str(OUT),
        "--overwrite",
        "--config", str(CONFIG),
    ]


def main(argv=None) -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--spec", required=True, help="path to the OpenAPI spec")
    args = p.parse_args(argv)
    spec = Path(args.spec)
    if not spec.exists():
        print(f"error: missing spec {spec}", file=sys.stderr)
        return 1
    # --overwrite replaces OUT; ensure a clean parent dir exists.
    OUT_PARENT.mkdir(parents=True, exist_ok=True)
    print(f"$ {' '.join(build_cmd(spec))}")
    subprocess.run(build_cmd(spec), check=True, env=hook_env())
    print(f"generated client at {OUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
