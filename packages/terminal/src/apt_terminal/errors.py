from __future__ import annotations

import json as _json


class AptError(Exception):
    exit_code = 1


class ConfigError(AptError):
    exit_code = 2


class AuthError(AptError):
    exit_code = 3


class NotFoundError(AptError):
    exit_code = 4


class ApiError(AptError):
    """Non-2xx response from a service."""

    exit_code = 5

    def __init__(self, status: int, message: str, body: object = None) -> None:
        super().__init__(f"{status}: {message}")
        self.status = status
        self.body = body


def _message_from_body(body: object, fallback: str) -> str:
    """The message of a /v1 error envelope: `{"error": {type, code, message, param}}`.

    `param` names the request field the server refused, so it is appended when present —
    it is what tells a `--set` user which of their values to fix.
    """
    if isinstance(body, dict):
        err = body.get("error")
        if isinstance(err, dict) and err.get("message") not in (None, ""):
            message = str(err["message"])
            param = err.get("param")
            return f"{message} (param: {param})" if param not in (None, "") else message
    return fallback


def message_from_bytes(content: bytes, fallback: str) -> str:
    try:
        body = _json.loads(content.decode() or "{}")
    except (ValueError, AttributeError):
        return fallback
    return _message_from_body(body, fallback)


def error_for_status(status: int, message: str) -> AptError:
    if status in (401, 403):
        return AuthError(message)
    if status == 404:
        return NotFoundError(message)
    return ApiError(status, message)
