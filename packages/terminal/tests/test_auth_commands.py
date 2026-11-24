from __future__ import annotations

import json

import httpx
import pytest
import respx
from typer.testing import CliRunner

from apt_terminal import auth_commands
from apt_terminal import config as c
from apt_terminal.auth import Session
from apt_terminal.errors import AuthError

BASE = "https://api.test"
SESSIONS = f"{BASE}/v1/auth/sessions"
runner = CliRunner()


def _session(tmp_path) -> Session:
    cfg = c.Config(path=tmp_path / "config.toml")
    cfg.profile().base_url = BASE
    return Session(profile=cfg.profile(), config=cfg)


@respx.mock
def test_login_command(tmp_path):
    sess = _session(tmp_path)
    app = auth_commands.build_auth_app(lambda: sess)
    respx.post(SESSIONS).mock(
        return_value=httpx.Response(
            200, json={"token": "a", "refresh_token": "r", "user": {"email": "u@x"}}
        )
    )
    res = runner.invoke(app, ["login", "--email", "u@x", "--password", "pw"])
    assert res.exit_code == 0, res.output
    assert "Logged in as u@x" in res.output
    assert sess.profile.access_token == "a"


@respx.mock
def test_login_command_completes_mfa_with_a_code(tmp_path):
    sess = _session(tmp_path)
    app = auth_commands.build_auth_app(lambda: sess)
    route = respx.post(SESSIONS).mock(side_effect=[
        httpx.Response(202, json={"mfa_required": True, "token": "pend",
                                  "methods": ["webauthn", "totp"]}),
        httpx.Response(200, json={"token": "a", "refresh_token": "r", "user": {"email": "u@x"}}),
    ])
    res = runner.invoke(app, ["login", "--identifier", "u@x", "--password", "pw"], input="654321\n")
    assert res.exit_code == 0, res.output
    assert json.loads(route.calls.last.request.content) == {
        "method": "totp", "token": "pend", "code": "654321",
    }
    assert sess.profile.access_token == "a"


@respx.mock
def test_login_command_sends_the_sms_before_asking(tmp_path):
    sess = _session(tmp_path)
    app = auth_commands.build_auth_app(lambda: sess)
    respx.post(SESSIONS).mock(side_effect=[
        httpx.Response(202, json={"mfa_required": True, "token": "pend", "methods": ["sms"]}),
        httpx.Response(200, json={"token": "a", "refresh_token": "r", "user": {"email": "u@x"}}),
    ])
    sms = respx.post(f"{BASE}/v1/auth/sms_codes").mock(
        return_value=httpx.Response(202, json={"ok": True})
    )
    res = runner.invoke(app, ["login", "--identifier", "u@x", "--password", "pw", "--code", "1"])
    assert res.exit_code == 0, res.output
    assert sms.called


def test_pick_factor():
    assert auth_commands.pick_factor(("sms", "totp"), None) == "totp"
    assert auth_commands.pick_factor(("sms", "totp"), "sms") == "sms"
    with pytest.raises(AuthError):
        auth_commands.pick_factor(("webauthn",), None)
    with pytest.raises(AuthError):
        auth_commands.pick_factor(("totp",), "sms")


@respx.mock
def test_whoami_command(tmp_path):
    sess = _session(tmp_path)
    sess.profile.access_token = "a"
    app = auth_commands.build_auth_app(lambda: sess)
    respx.get(f"{BASE}/v1/account").mock(
        return_value=httpx.Response(200, json={"object": "account", "email": "u@x", "id": "1"})
    )
    res = runner.invoke(app, ["whoami"])
    assert res.exit_code == 0, res.output
    assert "u@x" in res.output


@respx.mock
def test_logout_command(tmp_path):
    sess = _session(tmp_path)
    sess.profile.access_token = "a"
    sess.profile.refresh_token = "r"
    app = auth_commands.build_auth_app(lambda: sess)
    route = respx.post(f"{BASE}/v1/auth/sessions/revoke").mock(
        return_value=httpx.Response(200, json={"object": "auth.session"})
    )
    res = runner.invoke(app, ["logout"])
    assert res.exit_code == 0, res.output
    assert json.loads(route.calls.last.request.content) == {"refreshToken": "r"}
    assert sess.profile.access_token is None
    assert sess.profile.refresh_token is None


@respx.mock
def test_refresh_command(tmp_path):
    sess = _session(tmp_path)
    sess.profile.access_token = "old"
    sess.profile.refresh_token = "r"
    app = auth_commands.build_auth_app(lambda: sess)
    respx.post(f"{BASE}/v1/auth/sessions/refresh").mock(
        return_value=httpx.Response(200, json={"token": "new", "refresh_token": "r2"})
    )
    res = runner.invoke(app, ["refresh"])
    assert res.exit_code == 0, res.output
    assert sess.profile.access_token == "new"
    assert sess.profile.refresh_token == "r2"
