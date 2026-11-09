from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.game_player_patch import GamePlayerPatch
from ...models.post_v1_game_players_me_response_200 import PostV1GamePlayersMeResponse200
from ...models.stripe_error import StripeError
from ...types import Response


def _get_kwargs(
    *,
    body: GamePlayerPatch,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/game/players/me",
    }

    _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostV1GamePlayersMeResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = PostV1GamePlayersMeResponse200.from_dict(response.json())

        return response_200

    if response.status_code == 400:
        response_400 = StripeError.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = StripeError.from_dict(response.json())

        return response_401

    if response.status_code == 404:
        response_404 = StripeError.from_dict(response.json())

        return response_404

    if response.status_code == 409:
        response_409 = StripeError.from_dict(response.json())

        return response_409

    if response.status_code == 422:
        response_422 = StripeError.from_dict(response.json())

        return response_422

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[PostV1GamePlayersMeResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    body: GamePlayerPatch,
) -> Response[PostV1GamePlayersMeResponse200 | StripeError]:
    """Create or edit the caller’s own per-game profile

     Omitting a key leaves the stored value alone; sending `null` clears it — without that distinction a
    character name could be replaced but never removed. Only the keys actually sent are written, so an
    avatar-only edit cannot reset `visibility` to the `private` default or rewrite `first_played_at`. A
    character name is SCREENED whenever it is set, not only when the profile is public, because
    visibility can be flipped later with no text change — a refused name is 422 and echoes nothing about
    the verdict. 422 also when the game’s `character_names` setting is `off`.

    Replaces PATCH /game/players/me.

    Args:
        body (GamePlayerPatch): Omit a key to leave it alone; send `null` to clear it.
            `character_name` is screened whenever it is set, whatever the profile’s visibility.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1GamePlayersMeResponse200 | StripeError]
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
    body: GamePlayerPatch,
) -> PostV1GamePlayersMeResponse200 | StripeError | None:
    """Create or edit the caller’s own per-game profile

     Omitting a key leaves the stored value alone; sending `null` clears it — without that distinction a
    character name could be replaced but never removed. Only the keys actually sent are written, so an
    avatar-only edit cannot reset `visibility` to the `private` default or rewrite `first_played_at`. A
    character name is SCREENED whenever it is set, not only when the profile is public, because
    visibility can be flipped later with no text change — a refused name is 422 and echoes nothing about
    the verdict. 422 also when the game’s `character_names` setting is `off`.

    Replaces PATCH /game/players/me.

    Args:
        body (GamePlayerPatch): Omit a key to leave it alone; send `null` to clear it.
            `character_name` is screened whenever it is set, whatever the profile’s visibility.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1GamePlayersMeResponse200 | StripeError
    """

    return sync_detailed(
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    body: GamePlayerPatch,
) -> Response[PostV1GamePlayersMeResponse200 | StripeError]:
    """Create or edit the caller’s own per-game profile

     Omitting a key leaves the stored value alone; sending `null` clears it — without that distinction a
    character name could be replaced but never removed. Only the keys actually sent are written, so an
    avatar-only edit cannot reset `visibility` to the `private` default or rewrite `first_played_at`. A
    character name is SCREENED whenever it is set, not only when the profile is public, because
    visibility can be flipped later with no text change — a refused name is 422 and echoes nothing about
    the verdict. 422 also when the game’s `character_names` setting is `off`.

    Replaces PATCH /game/players/me.

    Args:
        body (GamePlayerPatch): Omit a key to leave it alone; send `null` to clear it.
            `character_name` is screened whenever it is set, whatever the profile’s visibility.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1GamePlayersMeResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    body: GamePlayerPatch,
) -> PostV1GamePlayersMeResponse200 | StripeError | None:
    """Create or edit the caller’s own per-game profile

     Omitting a key leaves the stored value alone; sending `null` clears it — without that distinction a
    character name could be replaced but never removed. Only the keys actually sent are written, so an
    avatar-only edit cannot reset `visibility` to the `private` default or rewrite `first_played_at`. A
    character name is SCREENED whenever it is set, not only when the profile is public, because
    visibility can be flipped later with no text change — a refused name is 422 and echoes nothing about
    the verdict. 422 also when the game’s `character_names` setting is `off`.

    Replaces PATCH /game/players/me.

    Args:
        body (GamePlayerPatch): Omit a key to leave it alone; send `null` to clear it.
            `character_name` is screened whenever it is set, whatever the profile’s visibility.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1GamePlayersMeResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
        )
    ).parsed
