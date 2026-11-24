from __future__ import annotations

import enum
import inspect
import json
import sys
import types
import typing
from collections.abc import Callable
from typing import Annotated, Any

import attrs
import httpx
import typer

from apt_terminal import errors
from apt_terminal.auth import Session
from apt_terminal.errors import AptError
from apt_terminal.output import render
from apt_terminal.resources import Action, Resource

SetOpt = Annotated[list[str] | None, typer.Option("--set", help="FIELD=VALUE (repeatable)")]
JsonOpt = Annotated[bool, typer.Option("--json", help="Raw JSON output")]


def parse_set(pairs: list[str]) -> dict[str, object]:
    out: dict[str, object] = {}
    for pair in pairs:
        if "=" not in pair:
            raise AptError(f"--set expects FIELD=VALUE, got {pair!r}")
        key, _, raw = pair.partition("=")
        try:
            out[key.strip()] = json.loads(raw)
        except json.JSONDecodeError:
            out[key.strip()] = raw
    return out


def enum_type(annotation: object) -> type[enum.Enum] | None:
    """The Enum a field accepts, or None if it does not accept one.

    Looks through a union, because an optional enum arrives as `Unset | TheEnum` and is
    still an enum as far as a `--set` value is concerned. A union naming more than one enum
    would make the coercion ambiguous, so it is left alone rather than guessed at.
    """
    if isinstance(annotation, type) and issubclass(annotation, enum.Enum):
        return annotation
    if isinstance(annotation, types.UnionType) or typing.get_origin(annotation) is typing.Union:
        found = [
            arg
            for arg in typing.get_args(annotation)
            if isinstance(arg, type) and issubclass(arg, enum.Enum)
        ]
        if len(found) == 1:
            return found[0]
    return None


def field_type(model: type, field: attrs.Attribute[Any]) -> object:
    """A field's annotation as a type, not as the string `from __future__ import annotations` leaves.

    Since openapi-python-client 0.29 the generated models postpone their annotations, so
    `field.type` is source text such as `"PostV1AiServicesBodyProviderKind"`. It is
    evaluated in the model's own module, where the generator imported every enum it names.
    A name that module imports only under TYPE_CHECKING (nested models, never enums)
    cannot resolve and comes back as None, which `enum_type` already treats as "not an enum".
    """
    if not isinstance(field.type, str):
        return field.type
    try:
        return eval(field.type, vars(sys.modules[model.__module__]))  # generator-written text
    except NameError:
        return None


def coerce_enums(model: type, kwargs: dict[str, object]) -> dict[str, object]:
    """Turn `--set` strings into the Enum members the generated models declare.

    The generated body models are plain attrs classes with no converters, so a str lands in
    an enum-typed field unchallenged and only detonates later, inside `to_dict()`, as
    `AttributeError: 'str' object has no attribute 'value'` — pointing at generated code,
    naming neither the field the user typed nor the values it would have accepted.

    Coercing here makes the failure fail-fast and legible: it happens while we still know
    which `--set` produced it, and the message can list the actual choices. Members are
    matched BY VALUE (what the API speaks and what the user reads in the docs), falling back
    to the member NAME so that a value the generator had to mangle into an identifier is
    still typeable.
    """
    out = dict(kwargs)
    for field in attrs.fields(model):
        want = enum_type(field_type(model, field))
        if want is None or field.name not in out:
            continue
        given = out[field.name]
        if isinstance(given, want):
            continue
        try:
            out[field.name] = want(given)
            continue
        except ValueError:
            pass
        by_name = getattr(want, given, None) if isinstance(given, str) else None
        if isinstance(by_name, want):
            out[field.name] = by_name
            continue
        choices = ", ".join(str(member.value) for member in want)
        raise AptError(f"invalid value for {field.name}: {given!r}. allowed: {choices}")
    return out


def build_body(model: type, pairs: list[str]) -> object:
    try:
        known = {f.name for f in attrs.fields(model)}
    except Exception as exc:  # not an attrs class, etc.
        raise AptError(f"{model.__name__} is not a valid request body: {exc}") from exc
    kwargs = parse_set(pairs)
    unknown = set(kwargs) - known
    if unknown:
        allowed = ", ".join(sorted(known - {"additional_properties"}))
        raise AptError(f"unknown field(s): {', '.join(sorted(unknown))}. allowed: {allowed}")
    kwargs = coerce_enums(model, kwargs)
    try:
        return model(**kwargs)
    except TypeError as exc:
        raise AptError(
            f"invalid fields for {model.__name__}: {exc}. "
            f"Note: --set values are JSON-parsed (true/false/null/numbers become typed); "
            f"quote a literal, e.g. --set name='\"true\"'."
        ) from exc


# The /v1 maximum page size. A list command shows everything, so it reads in the biggest
# pages the server allows and follows `has_more` rather than stopping at the default (10).
PAGE_SIZE = 100


