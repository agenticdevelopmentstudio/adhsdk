#!/usr/bin/env python3
"""Self-test: the retired-names guard catches every retired spelling, and only those."""
import subprocess
import sys
import tempfile
from pathlib import Path

GUARD = Path(__file__).resolve().parent / "check_no_retired_names.py"


def run(repo_root: Path, *roots: Path) -> subprocess.CompletedProcess:
    return subprocess.run(
        [sys.executable, str(GUARD), "--repo-root", str(repo_root), *map(str, roots)],
        capture_output=True, text=True,
    )


def check(line: str, expect_hit: bool, name: str = "docs/guide.md") -> None:
    with tempfile.TemporaryDirectory() as tmp:
        repo = Path(tmp)
        f = repo / name
        f.parent.mkdir(parents=True, exist_ok=True)
        f.write_text(line + "\n", encoding="utf-8")
        # A clean file too, so an exempt line reads as "scanned, clean" (0) and
        # not as "nothing to scan" (2).
        (repo / "clean.md").write_text("clean\n", encoding="utf-8")
        result = run(repo)
        want = 1 if expect_hit else 0
        assert result.returncode == want, f"{line!r} in {name}: exit {result.returncode}, wanted {want}\n{result.stderr}"


def test_retired_scopes_are_caught() -> None:
    check("import { x } from '@agentic-toolkit/model'", True)
    check("import { x } from '@agenticdevelopertoolkit/chat'", True)
    check("pnpm --filter '@agenticdevelopertoolkit/*' build", True)


def test_retired_names_are_caught_in_every_spelling() -> None:
    for line in (
        "import AgenticToolkitCore",
        "import AgenticDeveloperToolkitUI",
        "bundle id com.agentic-toolkit.app",
        "com.agentictoolkit.plugin.openai",
        "AGENTIC_TOOLKIT_HEADLESS=1",
        "the agentic developer toolkit's chat",
        "see adtoolkit://cookbook/ui/button",
        "the PersonaToolkit leftovers",
        "keeps the persona toolkit out of the graph",
        "external/agentictoolkit",
    ):
        check(line, True)


def test_current_names_pass() -> None:
    for line in (
        "import { x } from '@adh-sdk/model'",
        "import AgenticDeveloperHubSDKCore",
        "com.mikefullerton.agenticdeveloperhubsdk.app",
        "ADH_SDK_HEADLESS=1",
        "adhsdk://cookbook/ui/button",
        "talks to https://api.agenticdeveloperhub.com",
    ):
        check(line, False)


def test_names_outside_the_rename_pass() -> None:
    for line in (
        "deployed at https://agenticdevelopertoolkit.com",
        "and agenticdevelopertoolkit.dev",
        "the agenticpersonatoolkit product",
        "name: 'Agentic Persona Toolkit'",
        "adhcontent/content/adtoolkit/index.md",
        "the adtoolkitwebsite repo",
    ):
        check(line, False)


def test_legacy_files_sessions_and_guards_are_exempt() -> None:
    check('legacyService = "com.agentictoolkit"', False,
          "packages/apple/AgenticDeveloperHubSDK/AIPluginKit/SecretStoring.swift")
    check("we renamed AgenticToolkit today", False, "docs/sessions/2026-11-04.md")
    check('PATTERN = "@agentic-toolkit/"', False, "tools/check_no_retired_names.py")
    check('SCOPE = "@agentic-toolkit/"', True, "tools/helper.py")


def test_lockfiles_and_build_output_are_skipped() -> None:
    check("'@agentic-toolkit/ui':", False, "pnpm-lock.yaml")
    with tempfile.TemporaryDirectory() as tmp:
        repo = Path(tmp)
        (repo / "dist").mkdir()
        (repo / "dist" / "index.js").write_text("'@agentic-toolkit/ui'\n", encoding="utf-8")
        (repo / "README.md").write_text("clean\n", encoding="utf-8")
        assert run(repo).returncode == 0


def test_a_repo_inside_a_worktrees_dir_is_still_scanned() -> None:
    # The skip list names directories inside the repo. A checkout at
    # .claude/worktrees/<name>/ is the repo itself and must not skip every file.
    with tempfile.TemporaryDirectory() as tmp:
        repo = Path(tmp) / ".claude" / "worktrees" / "feature"
        repo.mkdir(parents=True)
        (repo / "README.md").write_text("clean\n", encoding="utf-8")
        assert run(repo).returncode == 0
        (repo / "README.md").write_text("AgenticToolkit\n", encoding="utf-8")
        assert run(repo).returncode == 1
        (repo / "README.md").write_text("clean\n", encoding="utf-8")
        (repo / "worktrees").mkdir()
        (repo / "worktrees" / "other.md").write_text("AgenticToolkit\n", encoding="utf-8")
        assert run(repo).returncode == 0


def test_the_toolkit_site_name_is_allowed_only_in_its_registry_row() -> None:
    registry = "packages/web/packages/adh-registry/src/sites/registry.ts"
    check("{ id: 'toolkit', fullLabel: 'Agentic Developer Toolkit' },", False, registry)
    # The rest of that line, and the name anywhere else, is still checked.
    check("{ fullLabel: 'Agentic Developer Toolkit', pkg: '@agentic-toolkit/ui' },", True, registry)
    check("description: 'Agentic Developer Toolkit'", True, registry)
    check("fullLabel: 'Agentic Developer Toolkit'", True, "docs/guide.md")


def test_the_adtoolkit_repo_is_allowed_only_in_its_named_files() -> None:
    support = ("packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKCoreTests/"
               "ClaudeHooks/StatusLineTestSupport.swift")
    check("/// The adtoolkit checkout, which owns claudehelpers' status-line", False, support)
    check("install adtoolkit (run ./install in its checkout, ~/.adtoolkitrc)", False, support)
    # Every other retired name in that file, and the old URI scheme, is still caught.
    check("/// adtoolkit's dispatcher, built by AgenticToolkit", True, support)
    check("see adtoolkit://cookbook/ui/button", True, support)
    # And the bare word anywhere else is still the retired SDK name.
    check("/// The adtoolkit checkout, which owns claudehelpers' status-line", True, "docs/guide.md")


def test_explicit_roots_scan_only_those() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        repo = Path(tmp)
        (repo / "a").mkdir()
        (repo / "b").mkdir()
        (repo / "a" / "x.md").write_text("clean\n", encoding="utf-8")
        (repo / "b" / "y.md").write_text("AgenticToolkit\n", encoding="utf-8")
        assert run(repo, repo / "a").returncode == 0
        assert run(repo, repo / "b").returncode == 1


def test_empty_scan_and_missing_root_are_not_a_pass() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        repo = Path(tmp)
        assert run(repo).returncode == 2
        assert run(repo, repo / "missing").returncode == 2


def main() -> int:
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for test in tests:
        test()
    print(f"check_no_retired_names_test: {len(tests)} passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
