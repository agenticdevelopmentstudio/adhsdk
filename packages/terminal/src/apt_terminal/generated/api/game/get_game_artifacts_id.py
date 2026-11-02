from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.game_artifact import GameArtifact
from ...types import Response


def _get_kwargs(
    id: str,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/game/artifacts/{id}".format(
            id=quote(str(id), safe=""),
        ),
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | GameArtifact | None:
    if response.status_code == 200:
        response_200 = GameArtifact.from_dict(response.json())

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
) -> Response[Error | GameArtifact]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    id: str,
    *,
    client: AuthenticatedClient | Client,
) -> Response[Error | GameArtifact]:
    """One artifact — anonymous when it is public, plus the caller’s own when signed in

     No `security` because an anonymous caller is a supported caller: without a bearer token this serves
    any PUBLIC, non-withdrawn artifact by id, in any ecosystem (the id is the scope on a by-id read).
    WITH a bearer token it additionally serves the caller’s own private artifacts. A token that is
    present but invalid is 401, not a silent downgrade to the anonymous path — otherwise a caller could
    not tell a revoked session from a working one. The `body` bytea is never serialised here.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GameArtifact]
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
    client: AuthenticatedClient | Client,
) -> Error | GameArtifact | None:
    """One artifact — anonymous when it is public, plus the caller’s own when signed in

     No `security` because an anonymous caller is a supported caller: without a bearer token this serves
    any PUBLIC, non-withdrawn artifact by id, in any ecosystem (the id is the scope on a by-id read).
    WITH a bearer token it additionally serves the caller’s own private artifacts. A token that is
    present but invalid is 401, not a silent downgrade to the anonymous path — otherwise a caller could
    not tell a revoked session from a working one. The `body` bytea is never serialised here.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GameArtifact
    """

    return sync_detailed(
        id=id,
        client=client,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient | Client,
) -> Response[Error | GameArtifact]:
    """One artifact — anonymous when it is public, plus the caller’s own when signed in

     No `security` because an anonymous caller is a supported caller: without a bearer token this serves
    any PUBLIC, non-withdrawn artifact by id, in any ecosystem (the id is the scope on a by-id read).
    WITH a bearer token it additionally serves the caller’s own private artifacts. A token that is
    present but invalid is 401, not a silent downgrade to the anonymous path — otherwise a caller could
    not tell a revoked session from a working one. The `body` bytea is never serialised here.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GameArtifact]
    """

    kwargs = _get_kwargs(
        id=id,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    *,
    client: AuthenticatedClient | Client,
) -> Error | GameArtifact | None:
    """One artifact — anonymous when it is public, plus the caller’s own when signed in

     No `security` because an anonymous caller is a supported caller: without a bearer token this serves
    any PUBLIC, non-withdrawn artifact by id, in any ecosystem (the id is the scope on a by-id read).
    WITH a bearer token it additionally serves the caller’s own private artifacts. A token that is
    present but invalid is 401, not a silent downgrade to the anonymous path — otherwise a caller could
    not tell a revoked session from a working one. The `body` bytea is never serialised here.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GameArtifact
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
        )
    ).parsed
