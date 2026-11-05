#!/usr/bin/env python3
"""Self-test: the recipe-scope guard must actually catch a stale reference."""
import subprocess
import sys
import tempfile
from pathlib import Path

GUARD = Path(__file__).resolve().parent / "check_recipe_scope.py"


def run(root: Path) -> subprocess.CompletedProcess:
    return subprocess.run(
        [sys.executable, str(GUARD), "--root", str(root)], capture_output=True, text=True
    )


def test_clean_recipes_pass() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        (root / "button.md").write_text("Use `@adh-sdk/ui`.", encoding="utf-8")
        assert run(root).returncode == 0


def test_stale_scope_fails() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        (root / "button.md").write_text("Use `@agentic-toolkit/ui`.", encoding="utf-8")
        result = run(root)
        assert result.returncode == 1
        assert "button.md" in result.stdout + result.stderr
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        (root / "button.md").write_text("Use `@agenticdevelopertoolkit/ui`.", encoding="utf-8")
        assert run(root).returncode == 1


def test_empty_dir_is_an_error() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        assert run(Path(tmp)).returncode == 2


if __name__ == "__main__":
    test_clean_recipes_pass()
    test_stale_scope_fails()
    test_empty_dir_is_an_error()
    print("check_recipe_scope_test: 3 passed")
