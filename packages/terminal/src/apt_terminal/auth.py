from __future__ import annotations

import contextlib
import os
from typing import Any

import httpx

from apt_terminal import config as config_mod
from apt_terminal import errors
from apt_terminal.config import Config, Profile
from apt_terminal.errors import AuthError
from apt_terminal.generated import AuthenticatedClient, Client
from apt_terminal.generated.api.auth import (
    get_v1_account,
    post_v1_auth_sessions,
    post_v1_auth_sessions_refresh,
    post_v1_auth_sessions_revoke,
    post_v1_auth_sms_codes,
)
from apt_terminal.generated.models.post_v1_auth_sessions_body import PostV1AuthSessionsBody
from apt_terminal.generated.models.post_v1_auth_sessions_body_method import (
    PostV1AuthSessionsBodyMethod,
)
from apt_terminal.generated.models.post_v1_auth_sms_codes_body import PostV1AuthSmsCodesBody

# The second factors a terminal can satisfy by typing a code, in the order `apt auth login`
# offers them. A passkey (`webauthn`) needs a browser authenticator and is not among them.
CODE_FACTORS: tuple[str, ...] = ("totp", "sms", "recovery")


class MfaRequired(Exception):
    """The password was right but the account has a second factor enrolled.

    `POST /v1/auth/sessions` answers 202 with a short-lived pending `token` and the enrolled
    `methods`; the session is minted by sending that token back with a code
    (`Session.complete_mfa`).
    """

    def __init__(self, token: str, methods: tuple[str, ...]) -> None:
        super().__init__("a second factor is required")
        self.token = token
        self.methods = methods


class Session:
    """Owns the auth lifecycle and builds generated clients for the engine."""

    def __init__(self, profile: Profile, config: Config) -> None:
        self.profile = profile
        self.config = config

    @property
    def base_url(self) -> str:
        return os.environ.get("APT_BASE_URL") or self.profile.base_url

    def login(self, identifier: str, password: str) -> str:
        """Password login. Returns the account email, or raises MfaRequired / AuthError."""
        body = PostV1AuthSessionsBody(method=PostV1AuthSessionsBodyMethod.PASSWORD)
        body.additional_properties.update({"identifier": identifier, "password": password})
        resp = self._post(post_v1_auth_sessions._get_kwargs(body=body))
        if resp.status_code == 202:
            data = resp.json()
            raise MfaRequired(
                token=str(data.get("token") or ""),
                methods=tuple(str(m) for m in data.get("methods") or ()),
            )
        return self._store_session(resp, "login failed", fallback_email=identifier)

    def complete_mfa(self, token: str, method: str, code: str) -> str:
        """Finish an MFA login with a typed code. Returns the account email."""
        if method not in CODE_FACTORS:
            raise AuthError(
                f"'{method}' cannot be completed from a terminal; use one of: "
                f"{', '.join(CODE_FACTORS)}"
            )
        body = PostV1AuthSessionsBody(method=PostV1AuthSessionsBodyMethod(method))
        body.additional_properties.update({"token": token, "code": code})
        resp = self._post(post_v1_auth_sessions._get_kwargs(body=body))
        return self._store_session(resp, "verification failed", fallback_email="")

    def send_sms_code(self, token: str) -> None:
        """Ask the server to text the login code for a pending MFA token."""
        resp = self._post(post_v1_auth_sms_codes._get_kwargs(body=PostV1AuthSmsCodesBody(token=token)))
        if resp.status_code >= 400:
            raise AuthError(_message(resp, "could not send the SMS code"))

    def refresh(self) -> bool:
        if not self.profile.refresh_token:
            return False
        resp = self._post(
            {
                **post_v1_auth_sessions_refresh._get_kwargs(),
                "json": {"refreshToken": self.profile.refresh_token},
            }
        )
        if resp.status_code != 200:
            return False
        data = resp.json()
        access = data.get("token")
        if not access:
            return False
        self.profile.access_token = access
        # The old refresh token is single-use; keep it only if the server somehow sent none.
        self.profile.refresh_token = data.get("refresh_token") or self.profile.refresh_token
        config_mod.save(self.config)
        return True

    def logout(self) -> None:
        if self.profile.refresh_token:
            with contextlib.suppress(httpx.HTTPError):
                self._post(
                    {
                        **post_v1_auth_sessions_revoke._get_kwargs(),
                        "json": {"refreshToken": self.profile.refresh_token},
                    }
                )
        self.profile.access_token = None
        self.profile.refresh_token = None
        config_mod.save(self.config)

    def whoami(self) -> dict[str, Any]:
        kwargs = get_v1_account._get_kwargs()
        resp = self.client_factory().get_httpx_client().request(**kwargs)
        if resp.status_code == 401 and self.refresh():
            resp = self.client_factory().get_httpx_client().request(**kwargs)
        if resp.status_code != 200:
            raise AuthError("not logged in or session expired")
        result: dict[str, Any] = resp.json()
        return result

    def client_factory(self) -> AuthenticatedClient:
        token = os.environ.get("APT_TOKEN") or self.profile.access_token
        if not token:
            raise AuthError("not logged in — run 'apt auth login'")
        return AuthenticatedClient(base_url=self.base_url, token=token)

    def public_client(self) -> Client:
        return Client(base_url=self.base_url)

    def _post(self, kwargs: dict[str, Any]) -> httpx.Response:
        return self.public_client().get_httpx_client().request(**kwargs)

    def _store_session(self, resp: httpx.Response, fallback: str, *, fallback_email: str) -> str:
        """Persist the `{token, refresh_token, user}` a finished /v1 login answers with."""
        if resp.status_code != 200:
            raise AuthError(_message(resp, fallback))
        data = resp.json()
        access = data.get("token")
        refresh = data.get("refresh_token")
        if not access or not refresh:
            raise AuthError("login succeeded but tokens were missing from the response")
        self.profile.access_token = access
        self.profile.refresh_token = refresh
        config_mod.save(self.config)
        return str((data.get("user") or {}).get("email") or fallback_email)


def _message(resp: httpx.Response, fallback: str) -> str:
    return errors.message_from_bytes(resp.content, fallback)
