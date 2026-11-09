from __future__ import annotations

import json

import httpx
import pytest
import respx
from typer.testing import CliRunner

from apt_terminal import config as c
from apt_terminal import crud
from apt_terminal import resources as r
from apt_terminal.auth import Session
from apt_terminal.errors import ApiError, AptError, AuthError, NotFoundError

BASE = "https://api.test"
SERVICES = f"{BASE}/v1/ai_services"
runner = CliRunner()


def _session(tmp_path) -> Session:
    cfg = c.Config(path=tmp_path / "config.toml")
    p = cfg.profile()
    p.base_url = BASE
    p.access_token = "acc"
    return Session(profile=p, config=cfg)


def _services() -> r.Resource:
    return next(res for res in r.PERSONA if res.name == "services")


def _list(rows: list[object], *, has_more: bool = False, url: str = "/v1/ai_services") -> dict:
    return {"object": "list", "data": rows, "has_more": has_more, "url": url}


def _error(message: str, type_: str = "invalid_request_error", **extra: str) -> dict:
    return {"error": {"type": type_, "message": message, **extra}}


def _service(id_: str) -> dict:
    return {"id": id_, "object": "ai_service", "name": "svc", "provider_kind": "openai",
            "base_url": "https://o.test", "created": 1700000000, "updated": 1700000000}


def test_parse_set_coerces_json():
    assert crud.parse_set(["name=foo", "n=5", "flag=true"]) == {
        "name": "foo", "n": 5, "flag": True,
    }


def _services_body():
    from apt_terminal.generated.models.post_v1_ai_services_body import PostV1AiServicesBody

    return PostV1AiServicesBody


def test_build_body_rejects_unknown_field():
    with pytest.raises(AptError):
        crud.build_body(_services_body(), ["bogus=1"])


def test_build_body_builds_model():
    body = crud.build_body(
        _services_body(),
        ["name=svc", "provider_kind=openai", "base_url=https://o.test"],
    )
    assert body.name == "svc"
    assert body.to_dict()["provider_kind"] == "openai"


@respx.mock
def test_list_unwraps_the_envelope_and_asks_for_full_pages(tmp_path):
    app = crud.build_resource_app(_services(), lambda: _session(tmp_path))
    route = respx.get(SERVICES).mock(return_value=httpx.Response(200, json=_list([_service("1")])))
    res = runner.invoke(app, ["list", "--json"])
    assert res.exit_code == 0, res.output
    assert json.loads(res.output) == [_service("1")]
    assert route.calls.last.request.url.params["limit"] == str(crud.PAGE_SIZE)


@respx.mock
def test_list_follows_has_more_with_starting_after(tmp_path):
    sess = _session(tmp_path)
    first = respx.get(SERVICES, params={"starting_after": "2"}).mock(
        return_value=httpx.Response(200, json=_list([_service("3")]))
    )
    respx.get(SERVICES).mock(
        return_value=httpx.Response(200, json=_list([_service("1"), _service("2")], has_more=True))
    )
    rows = crud.fetch(_services().ops.list_, client_factory=sess.client_factory,
                      refresh=sess.refresh)
    assert [row["id"] for row in rows] == ["1", "2", "3"]
    assert first.called


@respx.mock
def test_list_table_shows_created_as_utc(tmp_path):
    app = crud.build_resource_app(_services(), lambda: _session(tmp_path))
    respx.get(SERVICES).mock(return_value=httpx.Response(200, json=_list([_service("1")])))
    res = runner.invoke(app, ["list"])
    assert res.exit_code == 0, res.output
    assert "2023-11-14" in res.output


@respx.mock
def test_get_returns_the_bare_object(tmp_path):
    app = crud.build_resource_app(_services(), lambda: _session(tmp_path))
    respx.get(f"{SERVICES}/s1").mock(return_value=httpx.Response(200, json=_service("s1")))
    res = runner.invoke(app, ["get", "s1", "--json"])
    assert res.exit_code == 0, res.output
    assert json.loads(res.output)["object"] == "ai_service"


