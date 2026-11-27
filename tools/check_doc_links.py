#!/usr/bin/env python3
"""Every repo-relative `docs/…md`, `cookbook/…md` or `recipes/…md` citation in this repo must resolve,
and so must every `agenticdeveloperhub://recipes/<slug>` citation — the recipe corpus's
own cross-reference scheme, used in `domain:` (self-resolving), `ingredients:`/`related:`
frontmatter lists, and an ingredient table's Domain column.

AND every repo-relative citation of a SOURCE path made from inside `docs/` or `recipes/`.

The root `recipes/` corpus moved into `cookbook/` with the cookr format 2 upgrade, so a
`recipes/…md` path or a `agenticdeveloperhub://recipes/<slug>` URI left anywhere now
reports as dangling: cite the spec's `cookbook/<group>/<name>/` folder or its rdid instead.
Source-path citations inside `cookbook/` itself are not checked (they never were).

That last clause is the widening, and it is worth saying why. The `.md`-only regex was
honest about its scope and completely green while 42 recipe citations pointed at
`websites/shared/ui/…` — a directory tree that does not exist in this repo at all; the
files live at `packages/web/packages/ui/…`. A recipe's "Platform Notes" section is almost
entirely source-path citations, so the one part of a recipe most likely to rot was the one
part this guard could not see. A dangling `.tsx` misleads a reader exactly as much as a
dangling `.md` does.

The false-positive risk that kept the original scope narrow is real: prose is full of
path-shaped strings that are not citations into this repo (`src/foo.ts` in an example
snippet, `your-app/pages/index.tsx` in an integration walkthrough, `and/or`). The
containment is a single rule: a source-path citation is only checked when its FIRST
SEGMENT is a real top-level directory of the scanned root. `websites/shared/ui/x.tsx` is
checked because `websites/` exists here; `src/foo.ts` and `your-app/x.ts` are not checked
at all, because nothing in this repo could ever have been meant by them.

Three shapes are skipped even under a real top-level directory, because none of them is
a coordinate anyone can follow or fix: a `...` elision segment, a `*` glob, and a `..`
parent hop.

A citation of a path this repo's `.gitignore` ignores is not dangling either. Since
`b95e5fe87` the build output and generated code are produced on each machine, so a doc
that says where they land (`docs/architecture/build-output-not-committed.md`) names
paths a fresh checkout does not have yet, and this guard runs before install and build.
Whether such a path exists says which steps this machine ran, not whether the doc is
right. Which paths count is narrow on purpose:

  * Only when the scanned root is the top of a git checkout. Outside one nothing is
    ignored, and a root that merely sits inside some other repo (a temp directory under
    a checkout, say) borrows none of that repo's rules.
  * Only a non-negated rule in one of the repo's own `.gitignore` files. A developer's
    global excludes file and `.git/info/exclude` are that machine's, so a path they
    ignore is still checked, or the guard would pass on one machine and fail on the next.
  * Never a tracked path, a file or a directory with tracked files in it: a committed
    file that a pattern happens to match, deleted in the working tree, is still dangling.
  * A typo under a glob or directory pattern (`routes.*.generated.ts`,
    `packages/apple/**/build/`) is excused like the path it misspells; the rule cannot
    tell them apart.

git answers (`check-ignore -v`) with the path also tried as a directory, because an
ignore pattern ending in `/` matches only a directory and a missing path is read as a
file. The paths go to git NUL-separated, so a non-ASCII one is not C-quoted on the way
back, and if git refuses one path (one beyond a symlink, say) the rest are asked one at
a time, so that one is still checked and the others are still excused. git is asked
about the scanned root alone: the `GIT_*` variables a hook runs with (`GIT_DIR`,
`GIT_WORK_TREE`, `GIT_INDEX_FILE`, ...) are dropped first, or git would answer from the
repo they name.

The scope guard is a denylist and knows the private scope's name; this is the complement.
It asks only whether a reader following the citation lands on a file, which is the property
that actually matters and the one that survives the private repo being renamed.

Exit 0 clean, 1 dangling citations found, 2 nothing scanned.
"""
from __future__ import annotations

