from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.get_game_instances_response_200 import GetGameInstancesResponse200
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    game_id: str | Unset = UNSET,
    slug: str | Unset = UNSET,
    depth: str | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["game_id"] = game_id

    params["slug"] = slug

    params["depth"] = depth

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/game/instances",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | GetGameInstancesResponse200 | None:
    if response.status_code == 200:
        response_200 = GetGameInstancesResponse200.from_dict(response.json())

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

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | GetGameInstancesResponse200]:
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
    depth: str | Unset = UNSET,
) -> Response[Error | GetGameInstancesResponse200]:
    """The caller’s own instances, including what is inside what they hold

     A recursive containment walk: everything located on the player, plus everything located inside
    those, and so on — the chest in the inventory and the key in the chest. Two INDEPENDENT bounds, and
    neither substitutes for the other: a depth cap (default and maximum 32) cuts a containment cycle,
    and a hard row limit (2000) cuts breadth, because a cycle at depth 2 fanning out ten ways per level
    is still 10^32 rows inside the depth cap. The row limit is applied BEFORE the sort, so a truncated
    walk returns the rows the walk reached first (shallowest first) rather than the smallest 2000 by
    sort key; on a well-formed world nothing is truncated and the two are the same. `location_id`
    carries no FK, so nothing is read from the request: the player id comes from the caller’s own
    resolved profile. A caller who has never played gets an empty list, not a 404.

    Args:
        game_id (str | Unset):
        slug (str | Unset):
        depth (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GetGameInstancesResponse200]
    """

    kwargs = _get_kwargs(
        game_id=game_id,
        slug=slug,
        depth=depth,
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
    depth: str | Unset = UNSET,
) -> Error | GetGameInstancesResponse200 | None:
    """The caller’s own instances, including what is inside what they hold

     A recursive containment walk: everything located on the player, plus everything located inside
    those, and so on — the chest in the inventory and the key in the chest. Two INDEPENDENT bounds, and
    neither substitutes for the other: a depth cap (default and maximum 32) cuts a containment cycle,
    and a hard row limit (2000) cuts breadth, because a cycle at depth 2 fanning out ten ways per level
    is still 10^32 rows inside the depth cap. The row limit is applied BEFORE the sort, so a truncated
    walk returns the rows the walk reached first (shallowest first) rather than the smallest 2000 by
    sort key; on a well-formed world nothing is truncated and the two are the same. `location_id`
    carries no FK, so nothing is read from the request: the player id comes from the caller’s own
    resolved profile. A caller who has never played gets an empty list, not a 404.

    Args:
        game_id (str | Unset):
        slug (str | Unset):
        depth (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GetGameInstancesResponse200
    """

    return sync_detailed(
        client=client,
        game_id=game_id,
        slug=slug,
        depth=depth,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    game_id: str | Unset = UNSET,
    slug: str | Unset = UNSET,
    depth: str | Unset = UNSET,
) -> Response[Error | GetGameInstancesResponse200]:
    """The caller’s own instances, including what is inside what they hold

     A recursive containment walk: everything located on the player, plus everything located inside
    those, and so on — the chest in the inventory and the key in the chest. Two INDEPENDENT bounds, and
    neither substitutes for the other: a depth cap (default and maximum 32) cuts a containment cycle,
    and a hard row limit (2000) cuts breadth, because a cycle at depth 2 fanning out ten ways per level
    is still 10^32 rows inside the depth cap. The row limit is applied BEFORE the sort, so a truncated
    walk returns the rows the walk reached first (shallowest first) rather than the smallest 2000 by
    sort key; on a well-formed world nothing is truncated and the two are the same. `location_id`
    carries no FK, so nothing is read from the request: the player id comes from the caller’s own
    resolved profile. A caller who has never played gets an empty list, not a 404.

    Args:
        game_id (str | Unset):
        slug (str | Unset):
        depth (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GetGameInstancesResponse200]
    """

    kwargs = _get_kwargs(
        game_id=game_id,
        slug=slug,
        depth=depth,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    game_id: str | Unset = UNSET,
    slug: str | Unset = UNSET,
    depth: str | Unset = UNSET,
) -> Error | GetGameInstancesResponse200 | None:
    """The caller’s own instances, including what is inside what they hold

     A recursive containment walk: everything located on the player, plus everything located inside
    those, and so on — the chest in the inventory and the key in the chest. Two INDEPENDENT bounds, and
    neither substitutes for the other: a depth cap (default and maximum 32) cuts a containment cycle,
    and a hard row limit (2000) cuts breadth, because a cycle at depth 2 fanning out ten ways per level
    is still 10^32 rows inside the depth cap. The row limit is applied BEFORE the sort, so a truncated
    walk returns the rows the walk reached first (shallowest first) rather than the smallest 2000 by
    sort key; on a well-formed world nothing is truncated and the two are the same. `location_id`
    carries no FK, so nothing is read from the request: the player id comes from the caller’s own
    resolved profile. A caller who has never played gets an empty list, not a 404.

    Args:
        game_id (str | Unset):
        slug (str | Unset):
        depth (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GetGameInstancesResponse200
    """

    return (
        await asyncio_detailed(
            client=client,
            game_id=game_id,
            slug=slug,
            depth=depth,
        )
    ).parsed
