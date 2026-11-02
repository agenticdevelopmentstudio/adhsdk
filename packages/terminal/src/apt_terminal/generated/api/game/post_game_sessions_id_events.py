from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.game_event import GameEvent
from ...models.game_event_post import GameEventPost
from ...types import UNSET, Response, Unset


def _get_kwargs(
    id: str,
    *,
    body: GameEventPost | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/game/sessions/{id}/events".format(
            id=quote(str(id), safe=""),
        ),
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | GameEvent | None:
    if response.status_code == 200:
        response_200 = GameEvent.from_dict(response.json())

        return response_200

    if response.status_code == 201:
        response_201 = GameEvent.from_dict(response.json())

        return response_201

    if response.status_code == 400:
        response_400 = Error.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = Error.from_dict(response.json())

        return response_401

    if response.status_code == 404:
        response_404 = Error.from_dict(response.json())

        return response_404

    if response.status_code == 409:
        response_409 = Error.from_dict(response.json())

        return response_409

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | GameEvent]:
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
    body: GameEventPost | Unset = UNSET,
) -> Response[Error | GameEvent]:
    """Record one turn (idempotent on `client_event_id`)

     **This endpoint runs no engine.** The caller runs its own turn and posts the result; adh appends it
    and assigns the next `seq`. A repeat of the same `client_event_id` returns the STORED row with 200
    and executes nothing — which is what makes a dropped SSE connection safe to retry. 409 when the
    session has ended: the caller still owns it and can still read it, but it cannot advance. Naming an
    `artifact_id` counts one exposure against that artifact, and only on a genuine insert — never on a
    replay, or the retry would double-count.

    Args:
        id (str):
        body (GameEventPost | Unset): `client_event_id` is the caller’s idempotency key: reposting
            the same one returns the stored event and executes nothing.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GameEvent]
    """

    kwargs = _get_kwargs(
        id=id,
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    *,
    client: AuthenticatedClient,
    body: GameEventPost | Unset = UNSET,
) -> Error | GameEvent | None:
    """Record one turn (idempotent on `client_event_id`)

     **This endpoint runs no engine.** The caller runs its own turn and posts the result; adh appends it
    and assigns the next `seq`. A repeat of the same `client_event_id` returns the STORED row with 200
    and executes nothing — which is what makes a dropped SSE connection safe to retry. 409 when the
    session has ended: the caller still owns it and can still read it, but it cannot advance. Naming an
    `artifact_id` counts one exposure against that artifact, and only on a genuine insert — never on a
    replay, or the retry would double-count.

    Args:
        id (str):
        body (GameEventPost | Unset): `client_event_id` is the caller’s idempotency key: reposting
            the same one returns the stored event and executes nothing.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GameEvent
    """

    return sync_detailed(
        id=id,
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
    body: GameEventPost | Unset = UNSET,
) -> Response[Error | GameEvent]:
    """Record one turn (idempotent on `client_event_id`)

     **This endpoint runs no engine.** The caller runs its own turn and posts the result; adh appends it
    and assigns the next `seq`. A repeat of the same `client_event_id` returns the STORED row with 200
    and executes nothing — which is what makes a dropped SSE connection safe to retry. 409 when the
    session has ended: the caller still owns it and can still read it, but it cannot advance. Naming an
    `artifact_id` counts one exposure against that artifact, and only on a genuine insert — never on a
    replay, or the retry would double-count.

    Args:
        id (str):
        body (GameEventPost | Unset): `client_event_id` is the caller’s idempotency key: reposting
            the same one returns the stored event and executes nothing.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GameEvent]
    """

    kwargs = _get_kwargs(
        id=id,
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    *,
    client: AuthenticatedClient,
    body: GameEventPost | Unset = UNSET,
) -> Error | GameEvent | None:
    """Record one turn (idempotent on `client_event_id`)

     **This endpoint runs no engine.** The caller runs its own turn and posts the result; adh appends it
    and assigns the next `seq`. A repeat of the same `client_event_id` returns the STORED row with 200
    and executes nothing — which is what makes a dropped SSE connection safe to retry. 409 when the
    session has ended: the caller still owns it and can still read it, but it cannot advance. Naming an
    `artifact_id` counts one exposure against that artifact, and only on a genuine insert — never on a
    replay, or the retry would double-count.

    Args:
        id (str):
        body (GameEventPost | Unset): `client_event_id` is the caller’s idempotency key: reposting
            the same one returns the stored event and executes nothing.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GameEvent
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            body=body,
        )
    ).parsed