import argparse
import re
import os
import subprocess
import sys
from pathlib import Path

# A repo-relative doc path. The lookbehind rejects `./docs/x.md` and `../docs/x.md`
# (relative to the citing file, so not ours to resolve) and `https://…/docs/x.md`.
CITATION = re.compile(r"(?<![./\w-])((?:docs|recipes|cookbook)/[\w./-]+\.md)\b")

# The recipe corpus's own cross-reference scheme: `adhsdk://recipes/<slug>`, or the
# older `agenticdeveloperhub://recipes/<slug>` a few recipes still carry, used in a recipe's `domain:` (self-resolving — the file always exists, it's citing
# itself), `ingredients:`/`related:` frontmatter lists, and an ingredient table's Domain
# column. This pattern answers "does it still resolve to a real file?" (not
# necessarily — a slug can name a recipe that stayed private, or one that was never
# written).
RECIPE_URI = re.compile(r"(?:adhsdk|agenticdeveloperhub)://recipes/([a-z0-9-]+)\b")

# A repo-relative path of two or more segments, checked ONLY inside docs/ and recipes/
# and ONLY when its first segment is a real top-level directory (see the docstring).
# The lookbehind is the same one CITATION uses: `./x/y.ts`, `../x/y.ts` and
# `https://host/x/y.ts` are not repo-relative and are not ours to resolve.
SOURCE_CITATION = re.compile(r"(?<![./\w-])(\w[\w.-]*(?:/[\w.@+-]+)+)")

# Prose directories whose source-path citations are checked. Everything else in the
# repo is left alone: package manifests, ignore files and build scripts are full of
# paths that are relative to themselves rather than to the repo root.
PROSE_DIRS = ("docs", "recipes")

# Trailing sentence punctuation the regex happily swallows.
_TRAILING = "/.,;:)]}\"'`"
# `worktrees` is other sessions' checkouts under .claude/: their docs are their branch's, not this one's.
SKIP_DIRS = {"node_modules", "dist", ".turbo", ".git", "coverage", ".next", "worktrees"}
# A file under any `archive/` directory is a record of how the code looked when it was
# written — an executed plan's `git rm` list, a research note's "files modified" log.
# Repointing its coordinates would falsify the record, and the files it names are gone
# by design. It is skipped as a citing site only: a live doc citing an archived one is
# still checked, so moving a doc into an archive cannot strand the links to it.
ARCHIVE_DIR = "archive"
# A cookr version snapshot (`cookbook/<group>/<spec>/versions/<semver>/`) is the same
# kind of record: `cookr bump` freezes the published version there, and `cookr diff`
# reads it. Fixing a citation in the live spec bumps it, which snapshots the old text,
# citation and all; repointing the snapshot would make the diff lie. Skipped as a citing
# site only, exactly like an archive, and only under `cookbook/` with a semver segment.
SNAPSHOT_VERSION = re.compile(r"\d+\.\d+\.\d+")


def is_version_snapshot(rel: Path) -> bool:
    parts = rel.parts[:-1]
    return bool(parts) and parts[0] == "cookbook" and any(
        seg == "versions" and i + 1 < len(parts) and SNAPSHOT_VERSION.fullmatch(parts[i + 1])
        for i, seg in enumerate(parts)
    )


SKIP_SUFFIXES = {".png", ".jpg", ".jpeg", ".svg", ".woff2", ".map", ".lock"}
SKIP_NAMES = {"pnpm-lock.yaml", "package-lock.json"}
# The resolve-check's own self-test writes synthetic doc citations into temp
# dirs to prove the pass/fail paths, but those same literal fixture strings
# sit in the self-test's own source, and a repo-root scan (this guard's
# default) walks tools/ same as everything else. Skip that one file rather
# than the strings inside it: they are proof-of-behavior, not a citation
# into this repo. The retired-names guard's self-test is skipped by the same
# rule, so a fixture written there never has to resolve.
SKIP_NAMES |= {"check_doc_links_test.py", "check_no_retired_names_test.py"}


