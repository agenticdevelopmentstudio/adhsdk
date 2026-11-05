#!/usr/bin/env python3
"""No file in this repo may name the SDK by a name it no longer goes by.

This guard used to be check_no_private_scope.py, written when this repo was a
public toolkit and the AgenticToolkit packages arriving in it came from a private
repo. That repo merged in and its names are now this SDK's retired names, so the
same check became this one.

This SDK has been renamed twice. It started as AgenticToolkit, with its web
packages under `@agentic-toolkit/*`. A first rename meant to move everything to
Agentic Developer Toolkit (`@agenticdevelopertoolkit/*`) moved eight packages and
one Xcode project and stopped, which left two scopes and two Apple names live at
once. Phase 5 of the adhsdk rename finished the job: the repo is `adhsdk`, every
web package is `@adh-sdk/*`, and every Apple module, project and bundle ID is
`AgenticDeveloperHubSDK`.

A retired name is never harmless where it survives. An import of a retired scope
names a package nobody publishes. A path names a directory that is gone. A bundle
ID or a defaults key quietly starts a second copy of a user's data. So this guard
fails on any of them, anywhere in the repo.

Patterns:

  retired package scope   `@agentic-toolkit` and `@agenticdevelopertoolkit`.
  retired SDK name        AgenticToolkit, Agentic Developer Toolkit, adtoolkit and
                          PersonaToolkit, in any case and with any separator,
                          which covers module names, bundle IDs, env vars, paths
                          and prose.

What is NOT a retired name:

  * The agenticdevelopertoolkit.com and .dev domains, the agenticpersonatoolkit
    product, and adhcontent's `content/adtoolkit` folder. The site keeps its
    domains until it moves, which is a separate piece of work.
  * The files in LEGACY_FILES. Each one reads data an older build wrote under a
    retired name, so it has to spell that name to find the data.
  * Dated history in `docs/sessions/`, which records what was true at the time.
  * The guards themselves, and their self-tests, by filename only. A guard that
    hunts a string has to contain it.

Exit 0 clean, 1 on a hit, 2 if there was nothing to scan or a named root does not
exist. An empty scan is a broken path, never a pass.
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]

PATTERNS = {
    "retired package scope": re.compile(r"@agentic-toolkit\b|@agenticdevelopertoolkit\b", re.IGNORECASE),
    "retired SDK name": re.compile(
        r"agentic[-_ ]?(?:developer[-_ ]?)?toolkit(?!\.(?:com|dev)\b)"
        r"|(?<!content/)\badtoolkit\b"
        r"|(?<!agentic )\bpersona[-_ ]?toolkit",
        re.IGNORECASE,
    ),
}

# Repo-relative files that read data an older build wrote under a retired name.
# Each must keep spelling that name, and nothing else in it is exempt from review:
# add a file here only for that reason.
LEGACY_FILES = {
    # Keychain items saved under the old service name.
    "packages/apple/AgenticDeveloperHubSDK/AIPluginKit/SecretStoring.swift",
    "cookbook/ai/plugins/secret-storing.md",
    "cookbook/ai/plugins/secret-storing/platform-notes.md",
    # Settings saved under the old plugin IDs.
    "packages/apple/AgenticDeveloperHubSDK/macOS/Features/AIPlugins/AIProviderMigration.swift",
    "packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKMacOSTests/AIPlugins/AIProviderMigrationTests.swift",
    # The window-contexts state directory the sample host used to write.
    "packages/apple/AgenticDeveloperHubSDKApp/AgenticDeveloperHubSDKApp/WindowContextsCoordinator.swift",
    # The localStorage key the color-mode choice used to live under.
    "packages/web/packages/themes/src/colorMode.tsx",
}

# Dated history: it records what was true when it was written.
SKIP_PREFIXES = ("docs/sessions/",)

SKIP_DIRS = {"node_modules", "dist", ".turbo", ".git", "coverage", ".next",
             # Git-ignored scratch and other checkouts of this repo.
             ".superpowers", "worktrees"}

# A lockfile names whatever the manifests name and is regenerated, not edited.
SKIP_NAMES = {
    "pnpm-lock.yaml", "package-lock.json", "yarn.lock",
    # The guards and their self-tests (see the docstring).
    "check_no_retired_names.py", "check_no_retired_names_test.py",
    "check_doc_links.py", "check_doc_links_test.py",
    "check_recipe_scope.py", "check_recipe_scope_test.py",
    "check_doc_subpaths.py", "check_doc_subpaths_test.py",
}
SKIP_SUFFIXES = {
    ".png", ".jpg", ".jpeg", ".gif", ".webp", ".ico", ".svg",
    ".woff", ".woff2", ".ttf", ".otf", ".eot",
    ".pdf", ".zip", ".gz", ".map",
}


def _scan_lines(text: str, rel: str) -> list[str]:
    hits: list[str] = []
    for lineno, line in enumerate(text.splitlines(), start=1):
        for label, pattern in PATTERNS.items():
            if pattern.search(line):
                hits.append(f"{rel}:{lineno}: {label}: {line.strip()}")
    return hits


def _skipped(path: Path, repo_root: Path) -> bool:
    try:
        rel = path.relative_to(repo_root).as_posix()
    except ValueError:
        rel = path.as_posix()
    if rel in LEGACY_FILES or rel.startswith(SKIP_PREFIXES):
        return True
    if any(part in SKIP_DIRS for part in path.parts):
        return True
    return path.name in SKIP_NAMES or path.suffix.lower() in SKIP_SUFFIXES


def scan(root: Path, repo_root: Path) -> tuple[list[str], int]:
    hits: list[str] = []
    scanned = 0
    paths = [root] if root.is_file() else sorted(root.rglob("*"))
    for path in paths:
        if not path.is_file() or _skipped(path, repo_root):
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            continue
        scanned += 1
        try:
            rel = path.relative_to(repo_root).as_posix()
        except ValueError:
            rel = path.as_posix()
        hits.extend(_scan_lines(text, rel))
    return hits, scanned


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("roots", nargs="*", type=Path,
                        help="files or trees to scan (default: the whole repo)")
    parser.add_argument("--repo-root", default=None,
                        help="the repo to scan by default and to resolve LEGACY_FILES against "
                             "(self-test only)")
    args = parser.parse_args()
    repo_root = Path(args.repo_root).resolve() if args.repo_root else REPO_ROOT
    roots = [r.resolve() for r in args.roots] or [repo_root]

    all_hits: list[str] = []
    total = 0
    for root in roots:
        if not root.exists():
            print(f"check_no_retired_names: no such path: {root}", file=sys.stderr)
            return 2
        hits, scanned = scan(root, repo_root)
        all_hits.extend(hits)
        total += scanned

    if total == 0:
        print(f"check_no_retired_names: nothing to scan under {roots}", file=sys.stderr)
        return 2
    if all_hits:
        print(f"check_no_retired_names: {len(all_hits)} hit(s) in {total} files:\n", file=sys.stderr)
        for hit in all_hits:
            print(f"  {hit}", file=sys.stderr)
        print("\nRename it to the SDK's current name (adhsdk, @adh-sdk/*, AgenticDeveloperHubSDK). "
              "If the file reads data written under the old name, add it to LEGACY_FILES.",
              file=sys.stderr)
        return 1
    print(f"check_no_retired_names: {total} files, no retired names")
    return 0


if __name__ == "__main__":
    sys.exit(main())
