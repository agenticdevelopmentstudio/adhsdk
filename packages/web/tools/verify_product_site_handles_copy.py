#!/usr/bin/env python3
"""Assert `@adh-sdk/adh`'s product site handle words still match the backend's.

`packages/adh/src/site/reservedSlugs.ts` holds `PRODUCT_SITE_HANDLE_WORDS`, a copy of the
backend's list of the same name in `src/adh/src/lib/rdid.ts`, which the API enforces through
`RESERVED_PRODUCT_SITE_HANDLES`. The copy exists so the hub's form can refuse a reserved
handle before it is sent. Nothing else notices the two drifting: the backend gaining a word
makes the form offer a handle the API refuses, and the backend dropping one makes the form
refuse a handle the API accepts. Both sides add the registry's `RESERVED_SLUGS` to these
words, and that file is vendored into the backend under its own drift test, so the words are
the only hand-kept part.

The two lists must hold the same words, in either direction. Order does not matter.

The backend is another repo. The guard finds its `rdid.ts` from, in order: `--rdid`, the
`ADH_BACKEND_RDID` environment variable, or a checkout that holds this repo as a submodule
(the backend keeps it at `external/adhsdk`, so `src/adh/src/lib/rdid.ts` sits above it).
`--if-backend` makes "no backend found" a printed skip rather than a failure, for a run
of this repo on its own.

Exit codes: 0 in sync (or skipped under `--if-backend`) · 1 drift · 2 the guard could not
find or parse what it checks.
"""

from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[3]
COPY = REPO / "packages/web/packages/adh/src/site/reservedSlugs.ts"
RDID_IN_BACKEND = Path("src/adh/src/lib/rdid.ts")

BLOCK = re.compile(
    r"export\s+const\s+PRODUCT_SITE_HANDLE_WORDS\s*:[^=]*=\s*\[(?P<body>[^\]]*)\]", re.S
)
QUOTED = re.compile(r"'([^']*)'")


def handle_words(path: Path) -> set[str] | None:
    """The quoted words of the `PRODUCT_SITE_HANDLE_WORDS` array in `path`, or None."""
    found = BLOCK.findall(path.read_text())
    if len(found) != 1:
        return None
    body = "\n".join(line.split("//", 1)[0] for line in found[0].splitlines())
    return set(QUOTED.findall(body))


def find_rdid(explicit: Path | None) -> Path | None:
    if explicit is not None:
        return explicit
    env = os.environ.get("ADH_BACKEND_RDID")
    if env:
        return Path(env)
    for parent in REPO.parents:
        candidate = parent / RDID_IN_BACKEND
        if candidate.is_file():
            return candidate
    return None


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Check PRODUCT_SITE_HANDLE_WORDS against the backend.")
    ap.add_argument("--rdid", type=Path, help="the backend's src/adh/src/lib/rdid.ts")
    ap.add_argument(
        "--if-backend",
        action="store_true",
        help="skip, exit 0, when no backend rdid.ts can be found",
    )
    args = ap.parse_args(argv)

    rdid = find_rdid(args.rdid)
    if rdid is None:
        if args.if_backend:
            print(
                "verify_product_site_handles_copy: SKIPPED — no backend rdid.ts found "
                "(pass --rdid or set ADH_BACKEND_RDID to check)."
            )
            return 0
        print(
            "error: no backend rdid.ts found. Pass --rdid or set ADH_BACKEND_RDID.\n"
            "\nverify_product_site_handles_copy: FAILED TO CHECK.",
            file=sys.stderr,
        )
        return 2
    missing = [p for p in (COPY, rdid) if not p.is_file()]
    if missing:
        for p in missing:
            print(f"error: not found: {p}", file=sys.stderr)
        print("\nverify_product_site_handles_copy: FAILED TO CHECK.", file=sys.stderr)
        return 2

    copy, backend = handle_words(COPY), handle_words(rdid)
    for path, got in ((COPY, copy), (rdid, backend)):
        if not got:
            print(
                f"error: no single PRODUCT_SITE_HANDLE_WORDS array parsed from {path}\n"
                "\nverify_product_site_handles_copy: FAILED TO CHECK.",
                file=sys.stderr,
            )
            return 2

    only_copy, only_backend = sorted(copy - backend), sorted(backend - copy)
    if only_copy or only_backend:
        if only_backend:
            print(f"only in the backend ({rdid}): {', '.join(only_backend)}")
        if only_copy:
            print(f"only in the copy ({COPY.relative_to(REPO)}): {', '.join(only_copy)}")
        print("\nThe backend is the authority: make the copy hold exactly its words.")
        print("\nverify_product_site_handles_copy: words out of sync.", file=sys.stderr)
        return 1

    print(f"verify_product_site_handles_copy: OK — {len(copy)} word(s) match {rdid}.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
