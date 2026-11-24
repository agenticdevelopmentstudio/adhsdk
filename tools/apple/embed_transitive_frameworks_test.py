#!/usr/bin/env python3
"""Tests for embed_transitive_frameworks.py: the bundle layout it embeds into.

Run: python3 -m pytest tools/apple/embed_transitive_frameworks_test.py -q
"""
from __future__ import annotations

import plistlib
from pathlib import Path

import embed_transitive_frameworks as etf


def write_plist(path: Path, values: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("wb") as handle:
        plistlib.dump(values, handle)


def test_a_macos_app_keeps_its_binary_and_frameworks_under_contents(tmp_path: Path):
    app = tmp_path / "Hub.app"
    write_plist(app / "Contents" / "Info.plist", {"CFBundleExecutable": "Hub"})
    assert etf.bundle_layout(app) == (app / "Contents" / "MacOS" / "Hub", app / "Contents" / "Frameworks")


def test_an_ios_app_is_flat(tmp_path: Path):
    app = tmp_path / "Hub.app"
    write_plist(app / "Info.plist", {"CFBundleExecutable": "Hub"})
    assert etf.bundle_layout(app) == (app / "Hub", app / "Frameworks")


def test_the_executable_name_comes_from_the_info_plist(tmp_path: Path):
    app = tmp_path / "Agentic Developer Hub.app"
    write_plist(app / "Info.plist", {"CFBundleExecutable": "ADHub"})
    binary, _ = etf.bundle_layout(app)
    assert binary == app / "ADHub"


def test_without_an_info_plist_the_bundle_name_is_the_executable(tmp_path: Path):
    app = tmp_path / "Hub.app"
    (app / "Contents").mkdir(parents=True)
    binary, _ = etf.bundle_layout(app)
    assert binary == app / "Contents" / "MacOS" / "Hub"


def test_an_unreadable_info_plist_falls_back_to_the_bundle_name(tmp_path: Path):
    app = tmp_path / "Hub.app"
    app.mkdir()
    (app / "Info.plist").write_bytes(b"not a plist")
    assert etf.bundle_layout(app) == (app / "Hub", app / "Frameworks")


def test_a_missing_ios_binary_is_an_error_not_a_crash(tmp_path: Path, capsys):
    app = tmp_path / "Hub.app"
    write_plist(app / "Info.plist", {"CFBundleExecutable": "Hub"})
    products = tmp_path / "products"
    products.mkdir()
    assert etf.main(["embed", str(app), str(products)]) == 1
    assert f"app binary not found: {app.resolve() / 'Hub'}" in capsys.readouterr().err


def test_copies_are_signed_with_the_identity_xcode_hands_the_build_phase():
    assert etf.signing_identity({"EXPANDED_CODE_SIGN_IDENTITY": "ABC123"}) == "ABC123"
    assert etf.signing_identity({"EXPANDED_CODE_SIGN_IDENTITY": "-"}) == "-"


def test_copies_stay_unsigned_without_an_identity_or_when_signing_is_off():
    assert etf.signing_identity({}) is None
    assert etf.signing_identity({"EXPANDED_CODE_SIGN_IDENTITY": ""}) is None
    assert etf.signing_identity({"EXPANDED_CODE_SIGN_IDENTITY": "ABC123", "CODE_SIGNING_ALLOWED": "NO"}) is None


def test_xcode_mode_reads_the_app_from_target_build_dir():
    env = {"TARGET_BUILD_DIR": "/install/Applications", "WRAPPER_NAME": "Hub.app",
           "BUILT_PRODUCTS_DIR": "/dd/Build/Products/Release"}
    assert etf.xcode_paths(env) == (Path("/install/Applications/Hub.app"), Path("/dd/Build/Products/Release"))


def test_xcode_mode_without_build_settings_is_an_error_not_a_skip():
    message = etf.xcode_paths({"WRAPPER_NAME": "Hub.app"})
    assert isinstance(message, str)
    assert "TARGET_BUILD_DIR" in message and "BUILT_PRODUCTS_DIR" in message


def test_xcode_mode_fails_the_build_when_the_app_is_missing(tmp_path: Path, monkeypatch, capsys):
    products = tmp_path / "products"
    products.mkdir()
    monkeypatch.setenv("TARGET_BUILD_DIR", str(products))
    monkeypatch.setenv("WRAPPER_NAME", "Hub.app")
    monkeypatch.setenv("BUILT_PRODUCTS_DIR", str(products))
    assert etf.main(["embed", "--xcode"]) == 1
    assert "app binary not found" in capsys.readouterr().err


def test_a_copy_made_this_run_is_always_signed_even_when_it_verifies():
    assert etf.needs_signing(Path("X.framework"), True, verify=lambda _: True)


def test_a_framework_already_in_place_is_signed_only_when_it_does_not_verify():
    assert not etf.needs_signing(Path("X.framework"), False, verify=lambda _: True)
    assert etf.needs_signing(Path("X.framework"), False, verify=lambda _: False)
