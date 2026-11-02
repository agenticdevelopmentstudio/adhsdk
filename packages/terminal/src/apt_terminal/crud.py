from __future__ import annotations

import enum
import json
import sys
import types
import typing
from collections.abc import Callable
from typing import Annotated, Any

import attrs
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
    `field.type` is source text such as `"PostPersonaServicesBodyProviderKind"`. It is
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


def execute(
    op: Any,
    *,
    session: Session,
    path_args: tuple[Any, ...] = (),
    body: object | None = None,
    json_out: bool = False,
) -> None:
    """Call op via raw httpx, retry once on 401, then render or raise."""

    def call(client: Any) -> Any:
        # Build the request from the generated op's own kwargs (keeps routes +
        # body serialization in one place), but issue it with raw httpx and
        # render the server's raw JSON below. We deliberately do NOT use the
        # generated sync_detailed(): its strict attrs from_dict() raises on any
        # field drift between the spec and the live server (which we know
        # exists, e.g. auth token vs accessToken), and a display tool should
        # show whatever the server actually returned.
        kwargs = op._get_kwargs(*path_args, **({"body": body} if body is not None else {}))
        return client.get_httpx_client().request(**kwargs)

    client = session.client_factory()
    resp = call(client)

    if resp.status_code == 401 and session.refresh():
        client = session.client_factory()
        resp = call(client)

    if resp.status_code >= 400:
        raise errors.error_for_status(resp.status_code, errors.message_from_bytes(resp.content, f"HTTP {resp.status_code}"))

    try:
        data = resp.json()
    except ValueError:
        data = None
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
        execute(action.op, session=session_getter(), path_args=(id,), json_out=json_)
