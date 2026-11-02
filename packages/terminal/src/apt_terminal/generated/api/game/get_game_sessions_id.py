from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.game_session_detail import GameSessionDetail
from ...types import Response


def _get_kwargs(
    id: str,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/game/sessions/{id}".format(
            id=quote(str(id), safe=""),
        ),
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | GameSessionDetail | None:
    if response.status_code == 200:
        response_200 = GameSessionDetail.from_dict(response.json())

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
) -> Response[Error | GameSessionDetail]:
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
) -> Response[Error | GameSessionDetail]:
    """One session the caller owns, with its subject artifact’s summary

     The `summary` is the SUBJECT ARTIFACT’s — `game.sessions` has no such column — and is read through
    the session’s own `subject_artifact_id`, never through anything the caller supplies, so this cannot
    become a way to read an arbitrary artifact’s summary. `null` when the session names no artifact. A
    session belonging to someone else is 404, not 403: a 403 would confirm the id names a real session.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GameSessionDetail]
    """

    kwargs = _get_kwargs(
        id=id,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    *,
    client: AuthenticatedClient,
) -> Error | GameSessionDetail | None:
    """One session the caller owns, with its subject artifact’s summary

     The `summary` is the SUBJECT ARTIFACT’s — `game.sessions` has no such column — and is read through
    the session’s own `subject_artifact_id`, never through anything the caller supplies, so this cannot
    become a way to read an arbitrary artifact’s summary. `null` when the session names no artifact. A
    session belonging to someone else is 404, not 403: a 403 would confirm the id names a real session.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GameSessionDetail
    """

    return sync_detailed(
        id=id,
        client=client,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
) -> Response[Error | GameSessionDetail]:
    """One session the caller owns, with its subject artifact’s summary

     The `summary` is the SUBJECT ARTIFACT’s — `game.sessions` has no such column — and is read through
    the session’s own `subject_artifact_id`, never through anything the caller supplies, so this cannot
    become a way to read an arbitrary artifact’s summary. `null` when the session names no artifact. A
    session belonging to someone else is 404, not 403: a 403 would confirm the id names a real session.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GameSessionDetail]
    """

    kwargs = _get_kwargs(
        id=id,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    *,
    client: AuthenticatedClient,
) -> Error | GameSessionDetail | None:
    """One session the caller owns, with its subject artifact’s summary

     The `summary` is the SUBJECT ARTIFACT’s — `game.sessions` has no such column — and is read through
    the session’s own `subject_artifact_id`, never through anything the caller supplies, so this cannot
    become a way to read an arbitrary artifact’s summary. `null` when the session names no artifact. A
    session belonging to someone else is 404, not 403: a 403 would confirm the id names a real session.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GameSessionDetail
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
        )
    ).parsed
