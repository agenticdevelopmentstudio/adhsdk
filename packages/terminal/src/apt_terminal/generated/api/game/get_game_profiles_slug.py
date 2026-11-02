from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.game_public_profile import GamePublicProfile
from ...types import UNSET, Response, Unset


def _get_kwargs(
    slug_path: str,
    *,
    game_id: str | Unset = UNSET,
    slug_query: str | Unset = UNSET,
    ecosystem: str | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["game_id"] = game_id

    params["slug"] = slug_query

    params["ecosystem"] = ecosystem

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/game/profiles/{slug_path}".format(
            slug_path=quote(str(slug_path), safe=""),
        ),
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | GamePublicProfile | None:
    if response.status_code == 200:
        response_200 = GamePublicProfile.from_dict(response.json())

        return response_200

    if response.status_code == 400:
        response_400 = Error.from_dict(response.json())

        return response_400

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
) -> Response[Error | GamePublicProfile]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    slug_path: str,
    *,
    client: AuthenticatedClient | Client,
    game_id: str | Unset = UNSET,
    slug_query: str | Unset = UNSET,
    ecosystem: str | Unset = UNSET,
) -> Response[Error | GamePublicProfile]:
    """A player’s public per-game profile, by account slug (anonymous)

     Addressed by the account’s own slug (§4.5.1: one account, one profile address) — a `character_name`
    is flavour and nothing is addressed by it. **Four independent gates, every failure the same 404**:
    the account exists and is not deleted; `customers.public_profile_enabled` (the account-wide opt-in,
    honoured here exactly as the sibling `/public/users/{slug}` routes honour it); the per-game
    `players.visibility` is `public` or `unlisted`; and the game is not retired. Distinguishing them
    would tell a caller that an account exists AND plays this game, which is the fact the setting exists
    to withhold. `characterName` is withheld when the game’s `character_names` is `off`, at read time —
    a name stored before the operator turned the feature off is still in the column. A fifth gate sits
    under all of them: the product must be in `game` mode. `ecosystem` disambiguates which game a bare
    `slug` names (an unqualified ambiguous slug is a 409).

    Args:
        slug_path (str):
        game_id (str | Unset):
        slug_query (str | Unset):
        ecosystem (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GamePublicProfile]
    """

    kwargs = _get_kwargs(
        slug_path=slug_path,
        game_id=game_id,
        slug_query=slug_query,
        ecosystem=ecosystem,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    slug_path: str,
    *,
    client: AuthenticatedClient | Client,
    game_id: str | Unset = UNSET,
    slug_query: str | Unset = UNSET,
    ecosystem: str | Unset = UNSET,
) -> Error | GamePublicProfile | None:
    """A player’s public per-game profile, by account slug (anonymous)

     Addressed by the account’s own slug (§4.5.1: one account, one profile address) — a `character_name`
    is flavour and nothing is addressed by it. **Four independent gates, every failure the same 404**:
    the account exists and is not deleted; `customers.public_profile_enabled` (the account-wide opt-in,
    honoured here exactly as the sibling `/public/users/{slug}` routes honour it); the per-game
    `players.visibility` is `public` or `unlisted`; and the game is not retired. Distinguishing them
    would tell a caller that an account exists AND plays this game, which is the fact the setting exists
    to withhold. `characterName` is withheld when the game’s `character_names` is `off`, at read time —
    a name stored before the operator turned the feature off is still in the column. A fifth gate sits
    under all of them: the product must be in `game` mode. `ecosystem` disambiguates which game a bare
    `slug` names (an unqualified ambiguous slug is a 409).

    Args:
        slug_path (str):
        game_id (str | Unset):
        slug_query (str | Unset):
        ecosystem (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GamePublicProfile
    """

    return sync_detailed(
        slug_path=slug_path,
        client=client,
        game_id=game_id,
        slug_query=slug_query,
        ecosystem=ecosystem,
    ).parsed


async def asyncio_detailed(
    slug_path: str,
    *,
    client: AuthenticatedClient | Client,
    game_id: str | Unset = UNSET,
    slug_query: str | Unset = UNSET,
    ecosystem: str | Unset = UNSET,
) -> Response[Error | GamePublicProfile]:
    """A player’s public per-game profile, by account slug (anonymous)

     Addressed by the account’s own slug (§4.5.1: one account, one profile address) — a `character_name`
    is flavour and nothing is addressed by it. **Four independent gates, every failure the same 404**:
    the account exists and is not deleted; `customers.public_profile_enabled` (the account-wide opt-in,
    honoured here exactly as the sibling `/public/users/{slug}` routes honour it); the per-game
    `players.visibility` is `public` or `unlisted`; and the game is not retired. Distinguishing them
    would tell a caller that an account exists AND plays this game, which is the fact the setting exists
    to withhold. `characterName` is withheld when the game’s `character_names` is `off`, at read time —
    a name stored before the operator turned the feature off is still in the column. A fifth gate sits
    under all of them: the product must be in `game` mode. `ecosystem` disambiguates which game a bare
    `slug` names (an unqualified ambiguous slug is a 409).

    Args:
        slug_path (str):
        game_id (str | Unset):
        slug_query (str | Unset):
        ecosystem (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GamePublicProfile]
    """

    kwargs = _get_kwargs(
        slug_path=slug_path,
        game_id=game_id,
        slug_query=slug_query,
        ecosystem=ecosystem,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    slug_path: str,
    *,
    client: AuthenticatedClient | Client,
    game_id: str | Unset = UNSET,
    slug_query: str | Unset = UNSET,
    ecosystem: str | Unset = UNSET,
) -> Error | GamePublicProfile | None:
    """A player’s public per-game profile, by account slug (anonymous)

     Addressed by the account’s own slug (§4.5.1: one account, one profile address) — a `character_name`
    is flavour and nothing is addressed by it. **Four independent gates, every failure the same 404**:
    the account exists and is not deleted; `customers.public_profile_enabled` (the account-wide opt-in,
    honoured here exactly as the sibling `/public/users/{slug}` routes honour it); the per-game
    `players.visibility` is `public` or `unlisted`; and the game is not retired. Distinguishing them
    would tell a caller that an account exists AND plays this game, which is the fact the setting exists
    to withhold. `characterName` is withheld when the game’s `character_names` is `off`, at read time —
    a name stored before the operator turned the feature off is still in the column. A fifth gate sits
    under all of them: the product must be in `game` mode. `ecosystem` disambiguates which game a bare
    `slug` names (an unqualified ambiguous slug is a 409).

    Args:
        slug_path (str):
        game_id (str | Unset):
        slug_query (str | Unset):
        ecosystem (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GamePublicProfile
    """

    return (
        await asyncio_detailed(
            slug_path=slug_path,
            client=client,
            game_id=game_id,
            slug_query=slug_query,
            ecosystem=ecosystem,
        )
    ).parsed
