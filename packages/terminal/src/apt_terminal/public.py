from __future__ import annotations

from collections.abc import Callable
from typing import Annotated, Any

import typer

from apt_terminal import crud
from apt_terminal.auth import Session
from apt_terminal.generated.api.persona import get_v1_personas
from apt_terminal.generated.api.public import get_v1_users
from apt_terminal.generated.types import UNSET
from apt_terminal.output import render

JsonOpt = Annotated[bool, typer.Option("--json", help="Raw JSON output")]


def _run(op: Any, params: dict[str, Any], session: Session, json_out: bool) -> None:
    # A public lookup names ONE object by a query input (/v1 has no `/public/...` paths: the
    # gateway picks the unauthenticated variant because no credentials are sent), so it is a
    # single request with no paging and no refresh.
    resp = crud.send(op, client_factory=session.public_client, refresh=lambda: False, params=params)
    try:
        payload = resp.json()
    except ValueError:
        payload = None
    render(payload, json_out)


def build_public_app(session_getter: Callable[[], Session]) -> typer.Typer:
    app = typer.Typer(name="public", help="Unauthenticated public lookups", no_args_is_help=True)

    @app.command("persona")
    def persona(slug: str, json_: JsonOpt = False) -> None:
        # GET /v1/personas is also the listing, whose generated op defaults `limit=10`;
        # UNSET keeps the paging parameter off a lookup that names one persona.
        _run(get_v1_personas, {"slug": slug, "limit": UNSET}, session_getter(), json_)

    @app.command("user")
    def user(slug: str, json_: JsonOpt = False) -> None:
        _run(get_v1_users, {"handle": slug}, session_getter(), json_)

    return app