@respx.mock
def test_create_posts_snake_case_body(tmp_path):
    app = crud.build_resource_app(_services(), lambda: _session(tmp_path))
    route = respx.post(SERVICES).mock(return_value=httpx.Response(200, json=_service("9")))
    res = runner.invoke(app, [
        "create", "--set", "name=svc", "--set", "provider_kind=openai",
        "--set", "base_url=https://o.test", "--json",
    ])
    assert res.exit_code == 0, res.output
    sent = json.loads(route.calls.last.request.content)
    assert sent == {"name": "svc", "provider_kind": "openai", "base_url": "https://o.test"}


@respx.mock
def test_update_posts_to_the_object(tmp_path):
    app = crud.build_resource_app(_services(), lambda: _session(tmp_path))
    route = respx.post(f"{SERVICES}/s1").mock(return_value=httpx.Response(200, json=_service("s1")))
    res = runner.invoke(app, ["update", "s1", "--set", "name=renamed", "--json"])
    assert res.exit_code == 0, res.output
    assert json.loads(route.calls.last.request.content) == {"name": "renamed"}


@respx.mock
def test_delete_renders_the_tombstone(tmp_path):
    app = crud.build_resource_app(_services(), lambda: _session(tmp_path))
    respx.delete(f"{SERVICES}/s1").mock(return_value=httpx.Response(
        200, json={"id": "s1", "object": "ai_service", "deleted": True}
    ))
    res = runner.invoke(app, ["delete", "s1", "--json"])
    assert res.exit_code == 0, res.output
    assert json.loads(res.output)["deleted"] is True


@respx.mock
def test_401_triggers_refresh_then_retry(tmp_path):
    sess = _session(tmp_path)
    sess.profile.refresh_token = "ref"
    app = crud.build_resource_app(_services(), lambda: sess)
    respx.get(SERVICES).mock(side_effect=[
        httpx.Response(401, json=_error("expired", "authentication_error")),
        httpx.Response(200, json=_list([])),
    ])
    respx.post(f"{BASE}/v1/auth/sessions/refresh").mock(
        return_value=httpx.Response(200, json={"token": "acc2", "refresh_token": "ref2"})
    )
    res = runner.invoke(app, ["list", "--json"])
    assert res.exit_code == 0, res.output
    assert sess.profile.access_token == "acc2"


@respx.mock
def test_models_action_passes_the_service_as_a_query_param(tmp_path):
    app = crud.build_resource_app(_services(), lambda: _session(tmp_path))
    route = respx.get(f"{BASE}/v1/models", params={"service": "svc1"}).mock(
        return_value=httpx.Response(200, json=_list(["gpt-4o", "gpt-4o-mini"], url="/v1/models"))
    )
    res = runner.invoke(app, ["models", "svc1"])
    assert res.exit_code == 0, res.output
    assert route.called
    assert "gpt-4o" in res.output


@respx.mock
def test_connect_action_posts_to_the_nested_route(tmp_path):
    app = crud.build_resource_app(_services(), lambda: _session(tmp_path))
    route = respx.post(f"{SERVICES}/svc1/connect").mock(
        return_value=httpx.Response(200, json={"ok": True})
    )
    res = runner.invoke(app, ["connect", "svc1", "--json"])
    assert res.exit_code == 0, res.output
    assert route.called


@respx.mock
def test_error_status_exits_nonzero(tmp_path):
    app = crud.build_resource_app(_services(), lambda: _session(tmp_path))
    respx.get(SERVICES).mock(return_value=httpx.Response(400, json=_error("bad")))
    res = runner.invoke(app, ["list"])
    assert res.exit_code != 0


@respx.mock
def test_stripe_error_message_names_the_param(tmp_path):
    sess = _session(tmp_path)
    respx.post(SERVICES).mock(
        return_value=httpx.Response(400, json=_error("is required", param="base_url"))
    )
    body = crud.build_body(_services_body(), ["name=s", "provider_kind=openai", "base_url=x"])
    with pytest.raises(ApiError) as exc:
        crud.execute(_services().ops.create, session=sess, body=body)
    assert str(exc.value) == "400: is required (param: base_url)"


