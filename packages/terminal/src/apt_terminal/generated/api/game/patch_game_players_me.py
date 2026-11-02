from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.game_player import GamePlayer
from ...models.game_player_patch import GamePlayerPatch
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    body: GamePlayerPatch | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "patch",
        "url": "/game/players/me",
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | GamePlayer | None:
    if response.status_code == 200:
        response_200 = GamePlayer.from_dict(response.json())

        return response_200

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

    if response.status_code == 422:
        response_422 = Error.from_dict(response.json())

        return response_422

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | GamePlayer]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    body: GamePlayerPatch | Unset = UNSET,
) -> Response[Error | GamePlayer]:
    """Create or edit the caller’s own per-game profile

     Omitting a key leaves the stored value alone; sending `null` clears it — without that distinction a
    character name could be replaced but never removed. Only the keys actually sent are written, so an
    avatar-only edit cannot reset `visibility` to the `private` default or rewrite `first_played_at`. A
    character name is SCREENED whenever it is set, not only when the profile is public, because
    visibility can be flipped later with no text change — a refused name is 422 and echoes nothing about
    the verdict. 422 also when the game’s `character_names` setting is `off`.

    Args:
        body (GamePlayerPatch | Unset): Omit a key to leave it alone; send `null` to clear it.
            `character_name` is screened whenever it is set, whatever the profile’s visibility.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GamePlayer]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    body: GamePlayerPatch | Unset = UNSET,
) -> Error | GamePlayer | None:
    """Create or edit the caller’s own per-game profile

     Omitting a key leaves the stored value alone; sending `null` clears it — without that distinction a
    character name could be replaced but never removed. Only the keys actually sent are written, so an
    avatar-only edit cannot reset `visibility` to the `private` default or rewrite `first_played_at`. A
    character name is SCREENED whenever it is set, not only when the profile is public, because
    visibility can be flipped later with no text change — a refused name is 422 and echoes nothing about
    the verdict. 422 also when the game’s `character_names` setting is `off`.

    Args:
        body (GamePlayerPatch | Unset): Omit a key to leave it alone; send `null` to clear it.
            `character_name` is screened whenever it is set, whatever the profile’s visibility.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GamePlayer
    """

    return sync_detailed(
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    body: GamePlayerPatch | Unset = UNSET,
) -> Response[Error | GamePlayer]:
    """Create or edit the caller’s own per-game profile

     Omitting a key leaves the stored value alone; sending `null` clears it — without that distinction a
    character name could be replaced but never removed. Only the keys actually sent are written, so an
    avatar-only edit cannot reset `visibility` to the `private` default or rewrite `first_played_at`. A
    character name is SCREENED whenever it is set, not only when the profile is public, because
    visibility can be flipped later with no text change — a refused name is 422 and echoes nothing about
    the verdict. 422 also when the game’s `character_names` setting is `off`.

    Args:
        body (GamePlayerPatch | Unset): Omit a key to leave it alone; send `null` to clear it.
            `character_name` is screened whenever it is set, whatever the profile’s visibility.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GamePlayer]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    body: GamePlayerPatch | Unset = UNSET,
) -> Error | GamePlayer | None:
    """Create or edit the caller’s own per-game profile

     Omitting a key leaves the stored value alone; sending `null` clears it — without that distinction a
    character name could be replaced but never removed. Only the keys actually sent are written, so an
    avatar-only edit cannot reset `visibility` to the `private` default or rewrite `first_played_at`. A
    character name is SCREENED whenever it is set, not only when the profile is public, because
    visibility can be flipped later with no text change — a refused name is 422 and echoes nothing about
    the verdict. 422 also when the game’s `character_names` setting is `off`.

    Args:
        body (GamePlayerPatch | Unset): Omit a key to leave it alone; send `null` to clear it.
            `character_name` is screened whenever it is set, whatever the profile’s visibility.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GamePlayer
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
        )
    ).parsed