def send(
    op: Any,
    *,
    client_factory: Callable[[], Any],
    refresh: Callable[[], bool],
    path_args: tuple[Any, ...] = (),
    params: dict[str, Any] | None = None,
    body: object | None = None,
) -> httpx.Response:
    """Issue one generated op over raw httpx, retry once on 401 after `refresh`, raise on >=400.

    The request comes from the generated op's own `_get_kwargs` (routes, query names and
    body serialization stay in one place), but it is sent with raw httpx and the server's
    raw JSON is what the caller gets. We deliberately do NOT use the generated
    sync_detailed(): its strict attrs from_dict() raises on any drift between the spec and
    the live server, and a display tool should show whatever the server actually returned.
    """
    kwargs = op._get_kwargs(
        *path_args, **(params or {}), **({"body": body} if body is not None else {})
    )
    resp: httpx.Response = client_factory().get_httpx_client().request(**kwargs)
    if resp.status_code == 401 and refresh():
        resp = client_factory().get_httpx_client().request(**kwargs)
    if resp.status_code >= 400:
        raise errors.error_for_status(
            resp.status_code, errors.message_from_bytes(resp.content, f"HTTP {resp.status_code}")
        )
    return resp


def is_list_envelope(data: object) -> bool:
    """A /v1 collection: `{"object": "list", "data": [...], "has_more": bool, "url": str}`."""
    return (
        isinstance(data, dict) and data.get("object") == "list" and isinstance(data.get("data"), list)
    )


def pages(op: Any) -> bool:
    """Whether the generated op takes the /v1 cursor parameters."""
    names = inspect.signature(op._get_kwargs).parameters
    return "limit" in names and "starting_after" in names


def fetch(
    op: Any,
    *,
    client_factory: Callable[[], Any],
    refresh: Callable[[], bool],
    path_args: tuple[Any, ...] = (),
    params: dict[str, Any] | None = None,
    body: object | None = None,
) -> Any:
    """The op's JSON result; a list envelope comes back as the rows of EVERY page.

    A paged op is read `PAGE_SIZE` at a time, passing the last row's id as
    `starting_after` while the server says `has_more`. Rows without an id (a bare list of
    strings) cannot be cursored past, so that is where reading stops.
    """
    paged = pages(op)
    query = {**(params or {}), **({"limit": PAGE_SIZE} if paged else {})}

    def one(extra: dict[str, Any]) -> Any:
        resp = send(
            op,
            client_factory=client_factory,
            refresh=refresh,
            path_args=path_args,
            params={**query, **extra},
            body=body,
        )
        try:
            return resp.json()
        except ValueError:
            return None

    data = one({})
    if not is_list_envelope(data):
        return data
    rows: list[Any] = list(data["data"])
    while paged and data.get("has_more") and rows:
        last = rows[-1]
        cursor = last.get("id") if isinstance(last, dict) else None
        if not cursor:
            break
        data = one({"starting_after": cursor})
        if not is_list_envelope(data) or not data["data"]:
            break
        rows.extend(data["data"])
    return rows


def execute(
    op: Any,
    *,
    session: Session,
    path_args: tuple[Any, ...] = (),
    params: dict[str, Any] | None = None,
    body: object | None = None,
    json_out: bool = False,
) -> None:
    """Call op as the logged-in user, then render the result or raise."""
    data = fetch(
        op,
        client_factory=session.client_factory,
        refresh=session.refresh,
        path_args=path_args,
        params=params,
        body=body,
    )
    render(data, json_out)


def build_resource_app(res: Resource, session_getter: Callable[[], Session]) -> typer.Typer:
    app = typer.Typer(name=res.name, help=f"{res.domain} {res.name}", no_args_is_help=True)
    ops = res.ops

    if ops.list_ is not None:
        @app.command("list")
        def list_(json_: JsonOpt = False) -> None:
            execute(ops.list_, session=session_getter(), json_out=json_)
        app.command("ls", hidden=True)(list_)

    if ops.get is not None:
        @app.command("get")
        def get(id: str, json_: JsonOpt = False) -> None:
            execute(ops.get, session=session_getter(), path_args=(id,), json_out=json_)

    if ops.create is not None and res.create_body is not None:
        _create_body: type = res.create_body

        @app.command("create")
        def create(set_: SetOpt = None, json_: JsonOpt = False) -> None:
            body = build_body(_create_body, set_ or [])
            execute(ops.create, session=session_getter(), body=body, json_out=json_)

    if ops.update is not None and res.update_body is not None:
        _update_body: type = res.update_body

        @app.command("update")
        def update(id: str, set_: SetOpt = None, json_: JsonOpt = False) -> None:
            body = build_body(_update_body, set_ or [])
            execute(ops.update, session=session_getter(), path_args=(id,), body=body, json_out=json_)

    if ops.delete is not None:
        @app.command("delete")
        def delete(id: str, json_: JsonOpt = False) -> None:
            execute(ops.delete, session=session_getter(), path_args=(id,), json_out=json_)
        app.command("rm", hidden=True)(delete)

    for action in res.actions:
        _register_action(app, action, session_getter)

    return app


def _register_action(app: typer.Typer, action: Action, session_getter: Callable[[], Session]) -> None:
    @app.command(action.name, help=action.help)
    def _action(id: str, json_: JsonOpt = False) -> None:
        if action.id_param is None:
            execute(action.op, session=session_getter(), path_args=(id,), json_out=json_)
        else:
            execute(action.op, session=session_getter(), params={action.id_param: id}, json_out=json_)
