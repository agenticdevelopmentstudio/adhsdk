from __future__ import annotations

from collections.abc import Callable
from typing import Annotated

import typer

from apt_terminal.auth import CODE_FACTORS, MfaRequired, Session
from apt_terminal.errors import AuthError
from apt_terminal.output import emit_json, emit_text


def pick_factor(methods: tuple[str, ...], wanted: str | None) -> str:
    """The second factor to complete with: the one asked for, else the first typeable one."""
    usable = [m for m in CODE_FACTORS if m in methods]
    if wanted is not None:
        if wanted not in usable:
            raise AuthError(
                f"--mfa-method {wanted} is not available; this account offers: "
                f"{', '.join(usable) or 'none a terminal can complete'}"
            )
        return wanted
    if not usable:
        raise AuthError(
            "this account's second factor is a passkey, which a terminal cannot complete; "
            f"enrolled: {', '.join(methods) or 'none'}"
        )
    return usable[0]


def build_auth_app(session_getter: Callable[[], Session]) -> typer.Typer:
    app = typer.Typer(name="auth", help="Authentication", no_args_is_help=True)

    @app.command("login")
    def login(
        identifier: Annotated[
            str,
            typer.Option(
                "--identifier", "--email", prompt="Email or username", help="Email, username or phone"
            ),
        ],
        password: Annotated[str, typer.Option(prompt=True, hide_input=True)],
        mfa_method: Annotated[
            str | None,
            typer.Option("--mfa-method", help=f"Second factor to use: {', '.join(CODE_FACTORS)}"),
        ] = None,
        code: Annotated[
            str | None, typer.Option("--code", help="Second-factor code (prompted if omitted)")
        ] = None,
    ) -> None:
        session = session_getter()
        try:
            who = session.login(identifier, password)
        except MfaRequired as pending:
            method = pick_factor(pending.methods, mfa_method)
            if method == "sms":
                session.send_sms_code(pending.token)
            typed = code if code is not None else typer.prompt(f"{method} code")
            who = session.complete_mfa(pending.token, method, typed)
        emit_text(f"Logged in as {who}")

    @app.command("logout")
    def logout() -> None:
        session_getter().logout()
        emit_text("Logged out.")

    @app.command("whoami")
    def whoami() -> None:
        emit_json(session_getter().whoami())

    @app.command("refresh")
    def refresh() -> None:
        ok = session_getter().refresh()
        emit_text("Refreshed." if ok else "Could not refresh — run 'apt auth login'.")

    return app
