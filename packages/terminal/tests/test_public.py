from __future__ import annotations

import httpx
import respx
from typer.testing import CliRunner

from apt_terminal import config as c
from apt_terminal import public
from apt_terminal.auth import Session

BASE = "https://api.test"
runner = CliRunner()


def _session(tmp_path) -> Session:
    cfg = c.Config(path=tmp_path / "config.toml")
    cfg.profile().base_url = BASE
    return Session(profile=cfg.profile(), config=cfg)


@respx.mock
def test_public_persona(tmp_path):
    app = public.build_public_app(lambda: _session(tmp_path))
    route = respx.get(f"{BASE}/v1/personas", params={"slug": "zed"}).mock(
        return_value=httpx.Response(200, json={"object": "persona", "slug": "zed", "name": "Zed"})
    )
    res = runner.invoke(app, ["persona", "zed", "--json"])
    assert res.exit_code == 0, res.output
    assert "zed" in res.output
    request = route.calls.last.request
    assert "authorization" not in request.headers
    assert "limit" not in request.url.params  # a lookup, not a listing


@respx.mock
def test_public_user(tmp_path):
    app = public.build_public_app(lambda: _session(tmp_path))
    respx.get(f"{BASE}/v1/users", params={"handle": "zed"}).mock(
        return_value=httpx.Response(200, json={"object": "user", "slug": "zed", "name": "Zed"})
    )
    res = runner.invoke(app, ["user", "zed", "--json"])
    assert res.exit_code == 0, res.output
    assert "zed" in res.output


@respx.mock
def test_public_not_found_exits_4(tmp_path):
    app = public.build_public_app(lambda: _session(tmp_path))
    respx.get(f"{BASE}/v1/users").mock(
        return_value=httpx.Response(
            404, json={"error": {"type": "invalid_request_error", "code": "resource_missing",
                                 "message": "no such user"}}
        )
    )
    res = runner.invoke(app, ["user", "nobody"])
    assert res.exit_code != 0
