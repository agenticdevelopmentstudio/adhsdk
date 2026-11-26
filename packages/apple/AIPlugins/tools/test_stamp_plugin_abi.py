"""Unit tests for the AIPluginKit ABI stamp post-build script."""
import plistlib

import pytest

import stamp_plugin_abi as s


def test_reads_the_version_line():
    source = "public enum AIPluginABI {\n    public static let version = 3\n}\n"
    assert s.read_abi_version(source) == 3


def test_rejects_a_missing_or_ambiguous_version():
    with pytest.raises(ValueError):
        s.read_abi_version("public enum AIPluginABI {}")
    with pytest.raises(ValueError):
        s.read_abi_version("public static let version = 1\npublic static let version = 2\n")


def test_reads_the_real_source():
    tools = s.Path(__file__).resolve().parent
    source = s.abi_source(tools.parent).read_text(encoding="utf-8")
    assert s.read_abi_version(source) >= 1


@pytest.mark.parametrize("fmt", [plistlib.FMT_XML, plistlib.FMT_BINARY])
def test_stamps_and_keeps_keys_and_format(tmp_path, fmt):
    path = tmp_path / "Info.plist"
    path.write_bytes(plistlib.dumps({"CFBundleIdentifier": "x.y"}, fmt=fmt))

    s.stamp(path, 2)

    raw = path.read_bytes()
    assert raw.startswith(b"bplist") == (fmt == plistlib.FMT_BINARY)
    assert plistlib.loads(raw) == {"CFBundleIdentifier": "x.y", s.INFO_PLIST_KEY: 2}


def test_main_fails_without_the_build_environment(monkeypatch):
    for key in ("PROJECT_DIR", "TARGET_BUILD_DIR", "INFOPLIST_PATH"):
        monkeypatch.delenv(key, raising=False)
    assert s.main() == 1
