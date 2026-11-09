"""Regression test for `_spec_input.resolve_spec` — the `--` argv strip B3
extracted out of gen_endpoints.py and gen_table_metadata.py (previously
duplicated byte-for-byte, and untested in either copy). Without this, the
failure mode for a `pnpm --filter … gen:… -- <spec>` invocation is the
unhelpful `spec not found: <cwd>/--` (the separator itself read as the path).

Pattern matches the sibling precedent:
packages/apple/AgenticDeveloperHubClient/scripts/test_generate_spec_arg.py
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import _spec_input as si  # noqa: E402


def test_dashdash_separator_is_stripped(tmp_path):
    spec = tmp_path / "openapi.json"
    spec.write_text("{}")

    assert si.resolve_spec(["--", str(spec)]) == spec


def test_bare_positional_arg(tmp_path):
    spec = tmp_path / "openapi.json"
    spec.write_text("{}")

    assert si.resolve_spec([str(spec)]) == spec


def test_dashdash_alone_falls_back_to_env_var(tmp_path, monkeypatch):
    spec = tmp_path / "openapi.json"
    spec.write_text("{}")
    monkeypatch.setenv("ADH_OPENAPI_SPEC", str(spec))

    assert si.resolve_spec(["--"]) == spec


def test_no_arg_and_no_env_var_exits_with_a_helpful_message(monkeypatch):
    monkeypatch.delenv("ADH_OPENAPI_SPEC", raising=False)

    try:
        si.resolve_spec([])
    except SystemExit as exc:
        assert "ADH_OPENAPI_SPEC" in str(exc)
    else:
        raise AssertionError("resolve_spec([]) should have raised SystemExit")


def test_url_is_downloaded_to_a_temp_file(monkeypatch):
    class _Res:
        def __enter__(self):
            return self

        def __exit__(self, *exc):
            return False

        def read(self):
            return b'{"openapi": "3.1.0"}'

    seen = []

    def fake_urlopen(url, timeout):
        seen.append(url)
        return _Res()

    monkeypatch.setattr(si.urllib.request, "urlopen", fake_urlopen)

    path = si.resolve_spec([si.LIVE_V1_SPEC_URL])
    try:
        assert seen == [si.LIVE_V1_SPEC_URL]
        assert path.read_text() == '{"openapi": "3.1.0"}'
    finally:
        path.unlink()


def test_nonexistent_path_exits_loudly_rather_than_reading_as_no_spec(tmp_path):
    missing = tmp_path / "does-not-exist.json"

    try:
        si.resolve_spec([str(missing)])
    except SystemExit as exc:
        assert "spec not found" in str(exc)
    else:
        raise AssertionError("resolve_spec should reject a path that doesn't exist")
