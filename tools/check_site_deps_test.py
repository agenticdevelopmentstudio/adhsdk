#!/usr/bin/env python3
"""Self-test for check_site_deps.

Each case is written so that breaking the corresponding rule in the guard turns
this file red. The two that matter most are the ones a passing install would
hide: a specifier landing on the WRONG package, and an import the manifest never
declared — both of which resolve fine in a hoisted workspace and fail later.
"""
from __future__ import annotations

import json
import subprocess
import sys
import tempfile
from pathlib import Path

GUARD = Path(__file__).resolve().parent / "check_site_deps.py"


def run(repo_root: Path, root: str = "websites") -> subprocess.CompletedProcess:
    return subprocess.run(
        [sys.executable, str(GUARD), "--repo-root", str(repo_root), "--root", root],
        capture_output=True,
        text=True,
    )


def write_json(path: Path, data: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data), encoding="utf-8")


def make_package(repo_root: Path, name: str, directory: str) -> Path:
    """A package that a site can point at."""
    target = repo_root / directory
    write_json(target / "package.json", {"name": name, "version": "0.0.0"})
    return target


def make_site(
    repo_root: Path,
    name: str = "demo",
    deps: dict[str, str] | None = None,
    source: str | None = None,
) -> Path:
    site = repo_root / "websites" / name
    write_json(
        site / "package.json",
        {"name": f"{name}-site", "private": True, "dependencies": deps or {}},
    )
    if source is not None:
        (site / "src").mkdir(parents=True, exist_ok=True)
        (site / "src" / "page.tsx").write_text(source, encoding="utf-8")
    return site


def test_a_resolvable_specifier_naming_the_right_package_passes() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        repo_root = Path(tmp)
        make_package(repo_root, "@adh-sdk/chat", "packages/web/packages/chat")
        make_site(
            repo_root,
            deps={"@adh-sdk/chat": "file:../../packages/web/packages/chat"},
        )
        result = run(repo_root)
        assert result.returncode == 0, f"clean site rejected: {result.stderr}"


def test_a_specifier_resolving_nowhere_is_a_finding() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        repo_root = Path(tmp)
        make_site(
            repo_root,
            deps={"@adh-sdk/chat": "file:../../packages/web/packages/chat"},
        )
        result = run(repo_root)
        assert result.returncode == 1, f"dangling specifier missed: {result.stdout}"
        assert "resolves to no directory" in result.stderr


def test_a_specifier_resolving_to_the_wrong_package_is_a_finding() -> None:
    """The failure a successful install hides.

    The path exists, so pnpm is happy — but the site now has `search` installed
    under the name `chat`. Only comparing the target's declared name catches it.
    """
    with tempfile.TemporaryDirectory() as tmp:
        repo_root = Path(tmp)
        make_package(repo_root, "@adh-sdk/search", "packages/web/packages/chat")
        make_site(
            repo_root,
            deps={"@adh-sdk/chat": "file:../../packages/web/packages/chat"},
        )
        result = run(repo_root)
        assert result.returncode == 1, f"wrong package missed: {result.stdout}"
        assert "is package '@adh-sdk/search'" in result.stderr


def test_link_is_checked_the_same_as_file() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        repo_root = Path(tmp)
        make_site(
            repo_root,
            deps={"@adh-sdk/ui": "link:../../packages/web/packages/ui"},
        )
        result = run(repo_root)
        assert result.returncode == 1, f"link: specifier not checked: {result.stdout}"


def test_an_undeclared_owned_import_is_a_finding() -> None:
    """Resolves in a hoisted workspace, right up until the hoist changes."""
    with tempfile.TemporaryDirectory() as tmp:
        repo_root = Path(tmp)
        make_package(repo_root, "@adh-sdk/chat", "packages/web/packages/chat")
        make_site(
            repo_root,
            deps={"@adh-sdk/chat": "file:../../packages/web/packages/chat"},
            source="import { Button } from '@adh-sdk/ui'\n",
        )
        result = run(repo_root)
        assert result.returncode == 1, f"undeclared import missed: {result.stdout}"
        assert "does not declare it" in result.stderr


