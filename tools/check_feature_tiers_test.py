#!/usr/bin/env python3
"""Self-test for check_feature_tiers — above all, that it CAN fail.

Each case plants a small repo with an `.abstractr.json` and a features directory
and asserts the guard's exit code. The case that matters most is the unlisted
directory: that is the package added later that would otherwise fall through to
the web-workspace catch-all with nothing saying so.

Plain asserts, no framework.
Run: python3 tools/check_feature_tiers_test.py   (exit 0 = pass).
"""
from __future__ import annotations

import json
import subprocess
import sys
import tempfile
from pathlib import Path

GUARD = Path(__file__).resolve().parent / "check_feature_tiers.py"
FEATURES = "packages/web/packages/features"


def run(repo_root: Path) -> subprocess.CompletedProcess:
    return subprocess.run(
        [sys.executable, str(GUARD), "--root", str(repo_root)],
        capture_output=True,
        text=True,
    )


def plant(repo_root: Path, dirs: list[str], tiers: list[dict]) -> None:
    for name in dirs:
        (repo_root / FEATURES / name).mkdir(parents=True, exist_ok=True)
    # Things the guard must ignore: a loose preset file, node_modules, a dot-dir.
    (repo_root / FEATURES / "tsup.preset.ts").write_text("export {}\n", encoding="utf-8")
    (repo_root / FEATURES / "node_modules").mkdir(parents=True, exist_ok=True)
    (repo_root / FEATURES / ".turbo").mkdir(parents=True, exist_ok=True)
    config = {"version": 1, "tiers": tiers, "rules": {}}
    (repo_root / ".abstractr.json").write_text(json.dumps(config), encoding="utf-8")


def base_tiers() -> list[dict]:
    return [
        {"name": "web-workspace", "paths": ["packages/web"]},
        {
            "name": "web-features",
            "paths": [f"{FEATURES}/account/", f"{FEATURES}/teams"],
        },
        {"name": "web-support-access", "paths": [f"{FEATURES}/support-access/"]},
        # A prefix naming the loose preset file, as web-toolchain does: not a package.
        {"name": "web-toolchain", "paths": [f"{FEATURES}/tsup.preset"]},
    ]


def test_every_dir_in_one_tier_passes() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        repo_root = Path(tmp)
        plant(repo_root, ["account", "teams", "support-access"], base_tiers())
        result = run(repo_root)
        assert result.returncode == 0, result.stderr
        assert "OK" in result.stdout


def test_an_unlisted_dir_fails() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        repo_root = Path(tmp)
        plant(repo_root, ["account", "teams", "support-access", "newthing"], base_tiers())
        result = run(repo_root)
        assert result.returncode == 1, f"unlisted dir not caught: {result.stdout}"
        assert f"{FEATURES}/newthing/" in result.stderr
        assert "add" in result.stderr and "web-features" in result.stderr


def test_a_dir_listed_by_two_tiers_fails() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        repo_root = Path(tmp)
        tiers = base_tiers()
        tiers[1]["paths"].append(f"{FEATURES}/support-access/")
        plant(repo_root, ["account", "teams", "support-access"], tiers)
        result = run(repo_root)
        assert result.returncode == 1, f"double listing not caught: {result.stdout}"
        assert "support-access" in result.stderr


def test_a_listed_path_with_no_dir_fails() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        repo_root = Path(tmp)
        tiers = base_tiers()
        tiers[1]["paths"].append(f"{FEATURES}/gone/")
        plant(repo_root, ["account", "teams", "support-access"], tiers)
        result = run(repo_root)
        assert result.returncode == 1, f"dead entry not caught: {result.stdout}"
        assert f"{FEATURES}/gone/" in result.stderr


def main() -> int:
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for test in tests:
        test()
    print(f"check_feature_tiers_test: {len(tests)} passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
