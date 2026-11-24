from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.get_v1_game_instances_response_200 import GetV1GameInstancesResponse200
from ...models.stripe_error import StripeError
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    game_id: str | Unset = UNSET,
    slug: str | Unset = UNSET,
    depth: str | Unset = UNSET,
    limit: int | Unset = 10,
    starting_after: str | Unset = UNSET,
    ending_before: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["game_id"] = game_id

    params["slug"] = slug

    params["depth"] = depth

    params["limit"] = limit

    params["starting_after"] = starting_after

    params["ending_before"] = ending_before

    json_expand: list[str] | Unset = UNSET
    if not isinstance(expand, Unset):
        json_expand = expand

    params["expand[]"] = json_expand

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/v1/game/instances",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> GetV1GameInstancesResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = GetV1GameInstancesResponse200.from_dict(response.json())

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
) -> Response[GetV1GameInstancesResponse200 | StripeError]:
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
    limit: int | Unset = 10,
    starting_after: str | Unset = UNSET,
    ending_before: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1GameInstancesResponse200 | StripeError]:
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

    Replaces GET /game/instances.

    Args:
        game_id (str | Unset):
        slug (str | Unset):
        depth (str | Unset):
        limit (int | Unset):  Default: 10.
        starting_after (str | Unset):
        ending_before (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1GameInstancesResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        game_id=game_id,
        slug=slug,
        depth=depth,
        limit=limit,
        starting_after=starting_after,
        ending_before=ending_before,
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
    depth: str | Unset = UNSET,
    limit: int | Unset = 10,
    starting_after: str | Unset = UNSET,
    ending_before: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> GetV1GameInstancesResponse200 | StripeError | None:
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

    Replaces GET /game/instances.

    Args:
        game_id (str | Unset):
        slug (str | Unset):
        depth (str | Unset):
        limit (int | Unset):  Default: 10.
        starting_after (str | Unset):
        ending_before (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1GameInstancesResponse200 | StripeError
    """

    return sync_detailed(
        client=client,
        game_id=game_id,
        slug=slug,
        depth=depth,
        limit=limit,
        starting_after=starting_after,
        ending_before=ending_before,
        expand=expand,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    game_id: str | Unset = UNSET,
    slug: str | Unset = UNSET,
    depth: str | Unset = UNSET,
    limit: int | Unset = 10,
    starting_after: str | Unset = UNSET,
    ending_before: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1GameInstancesResponse200 | StripeError]:
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

    Replaces GET /game/instances.

    Args:
        game_id (str | Unset):
        slug (str | Unset):
        depth (str | Unset):
        limit (int | Unset):  Default: 10.
        starting_after (str | Unset):
        ending_before (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1GameInstancesResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        game_id=game_id,
        slug=slug,
        depth=depth,
        limit=limit,
        starting_after=starting_after,
        ending_before=ending_before,
        expand=expand,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    game_id: str | Unset = UNSET,
    slug: str | Unset = UNSET,
    depth: str | Unset = UNSET,
    limit: int | Unset = 10,
    starting_after: str | Unset = UNSET,
    ending_before: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> GetV1GameInstancesResponse200 | StripeError | None:
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

    Replaces GET /game/instances.

    Args:
        game_id (str | Unset):
        slug (str | Unset):
        depth (str | Unset):
        limit (int | Unset):  Default: 10.
        starting_after (str | Unset):
        ending_before (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1GameInstancesResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            client=client,
            game_id=game_id,
            slug=slug,
            depth=depth,
            limit=limit,
            starting_after=starting_after,
            ending_before=ending_before,
            expand=expand,
        )
    ).parsed