def normalize_source_path(raw: str, rest: str, top_level: set[str]) -> str | None:
    """The cited path, or None if it is not a citation this guard claims.

    `rest` is the remainder of the line after the match. `*` is deliberately outside
    the path pattern, so `packages/x/*.css` matches only as far as `packages/x` and
    the glob shows up here as a `rest` beginning `/*` — checking it that way keeps a
    bold-wrapped `**packages/x/y.ts**` (whose `rest` merely STARTS with `*`) a real
    citation rather than silently unchecked.
    """
    if rest.startswith("/*"):
        return None
    # A glob or placeholder inside the FILENAME (`pre_*_test.py`, `pre_<area>_test.py`)
    # stops the pattern mid-name, leaving a half-name that is no coordinate. `**` is not
    # one: that is a bold-wrapper closing a real citation.
    if rest.startswith("<") or (rest.startswith("*") and not rest.startswith("**")
                                and (raw[-1] in "._-" or rest[1:2].isalnum() or rest[1:2] == "_")):
        return None
    cited = raw.rstrip(_TRAILING)
    parts = cited.split("/")
    if len(parts) < 2 or parts[0] not in top_level:
        return None
    # `packages/apple/.../Sources` elides and `../x/y.ts` hops: neither names one file,
    # so neither can be resolved, and neither is a coordinate a reader could fix.
    if any(seg in ("...", "..") for seg in parts):
        return None
    return cited


def _git_env() -> dict[str, str]:
    """This process's environment without the variables that point git at another repo."""
    return {k: v for k, v in os.environ.items() if not k.startswith("GIT_")}


def _check_ignore(root: Path, queries: list[str]) -> list[str] | None:
    """The queries a rule in the repo's own .gitignore files ignores, or None when git
    gives no answer for the batch."""
    try:
        r = subprocess.run(
            ["git", "-C", str(root), "check-ignore", "-v", "-z", "--stdin"],
            input="".join(q + "\0" for q in queries), capture_output=True, text=True,
            env=_git_env(),
        )
    except OSError:
        return None
    # 0: some ignored, 1: none ignored, anything else (128: not a checkout, or a path
    # git refuses, such as one beyond a symlink): no answer.
    if r.returncode not in (0, 1):
        return None
    # -v -z answers in fours: source, line number, pattern, path. A negated pattern
    # (`!keep.log`) is reported too, and means the path is NOT ignored.
    fields = r.stdout.split("\0")
    ignored = []
    for source, _line, pattern, path in zip(*[iter(fields)] * 4):
        own = Path(source).name == ".gitignore" and not Path(source).is_absolute()
        if own and not pattern.startswith("!"):
            ignored.append(path)
    return ignored


def _tracked(root: Path, cited: list[str]) -> set[str]:
    """The cited paths the index holds, as a file or as a directory with files in it."""
    try:
        r = subprocess.run(
            ["git", "-C", str(root), "--literal-pathspecs", "ls-files", "-z", "--cached",
             "--", *cited],
            capture_output=True, text=True, env=_git_env(),
        )
    except OSError:
        return set()
    if r.returncode != 0:
        return set()
    files = [f for f in r.stdout.split("\0") if f]
    return {c for c in cited if any(f == c or f.startswith(c + "/") for f in files)}


def _is_checkout_top(root: Path) -> bool:
    """Whether `root` is the top of a git work tree (not just somewhere inside one)."""
    try:
        r = subprocess.run(
            ["git", "-C", str(root), "rev-parse", "--show-toplevel"],
            capture_output=True, text=True, env=_git_env(),
        )
    except OSError:
        return False
    return r.returncode == 0 and Path(r.stdout.strip()).resolve() == root.resolve()


