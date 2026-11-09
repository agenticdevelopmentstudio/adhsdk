"""Shared `resolve_spec` for this package's generators (gen_endpoints.py,
gen_table_metadata.py, gen_schema.py) — extracted because it used to be a
byte-equivalent ~30-line function, docstring included, copy-pasted into each
one. Edit here; every generator picks up the fix at import time.

pnpm always invokes these scripts as `python3 tools/<script>.py`, so `tools/`
is `sys.path[0]` (Python inserts the invoked script's own directory, not the
cwd) and `import _spec_input` resolves with no path manipulation needed.

The spec every generator reads is adh's `/v1` spec, `openapi.v1.json`: committed in
the adhbackend repo at `src/adh/openapi.v1.json` and served live at
`https://api.agenticdeveloperhub.com/v1/openapi.json`. The legacy `openapi.json`
beside it describes the unversioned routes the `/v1` gateway replays onto; nothing
here generates from it any more.
"""

from __future__ import annotations

import os
import sys
import tempfile
import urllib.request
from pathlib import Path

#: Where the live `/v1` spec is served — accepted wherever a spec path is.
LIVE_V1_SPEC_URL = "https://api.agenticdeveloperhub.com/v1/openapi.json"

#: The committed copy, relative to an adhbackend checkout.
BACKEND_V1_SPEC = "src/adh/openapi.v1.json"


def _download(url: str) -> Path:
    """Fetch a spec served over http(s) into a temp file and return its path."""
    with urllib.request.urlopen(url, timeout=60) as res:  # noqa: S310 — the URL is the caller's input
        body = res.read()
    fd, name = tempfile.mkstemp(prefix="adh-openapi-", suffix=".json")
    with os.fdopen(fd, "wb") as out:
        out.write(body)
    return Path(name)


def resolve_spec(argv: list[str] | None = None, env_var: str = "ADH_OPENAPI_SPEC") -> Path:
    """Locate adh's `/v1` OpenAPI spec, which is an INPUT — never a computed path.

    The spec belongs to adh. This repo is consumed standalone by repos that have
    no spec at all, so there is no relative location this file could honestly
    derive. It used to derive one (`parents[1].parent.parent` back when the
    package sat at `frontend/src/app/api-types`), and when the package moved into
    the toolkit that walk silently retargeted to a directory that does not exist —
    the same stale-path break this move exposed in four other tools. An explicit
    input either resolves or says why it didn't.

    The input is a file path or an http(s) URL (e.g. {LIVE_V1_SPEC_URL}); a URL is
    downloaded to a temp file first.
    """
    args = sys.argv[1:] if argv is None else argv
    # pnpm forwards the `--` separator through to the script, so a documented
    # `pnpm --filter … <script> -- <spec>` invocation arrives here as ['--', '<spec>']
    # and the separator gets read as the path. Drop one leading `--`.
    if args and args[0] == "--":
        args = args[1:]
    raw = args[0] if args else os.environ.get(env_var)
    if not raw:
        raise SystemExit(
            "no OpenAPI spec given. This generator reads adh's /v1 spec, which does "
            f"not live in this repo. Pass it as the first argument or set {env_var}:\n"
            f"  {env_var}=<adhbackend>/{BACKEND_V1_SPEC} python3 tools/<this-script>.py\n"
            f"  python3 tools/<this-script>.py {LIVE_V1_SPEC_URL}"
        )
    if raw.startswith(("http://", "https://")):
        return _download(raw)
    spec = Path(raw).expanduser().resolve()
    if not spec.is_file():
        raise SystemExit(f"spec not found: {spec}")
    return spec
