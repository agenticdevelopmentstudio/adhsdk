from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.get_game_feed_response_200 import GetGameFeedResponse200
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    game_id: str | Unset = UNSET,
    slug: str | Unset = UNSET,
    ecosystem: str | Unset = UNSET,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["game_id"] = game_id

    params["slug"] = slug

    params["ecosystem"] = ecosystem

    params["page"] = page

    params["page_size"] = page_size

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/game/feed",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | GetGameFeedResponse200 | None:
    if response.status_code == 200:
        response_200 = GetGameFeedResponse200.from_dict(response.json())

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
) -> Response[Error | GetGameFeedResponse200]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient | Client,
    game_id: str | Unset = UNSET,
    slug: str | Unset = UNSET,
    ecosystem: str | Unset = UNSET,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
) -> Response[Error | GetGameFeedResponse200]:
    """One game’s public artifact feed (anonymous, read replica)

     The hot path, and it carries no `security`: it serves published artifacts to signed-out visitors and
    runs on the read replica so it does not contend with authenticated traffic. Three predicates are the
    entire boundary — `visibility = 'public'`, `deleted_at is null`, and `ecosystem_id`, which is taken
    from the resolved game row and never used as a caller-supplied filter. `ecosystem` only
    disambiguates which game a bare `slug` names — ecosystem slugs are unique under a parent, so two
    products really can both own a game called `chess`, and an unqualified ambiguous slug is a 409. A
    retired game is 404, and so is a product that is not in `game` mode.

    Args:
        game_id (str | Unset):
        slug (str | Unset):
        ecosystem (str | Unset):
        page (str | Unset):
        page_size (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GetGameFeedResponse200]
    """

    kwargs = _get_kwargs(
        game_id=game_id,
        slug=slug,
        ecosystem=ecosystem,
        page=page,
        page_size=page_size,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient | Client,
    game_id: str | Unset = UNSET,
    slug: str | Unset = UNSET,
    ecosystem: str | Unset = UNSET,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
) -> Error | GetGameFeedResponse200 | None:
    """One game’s public artifact feed (anonymous, read replica)

     The hot path, and it carries no `security`: it serves published artifacts to signed-out visitors and
    runs on the read replica so it does not contend with authenticated traffic. Three predicates are the
    entire boundary — `visibility = 'public'`, `deleted_at is null`, and `ecosystem_id`, which is taken
    from the resolved game row and never used as a caller-supplied filter. `ecosystem` only
    disambiguates which game a bare `slug` names — ecosystem slugs are unique under a parent, so two
    products really can both own a game called `chess`, and an unqualified ambiguous slug is a 409. A
    retired game is 404, and so is a product that is not in `game` mode.

    Args:
        game_id (str | Unset):
        slug (str | Unset):
        ecosystem (str | Unset):
        page (str | Unset):
        page_size (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GetGameFeedResponse200
    """

    return sync_detailed(
        client=client,
        game_id=game_id,
        slug=slug,
        ecosystem=ecosystem,
        page=page,
        page_size=page_size,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient | Client,
    game_id: str | Unset = UNSET,
    slug: str | Unset = UNSET,
    ecosystem: str | Unset = UNSET,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
) -> Response[Error | GetGameFeedResponse200]:
    """One game’s public artifact feed (anonymous, read replica)

     The hot path, and it carries no `security`: it serves published artifacts to signed-out visitors and
    runs on the read replica so it does not contend with authenticated traffic. Three predicates are the
    entire boundary — `visibility = 'public'`, `deleted_at is null`, and `ecosystem_id`, which is taken
    from the resolved game row and never used as a caller-supplied filter. `ecosystem` only
    disambiguates which game a bare `slug` names — ecosystem slugs are unique under a parent, so two
    products really can both own a game called `chess`, and an unqualified ambiguous slug is a 409. A
    retired game is 404, and so is a product that is not in `game` mode.

    Args:
        game_id (str | Unset):
        slug (str | Unset):
        ecosystem (str | Unset):
        page (str | Unset):
        page_size (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GetGameFeedResponse200]
    """

    kwargs = _get_kwargs(
        game_id=game_id,
        slug=slug,
        ecosystem=ecosystem,
        page=page,
        page_size=page_size,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient | Client,
    game_id: str | Unset = UNSET,
    slug: str | Unset = UNSET,
    ecosystem: str | Unset = UNSET,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
) -> Error | GetGameFeedResponse200 | None:
    """One game’s public artifact feed (anonymous, read replica)

     The hot path, and it carries no `security`: it serves published artifacts to signed-out visitors and
    runs on the read replica so it does not contend with authenticated traffic. Three predicates are the
    entire boundary — `visibility = 'public'`, `deleted_at is null`, and `ecosystem_id`, which is taken
    from the resolved game row and never used as a caller-supplied filter. `ecosystem` only
    disambiguates which game a bare `slug` names — ecosystem slugs are unique under a parent, so two
    products really can both own a game called `chess`, and an unqualified ambiguous slug is a 409. A
    retired game is 404, and so is a product that is not in `game` mode.

    Args:
        game_id (str | Unset):
        slug (str | Unset):
        ecosystem (str | Unset):
        page (str | Unset):
        page_size (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GetGameFeedResponse200
    """

    return (
        await asyncio_detailed(
            client=client,
            game_id=game_id,
            slug=slug,
            ecosystem=ecosystem,
            page=page,
            page_size=page_size,
        )
    ).parsed
