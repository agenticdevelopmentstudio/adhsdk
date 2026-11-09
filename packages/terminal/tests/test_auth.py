from __future__ import annotations

import json

import httpx
import pytest
import respx

from apt_terminal import config as c
from apt_terminal.auth import MfaRequired, Session
from apt_terminal.errors import AuthError

BASE = "https://api.test"
SESSIONS = f"{BASE}/v1/auth/sessions"


def _session(tmp_path) -> Session:
    cfg = c.Config(path=tmp_path / "config.toml")
    p = cfg.profile()
    p.base_url = BASE
    return Session(profile=p, config=cfg)


@respx.mock
def test_login_stores_tokens_and_saves(tmp_path):
    s = _session(tmp_path)
    route = respx.post(SESSIONS).mock(
        return_value=httpx.Response(
            200,
            json={"object": "auth.session", "token": "acc1", "refresh_token": "ref1",
                  "user": {"email": "u@x.test"}},
        )
    )
    email = s.login("u@x.test", "pw")
    assert email == "u@x.test"
    assert s.profile.access_token == "acc1"
    assert s.profile.refresh_token == "ref1"
    # the discriminator the gateway routes on, plus the credentials
    assert json.loads(route.calls.last.request.content) == {
        "method": "password", "identifier": "u@x.test", "password": "pw",
    }
    # persisted to disk
    assert c.load(s.config.path).profile().access_token == "acc1"


@respx.mock
def test_login_failure_raises_with_the_stripe_error_message(tmp_path):
    s = _session(tmp_path)
    respx.post(SESSIONS).mock(
        return_value=httpx.Response(
            401, json={"error": {"type": "authentication_error", "message": "invalid credentials"}}
        )
    )
    with pytest.raises(AuthError, match="invalid credentials"):
        s.login("u@x.test", "wrong")


@respx.mock
def test_login_202_raises_mfa_required(tmp_path):
    s = _session(tmp_path)
    respx.post(SESSIONS).mock(
        return_value=httpx.Response(
            202, json={"mfa_required": True, "token": "pend", "methods": ["totp", "sms"]}
        )
    )
    with pytest.raises(MfaRequired) as exc:
        s.login("u@x.test", "pw")
    assert exc.value.token == "pend"
    assert exc.value.methods == ("totp", "sms")
    assert s.profile.access_token is None


@respx.mock
def test_complete_mfa_posts_method_token_code(tmp_path):
    s = _session(tmp_path)
    route = respx.post(SESSIONS).mock(
        return_value=httpx.Response(
            200, json={"token": "acc", "refresh_token": "ref", "user": {"email": "u@x"}}
        )
    )
    assert s.complete_mfa("pend", "totp", "123456") == "u@x"
    assert json.loads(route.calls.last.request.content) == {
        "method": "totp", "token": "pend", "code": "123456",
    }
    assert s.profile.refresh_token == "ref"


def test_complete_mfa_refuses_a_passkey(tmp_path):
    with pytest.raises(AuthError):
        _session(tmp_path).complete_mfa("pend", "webauthn", "x")


@respx.mock
def test_send_sms_code(tmp_path):
    route = respx.post(f"{BASE}/v1/auth/sms_codes").mock(
        return_value=httpx.Response(202, json={"ok": True})
    )
    _session(tmp_path).send_sms_code("pend")
    assert json.loads(route.calls.last.request.content) == {"token": "pend"}


@respx.mock
def test_refresh_updates_both_tokens(tmp_path):
    s = _session(tmp_path)
    s.profile.access_token = "old"
    s.profile.refresh_token = "ref1"
    route = respx.post(f"{BASE}/v1/auth/sessions/refresh").mock(
        return_value=httpx.Response(200, json={"token": "acc2", "refresh_token": "ref2"})
    )
    assert s.refresh() is True
    assert json.loads(route.calls.last.request.content) == {"refreshToken": "ref1"}
    assert s.profile.access_token == "acc2"
    assert s.profile.refresh_token == "ref2"


@respx.mock
def test_refresh_rejected_returns_false(tmp_path):
    s = _session(tmp_path)
    s.profile.refresh_token = "ref1"
    respx.post(f"{BASE}/v1/auth/sessions/refresh").mock(
        return_value=httpx.Response(401, json={"error": {"type": "authentication_error",
                                                         "message": "expired"}})
    )
    assert s.refresh() is False


def test_refresh_without_token_returns_false(tmp_path):
    s = _session(tmp_path)
    assert s.refresh() is False


def test_client_factory_requires_token(tmp_path):
    s = _session(tmp_path)
    with pytest.raises(AuthError):
        s.client_factory()


def test_client_factory_builds_authed(tmp_path):
    s = _session(tmp_path)
    s.profile.access_token = "acc"
    client = s.client_factory()
    assert client.token == "acc"
    assert client._base_url == BASE


def test_env_token_override_not_persisted(tmp_path, monkeypatch):
    s = _session(tmp_path)  # base_url=BASE, no tokens
    monkeypatch.setenv("APT_TOKEN", "envtok")
    client = s.client_factory()
    assert client.token == "envtok"
    assert s.profile.access_token is None          # not written into the profile
    assert not (tmp_path / "config.toml").exists()  # nothing saved