def git_ignored(root: Path, cited: list[str]) -> set[str]:
    """The cited paths git ignores under `root` (see the docstring); empty outside a checkout."""
    if not cited or not _is_checkout_top(root):
        return set()
    # NUL-separated both ways (`-z`), so a non-ASCII path comes back as it was sent
    # rather than C-quoted, and each answer maps back to the citation it was asked for.
    asked = {q: c for c in cited for q in (c, c + "/")}
    answer = _check_ignore(root, list(asked))
    if answer is None:
        # One path git refuses fails the whole batch; ask path by path, so only that
        # one goes unanswered (and so is still checked). Outside a checkout every query
        # fails the same way, and nothing is ignored. Only the candidates for "dangling"
        # are asked, so this is a handful of calls, not one per citation.
        answer = [q for q in asked if _check_ignore(root, [q])]
    return {asked[q] for q in answer if q in asked} - _tracked(root, cited)


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--root", default=str(Path(__file__).resolve().parent.parent))
    args = ap.parse_args()
    root = Path(args.root).resolve()

    # Real top-level directories of the scanned root — the whole false-positive
    # containment for source-path citations (see the docstring). Computed from the
    # tree rather than hardcoded so a new top-level directory is covered the day it
    # lands, and so the self-test's temp roots behave like the real one.
    top_level = {
        child.name
        for child in root.iterdir()
        if child.is_dir() and not child.name.startswith(".") and child.name not in SKIP_DIRS
    }

    hits: dict[str, list[str]] = {}

    def record(cited: str, where: str) -> None:
        seen = hits.setdefault(cited, [])
        # One line can carry the same path twice (and a doc-path citation is matched
        # by both CITATION and SOURCE_CITATION) — report the site once.
        if where not in seen:
            seen.append(where)

    scanned = 0
    for path in sorted(root.rglob("*")):
        if not path.is_file() or path.suffix.lower() in SKIP_SUFFIXES:
            continue
        rel = path.relative_to(root)
        if SKIP_DIRS & set(rel.parts) or path.name in SKIP_NAMES or ARCHIVE_DIR in rel.parts[:-1]:
            continue
        if is_version_snapshot(rel):
            continue
        try:
            lines = path.read_text(encoding="utf-8").splitlines()
        except (UnicodeDecodeError, OSError):
            continue
        scanned += 1
        in_prose = rel.parts[0] in PROSE_DIRS
        for i, line in enumerate(lines, 1):
            for m in CITATION.finditer(line):
                cited = m.group(1)
                if not (root / cited).exists():
                    record(cited, f"{rel}:{i}")
            for m in RECIPE_URI.finditer(line):
                cited = f"recipes/{m.group(1)}.md"
                if not (root / cited).exists():
                    record(cited, f"{rel}:{i}")
            if not in_prose:
                continue
            for m in SOURCE_CITATION.finditer(line):
                cited = normalize_source_path(m.group(1), line[m.end():], top_level)
                if cited is None or (root / cited).exists():
                    continue
                record(cited, f"{rel}:{i}")

    if scanned == 0:
        print(f"check_doc_links: scanned NOTHING under {root} — wrong root, or the "
              f"skip list ate the tree. Not a pass.", file=sys.stderr)
        sys.exit(2)

    for cited in git_ignored(root, list(hits)):
        hits.pop(cited, None)

    if hits:
        for cited, where in sorted(hits.items(), key=lambda kv: -len(kv[1])):
            print(f"{cited} does not exist here ({len(where)} citation(s)):", file=sys.stderr)
            for w in where:
                print(f"    {w}", file=sys.stderr)
        print(f"\ncheck_doc_links: {len(hits)} dangling doc path(s) over {scanned} files. "
              f"Either bring the file, or drop the coordinate and keep the claim.",
              file=sys.stderr)
        sys.exit(1)

    print(f"check_doc_links: OK — every citation resolves ({scanned} files scanned)")


if __name__ == "__main__":
    main()
