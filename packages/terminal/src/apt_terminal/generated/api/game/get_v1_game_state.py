from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.get_v1_game_state_response_200 import GetV1GameStateResponse200
from ...models.stripe_error import StripeError
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    game_id: str | Unset = UNSET,
    slug: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["game_id"] = game_id

    params["slug"] = slug

    json_expand: list[str] | Unset = UNSET
    if not isinstance(expand, Unset):
        json_expand = expand

    params["expand[]"] = json_expand

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/v1/game/state",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> GetV1GameStateResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = GetV1GameStateResponse200.from_dict(response.json())

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

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[GetV1GameStateResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    game_id: str | Unset = UNSET,
    slug: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1GameStateResponse200 | StripeError]:
    """The caller’s own scalars and lists, plus the game-wide ones

     Two sets with different owners, and they are NOT merged. The `player`-subject rows are the caller’s
    alone; the `game`-subject rows are shared configuration (limits, global settings). A flat map would
    let a player-owned key silently shadow a global of the same name — a per-player rules change nobody
    authored — and the two have different lifetimes, so a merged map has no coherent cache policy.
    Values are ARRAYS throughout, including for a key with one row: §4.11 stores a scalar as "one row at
    ordinal 0" and a one-element list as the same thing, so collapsing single values would invent a
    distinction the storage does not carry.

    Replaces GET /game/state.

    Args:
        game_id (str | Unset):
        slug (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1GameStateResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        game_id=game_id,
        slug=slug,
        expand=expand,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    game_id: str | Unset = UNSET,
    slug: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> GetV1GameStateResponse200 | StripeError | None:
    """The caller’s own scalars and lists, plus the game-wide ones

     Two sets with different owners, and they are NOT merged. The `player`-subject rows are the caller’s
    alone; the `game`-subject rows are shared configuration (limits, global settings). A flat map would
    let a player-owned key silently shadow a global of the same name — a per-player rules change nobody
    authored — and the two have different lifetimes, so a merged map has no coherent cache policy.
    Values are ARRAYS throughout, including for a key with one row: §4.11 stores a scalar as "one row at
    ordinal 0" and a one-element list as the same thing, so collapsing single values would invent a
    distinction the storage does not carry.

    Replaces GET /game/state.

    Args:
        game_id (str | Unset):
        slug (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1GameStateResponse200 | StripeError
    """

    return sync_detailed(
        client=client,
        game_id=game_id,
        slug=slug,
        expand=expand,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    game_id: str | Unset = UNSET,
    slug: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1GameStateResponse200 | StripeError]:
    """The caller’s own scalars and lists, plus the game-wide ones

     Two sets with different owners, and they are NOT merged. The `player`-subject rows are the caller’s
    alone; the `game`-subject rows are shared configuration (limits, global settings). A flat map would
    let a player-owned key silently shadow a global of the same name — a per-player rules change nobody
    authored — and the two have different lifetimes, so a merged map has no coherent cache policy.
    Values are ARRAYS throughout, including for a key with one row: §4.11 stores a scalar as "one row at
    ordinal 0" and a one-element list as the same thing, so collapsing single values would invent a
    distinction the storage does not carry.

    Replaces GET /game/state.

    Args:
        game_id (str | Unset):
        slug (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1GameStateResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        game_id=game_id,
        slug=slug,
        expand=expand,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    game_id: str | Unset = UNSET,
    slug: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> GetV1GameStateResponse200 | StripeError | None:
    """The caller’s own scalars and lists, plus the game-wide ones

     Two sets with different owners, and they are NOT merged. The `player`-subject rows are the caller’s
    alone; the `game`-subject rows are shared configuration (limits, global settings). A flat map would
    let a player-owned key silently shadow a global of the same name — a per-player rules change nobody
    authored — and the two have different lifetimes, so a merged map has no coherent cache policy.
    Values are ARRAYS throughout, including for a key with one row: §4.11 stores a scalar as "one row at
    ordinal 0" and a one-element list as the same thing, so collapsing single values would invent a
    distinction the storage does not carry.

    Replaces GET /game/state.

    Args:
        game_id (str | Unset):
        slug (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1GameStateResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            client=client,
            game_id=game_id,
            slug=slug,
            expand=expand,
        )
    ).parsed
