#!/usr/bin/env python3
"""Post-build phase for every .aiplugin target: write the AIPluginKit ABI
version into the built bundle's Info.plist under `AIPluginKitABIVersion`.

The version is read from `AIPluginABI.version` in
AgenticDeveloperHubSDK/AIPluginKit/AIPluginABI.swift, so a plugin is always
stamped with the ABI of the AIPluginKit it was compiled against. The plugin
manager refuses a bundle whose stamp is missing or differs before it loads any
of its code. The build fails when the version cannot be read.
"""
from __future__ import annotations

import os
import plistlib
import re
import sys
from pathlib import Path

INFO_PLIST_KEY = "AIPluginKitABIVersion"
_VERSION_LINE = re.compile(r"^\s*public\s+static\s+let\s+version\s*=\s*(\d+)\s*$", re.MULTILINE)


def read_abi_version(swift_source: str) -> int:
    """The integer literal of `public static let version = N`; exactly one must exist."""
    matches = _VERSION_LINE.findall(swift_source)
    if len(matches) != 1:
        raise ValueError(f"expected one `public static let version = N` line, found {len(matches)}")
    return int(matches[0])


def stamp(plist_path: Path, version: int) -> None:
    """Write `version` under INFO_PLIST_KEY, keeping the plist's other keys and format."""
    raw = plist_path.read_bytes()
    fmt = plistlib.FMT_BINARY if raw.startswith(b"bplist") else plistlib.FMT_XML
    data = plistlib.loads(raw)
    if data.get(INFO_PLIST_KEY) == version:
        return
    data[INFO_PLIST_KEY] = version
    plist_path.write_bytes(plistlib.dumps(data, fmt=fmt))


def abi_source(project_dir: Path) -> Path:
    return project_dir.parent / "AgenticDeveloperHubSDK" / "AIPluginKit" / "AIPluginABI.swift"


def main() -> int:
    env = os.environ
    try:
        source = abi_source(Path(env["PROJECT_DIR"]))
        version = read_abi_version(source.read_text(encoding="utf-8"))
        plist_path = Path(env["TARGET_BUILD_DIR"]) / env["INFOPLIST_PATH"]
        stamp(plist_path, version)
    except (KeyError, OSError, ValueError, plistlib.InvalidFileException) as error:
        print(f"error: could not stamp the AIPluginKit ABI version: {error}", file=sys.stderr)
        return 1
    print(f"stamped {env.get('FULL_PRODUCT_NAME')} with {INFO_PLIST_KEY}={version}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