@respx.mock
def test_404_raises_not_found_exit_code(tmp_path):
    """A 404 response raises NotFoundError (exit_code=4), confirmed via raised exception."""
    sess = _session(tmp_path)
    respx.get(SERVICES).mock(
        return_value=httpx.Response(404, json=_error("not found", code="resource_missing"))
    )
    with pytest.raises(NotFoundError) as exc_info:
        crud.execute(_services().ops.list_, session=sess)
    assert exc_info.value.exit_code == 4


@respx.mock
def test_401_no_refresh_raises_auth_error(tmp_path):
    """A 401 with no refresh token raises AuthError (exit_code=3)."""
    sess = _session(tmp_path)
    # no refresh_token set, so refresh() returns False
    respx.get(SERVICES).mock(
        return_value=httpx.Response(401, json=_error("unauthorized", "authentication_error"))
    )
    with pytest.raises(AuthError) as exc_info:
        crud.execute(_services().ops.list_, session=sess)
    assert exc_info.value.exit_code == 3


@respx.mock
def test_empty_list_renders_none(tmp_path):
    app = crud.build_resource_app(_services(), lambda: _session(tmp_path))
    respx.get(SERVICES).mock(return_value=httpx.Response(200, json=_list([])))
    res = runner.invoke(app, ["list"])
    assert res.exit_code == 0, res.output
    assert "(none)" in res.output


@respx.mock
def test_tokens_use_v1_api_keys(tmp_path):
    tokens = r.AUTH_TOKENS[0]
    app = crud.build_resource_app(tokens, lambda: _session(tmp_path))
    route = respx.post(f"{BASE}/v1/api_keys").mock(
        return_value=httpx.Response(200, json={"id": "k1", "object": "api_key", "token": "t"})
    )
    res = runner.invoke(app, ["create", "--set", "name=ci", "--json"])
    assert res.exit_code == 0, res.output
    assert json.loads(route.calls.last.request.content) == {"name": "ci"}


# --- enum coercion -------------------------------------------------------------------
#
# The generated body models are plain attrs classes with no converters, so before
# `coerce_enums` a `--set provider_kind=openai` stored the STRING and the command died later
# inside generated `to_dict()` with `AttributeError: 'str' object has no attribute 'value'`.
# These pin the coercion and, just as importantly, the error the user gets when the value is
# not a member — the old path could only crash.


def test_build_body_coerces_a_string_into_the_declared_enum():
    body = crud.build_body(_services_body(), [
        "name=svc", "provider_kind=openai", "base_url=https://o.test",
    ])
    from apt_terminal.generated.models.post_v1_ai_services_body_provider_kind import (
        PostV1AiServicesBodyProviderKind,
    )

    assert body.provider_kind is PostV1AiServicesBodyProviderKind.OPENAI


def test_a_coerced_body_serializes_instead_of_raising():
    # The regression itself: the failure was never at construction, it was here.
    body = crud.build_body(_services_body(), [
        "name=svc", "provider_kind=openai", "base_url=https://o.test",
    ])
    assert body.to_dict()["provider_kind"] == "openai"


def test_build_body_names_the_field_and_the_choices_for_a_bad_enum_value():
    with pytest.raises(AptError) as exc:
        crud.build_body(_services_body(), [
            "name=svc", "provider_kind=nope", "base_url=https://o.test",
        ])
    msg = str(exc.value)
    assert "provider_kind" in msg
    assert "openai" in msg


def test_build_body_leaves_a_non_enum_field_alone():
    body = crud.build_body(_services_body(), [
        "name=svc", "provider_kind=openai", "base_url=https://o.test",
    ])
    assert body.name == "svc"


def test_enum_type_looks_through_a_union_but_not_an_ambiguous_one():
    import enum

    class A(enum.Enum):
        X = "x"

    class B(enum.Enum):
        Y = "y"

    assert crud.enum_type(A) is A
    # An optional enum is still an enum as far as a --set value is concerned.
    assert crud.enum_type(A | None) is A
    assert crud.enum_type(str) is None
    # Two enums in one union would make the coercion a guess, so it declines.
    assert crud.enum_type(A | B) is None