def test_a_subpath_import_is_credited_to_its_package() -> None:
    """`@scope/ui/components/card` is the `@scope/ui` dependency, not a new one."""
    with tempfile.TemporaryDirectory() as tmp:
        repo_root = Path(tmp)
        make_package(repo_root, "@adh-sdk/ui", "packages/web/packages/ui")
        make_site(
            repo_root,
            deps={"@adh-sdk/ui": "file:../../packages/web/packages/ui"},
            source="import { Card } from '@adh-sdk/ui/components/card'\n",
        )
        result = run(repo_root)
        assert result.returncode == 0, f"subpath treated as its own package: {result.stderr}"


def test_a_third_party_import_is_not_this_guards_business() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        repo_root = Path(tmp)
        make_site(repo_root, source="import React from 'react'\nimport Link from 'next/link'\n")
        result = run(repo_root)
        assert result.returncode == 0, f"third-party import flagged: {result.stderr}"


def test_a_dev_dependency_counts_as_declared() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        repo_root = Path(tmp)
        make_package(repo_root, "@adh-sdk/themes", "packages/web/packages/themes")
        site = make_site(repo_root, source="import '@adh-sdk/themes'\n")
        write_json(
            site / "package.json",
            {
                "name": "demo-site",
                "devDependencies": {
                    "@adh-sdk/themes": "file:../../packages/web/packages/themes"
                },
            },
        )
        result = run(repo_root)
        assert result.returncode == 0, f"devDependency not counted: {result.stderr}"


def test_node_modules_is_not_scanned_for_imports() -> None:
    """An installed copy's own source is not this site's import graph."""
    with tempfile.TemporaryDirectory() as tmp:
        repo_root = Path(tmp)
        site = make_site(repo_root)
        vendored = site / "node_modules" / "something" / "dist"
        vendored.mkdir(parents=True)
        (vendored / "index.js").write_text(
            "require('@adh-sdk/search')\n", encoding="utf-8"
        )
        result = run(repo_root)
        assert result.returncode == 0, f"node_modules scanned: {result.stderr}"


def test_a_missing_sites_directory_is_exit_2() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        result = run(Path(tmp))
        assert result.returncode == 2, f"missing root was not exit 2: {result.returncode}"
        # The exact diagnosis, not just the exit code: an absent directory and a
        # directory holding no manifests are both 2, so asserting only the code
        # leaves the two branches indistinguishable and one of them dead.
        assert "no such directory" in result.stderr, result.stderr


def test_a_sites_directory_with_no_manifests_is_exit_2() -> None:
    """An empty scan is never a pass — the layout moving out from under the guard
    looks exactly like a clean repo if this returns 0."""
    with tempfile.TemporaryDirectory() as tmp:
        repo_root = Path(tmp)
        (repo_root / "websites").mkdir()
        (repo_root / "websites" / "run.sh").write_text("#!/bin/sh\n", encoding="utf-8")
        result = run(repo_root)
        assert result.returncode == 2, f"empty scan was not exit 2: {result.returncode}"
        assert "no site manifests" in result.stderr, result.stderr


def test_every_site_is_checked_not_just_the_first() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        repo_root = Path(tmp)
        make_package(repo_root, "@adh-sdk/chat", "packages/web/packages/chat")
        make_site(
            repo_root,
            name="aaa-clean",
            deps={"@adh-sdk/chat": "file:../../packages/web/packages/chat"},
        )
        make_site(
            repo_root,
            name="zzz-broken",
            deps={"@adh-sdk/ui": "file:../../packages/web/packages/ui"},
        )
        result = run(repo_root)
        assert result.returncode == 1, f"second site not checked: {result.stdout}"
        assert "zzz-broken" in result.stderr


def main() -> int:
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for test in tests:
        test()
    print(f"check_site_deps_test: {len(tests)} passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
