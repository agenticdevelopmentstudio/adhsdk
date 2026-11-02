from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.get_game_sessions_id_events_response_200 import GetGameSessionsIdEventsResponse200
from ...types import UNSET, Response, Unset


def _get_kwargs(
    id: str,
    *,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["page"] = page

    params["page_size"] = page_size

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/game/sessions/{id}/events".format(
            id=quote(str(id), safe=""),
        ),
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | GetGameSessionsIdEventsResponse200 | None:
    if response.status_code == 200:
        response_200 = GetGameSessionsIdEventsResponse200.from_dict(response.json())

        return response_200

    if response.status_code == 401:
        response_401 = Error.from_dict(response.json())

        return response_401

    if response.status_code == 404:
        response_404 = Error.from_dict(response.json())

        return response_404

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | GetGameSessionsIdEventsResponse200]:
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
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
) -> Response[Error | GetGameSessionsIdEventsResponse200]:
    """The session’s own event log, oldest first

     `game.events` is in `SKIP_TABLES`, so generic CRUD serves no read of it — a client that posted an
    event and then reconnected would otherwise have no way to discover what it missed. The session is
    resolved through the same owner predicate FIRST, so this query never sees a session id the caller
    does not own.

    Args:
        id (str):
        page (str | Unset):
        page_size (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GetGameSessionsIdEventsResponse200]
    """

    kwargs = _get_kwargs(
        id=id,
        page=page,
        page_size=page_size,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    *,
    client: AuthenticatedClient,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
) -> Error | GetGameSessionsIdEventsResponse200 | None:
    """The session’s own event log, oldest first

     `game.events` is in `SKIP_TABLES`, so generic CRUD serves no read of it — a client that posted an
    event and then reconnected would otherwise have no way to discover what it missed. The session is
    resolved through the same owner predicate FIRST, so this query never sees a session id the caller
    does not own.

    Args:
        id (str):
        page (str | Unset):
        page_size (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GetGameSessionsIdEventsResponse200
    """

    return sync_detailed(
        id=id,
        client=client,
        page=page,
        page_size=page_size,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
) -> Response[Error | GetGameSessionsIdEventsResponse200]:
    """The session’s own event log, oldest first

     `game.events` is in `SKIP_TABLES`, so generic CRUD serves no read of it — a client that posted an
    event and then reconnected would otherwise have no way to discover what it missed. The session is
    resolved through the same owner predicate FIRST, so this query never sees a session id the caller
    does not own.

    Args:
        id (str):
        page (str | Unset):
        page_size (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GetGameSessionsIdEventsResponse200]
    """

    kwargs = _get_kwargs(
        id=id,
        page=page,
        page_size=page_size,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    *,
    client: AuthenticatedClient,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
) -> Error | GetGameSessionsIdEventsResponse200 | None:
    """The session’s own event log, oldest first

     `game.events` is in `SKIP_TABLES`, so generic CRUD serves no read of it — a client that posted an
    event and then reconnected would otherwise have no way to discover what it missed. The session is
    resolved through the same owner predicate FIRST, so this query never sees a session id the caller
    does not own.

    Args:
        id (str):
        page (str | Unset):
        page_size (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GetGameSessionsIdEventsResponse200
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            page=page,
            page_size=page_size,
        )
    ).parsed
