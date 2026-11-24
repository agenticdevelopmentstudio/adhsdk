from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.get_v1_game_sessions_by_id_response_200 import GetV1GameSessionsByIdResponse200
from ...models.stripe_error import StripeError
from ...types import UNSET, Response, Unset


def _get_kwargs(
    id: str,
    *,
    expand: list[str] | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    json_expand: list[str] | Unset = UNSET
    if not isinstance(expand, Unset):
        json_expand = expand

    params["expand[]"] = json_expand

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/v1/game/sessions/{id}".format(
            id=quote(str(id), safe=""),
        ),
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> GetV1GameSessionsByIdResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = GetV1GameSessionsByIdResponse200.from_dict(response.json())

        return response_200

    if response.status_code == 401:
        response_401 = StripeError.from_dict(response.json())

        return response_401

    if response.status_code == 404:
        response_404 = StripeError.from_dict(response.json())

        return response_404

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[GetV1GameSessionsByIdResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1GameSessionsByIdResponse200 | StripeError]:
    """One session the caller owns, with its subject artifact’s summary

     The `summary` is the SUBJECT ARTIFACT’s — `game.sessions` has no such column — and is read through
    the session’s own `subject_artifact_id`, never through anything the caller supplies, so this cannot
    become a way to read an arbitrary artifact’s summary. `null` when the session names no artifact. A
    session belonging to someone else is 404, not 403: a 403 would confirm the id names a real session.

    Replaces GET /game/sessions/{id}.

    Args:
        id (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1GameSessionsByIdResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
        expand=expand,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    *,
    client: AuthenticatedClient,
    expand: list[str] | Unset = UNSET,
) -> GetV1GameSessionsByIdResponse200 | StripeError | None:
    """One session the caller owns, with its subject artifact’s summary

     The `summary` is the SUBJECT ARTIFACT’s — `game.sessions` has no such column — and is read through
    the session’s own `subject_artifact_id`, never through anything the caller supplies, so this cannot
    become a way to read an arbitrary artifact’s summary. `null` when the session names no artifact. A
    session belonging to someone else is 404, not 403: a 403 would confirm the id names a real session.

    Replaces GET /game/sessions/{id}.

    Args:
        id (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1GameSessionsByIdResponse200 | StripeError
    """

    return sync_detailed(
        id=id,
        client=client,
        expand=expand,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1GameSessionsByIdResponse200 | StripeError]:
    """One session the caller owns, with its subject artifact’s summary

     The `summary` is the SUBJECT ARTIFACT’s — `game.sessions` has no such column — and is read through
    the session’s own `subject_artifact_id`, never through anything the caller supplies, so this cannot
    become a way to read an arbitrary artifact’s summary. `null` when the session names no artifact. A
    session belonging to someone else is 404, not 403: a 403 would confirm the id names a real session.

    Replaces GET /game/sessions/{id}.

    Args:
        id (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1GameSessionsByIdResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
        expand=expand,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    *,
    client: AuthenticatedClient,
    expand: list[str] | Unset = UNSET,
) -> GetV1GameSessionsByIdResponse200 | StripeError | None:
    """One session the caller owns, with its subject artifact’s summary

     The `summary` is the SUBJECT ARTIFACT’s — `game.sessions` has no such column — and is read through
    the session’s own `subject_artifact_id`, never through anything the caller supplies, so this cannot
    become a way to read an arbitrary artifact’s summary. `null` when the session names no artifact. A
    session belonging to someone else is 404, not 403: a 403 would confirm the id names a real session.

    Replaces GET /game/sessions/{id}.

    Args:
        id (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1GameSessionsByIdResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            expand=expand,
        )
    ).parsed
