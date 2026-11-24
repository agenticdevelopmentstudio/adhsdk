from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.get_v1_gamification_leaderboards_by_stat_key_response_200 import (
    GetV1GamificationLeaderboardsByStatKeyResponse200,
)
from ...models.get_v1_gamification_leaderboards_by_stat_key_window import (
    GetV1GamificationLeaderboardsByStatKeyWindow,
)
from ...models.stripe_error import StripeError
from ...types import UNSET, Response, Unset


def _get_kwargs(
    stat_key: str,
    *,
    ecosystem: str | Unset = UNSET,
    window: GetV1GamificationLeaderboardsByStatKeyWindow
    | Unset = GetV1GamificationLeaderboardsByStatKeyWindow.TRENDING,
    limit: int | Unset = 20,
    expand: list[str] | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["ecosystem"] = ecosystem

    json_window: str | Unset = UNSET
    if not isinstance(window, Unset):
        json_window = window.value

    params["window"] = json_window

    params["limit"] = limit

    json_expand: list[str] | Unset = UNSET
    if not isinstance(expand, Unset):
        json_expand = expand

    params["expand[]"] = json_expand

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/v1/gamification/leaderboards/{stat_key}".format(
            stat_key=quote(str(stat_key), safe=""),
        ),
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> GetV1GamificationLeaderboardsByStatKeyResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = GetV1GamificationLeaderboardsByStatKeyResponse200.from_dict(response.json())

        return response_200

    if response.status_code == 400:
        response_400 = StripeError.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = StripeError.from_dict(response.json())

        return response_401

    if response.status_code == 403:
        response_403 = StripeError.from_dict(response.json())

        return response_403

    if response.status_code == 404:
        response_404 = StripeError.from_dict(response.json())

        return response_404

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[GetV1GamificationLeaderboardsByStatKeyResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    stat_key: str,
    *,
    client: AuthenticatedClient,
    ecosystem: str | Unset = UNSET,
    window: GetV1GamificationLeaderboardsByStatKeyWindow
    | Unset = GetV1GamificationLeaderboardsByStatKeyWindow.TRENDING,
    limit: int | Unset = 20,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1GamificationLeaderboardsByStatKeyResponse200 | StripeError]:
    """Per-realm leaderboard for one boardable stat (admin)

     Replaces GET /gamification/realms/{ecosystemId}/boards/{statKey}, GET /public/boards/{statKey}.

    Args:
        stat_key (str):
        ecosystem (str | Unset):
        window (GetV1GamificationLeaderboardsByStatKeyWindow | Unset):  Default:
            GetV1GamificationLeaderboardsByStatKeyWindow.TRENDING.
        limit (int | Unset):  Default: 20.
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1GamificationLeaderboardsByStatKeyResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        stat_key=stat_key,
        ecosystem=ecosystem,
        window=window,
        limit=limit,
        expand=expand,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    stat_key: str,
    *,
    client: AuthenticatedClient,
    ecosystem: str | Unset = UNSET,
    window: GetV1GamificationLeaderboardsByStatKeyWindow
    | Unset = GetV1GamificationLeaderboardsByStatKeyWindow.TRENDING,
    limit: int | Unset = 20,
    expand: list[str] | Unset = UNSET,
) -> GetV1GamificationLeaderboardsByStatKeyResponse200 | StripeError | None:
    """Per-realm leaderboard for one boardable stat (admin)

     Replaces GET /gamification/realms/{ecosystemId}/boards/{statKey}, GET /public/boards/{statKey}.

    Args:
        stat_key (str):
        ecosystem (str | Unset):
        window (GetV1GamificationLeaderboardsByStatKeyWindow | Unset):  Default:
            GetV1GamificationLeaderboardsByStatKeyWindow.TRENDING.
        limit (int | Unset):  Default: 20.
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1GamificationLeaderboardsByStatKeyResponse200 | StripeError
    """

    return sync_detailed(
        stat_key=stat_key,
        client=client,
        ecosystem=ecosystem,
        window=window,
        limit=limit,
        expand=expand,
    ).parsed


async def asyncio_detailed(
    stat_key: str,
    *,
    client: AuthenticatedClient,
    ecosystem: str | Unset = UNSET,
    window: GetV1GamificationLeaderboardsByStatKeyWindow
    | Unset = GetV1GamificationLeaderboardsByStatKeyWindow.TRENDING,
    limit: int | Unset = 20,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1GamificationLeaderboardsByStatKeyResponse200 | StripeError]:
    """Per-realm leaderboard for one boardable stat (admin)

     Replaces GET /gamification/realms/{ecosystemId}/boards/{statKey}, GET /public/boards/{statKey}.

    Args:
        stat_key (str):
        ecosystem (str | Unset):
        window (GetV1GamificationLeaderboardsByStatKeyWindow | Unset):  Default:
            GetV1GamificationLeaderboardsByStatKeyWindow.TRENDING.
        limit (int | Unset):  Default: 20.
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1GamificationLeaderboardsByStatKeyResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        stat_key=stat_key,
        ecosystem=ecosystem,
        window=window,
        limit=limit,
        expand=expand,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    stat_key: str,
    *,
    client: AuthenticatedClient,
    ecosystem: str | Unset = UNSET,
    window: GetV1GamificationLeaderboardsByStatKeyWindow
    | Unset = GetV1GamificationLeaderboardsByStatKeyWindow.TRENDING,
    limit: int | Unset = 20,
    expand: list[str] | Unset = UNSET,
) -> GetV1GamificationLeaderboardsByStatKeyResponse200 | StripeError | None:
    """Per-realm leaderboard for one boardable stat (admin)

     Replaces GET /gamification/realms/{ecosystemId}/boards/{statKey}, GET /public/boards/{statKey}.

    Args:
        stat_key (str):
        ecosystem (str | Unset):
        window (GetV1GamificationLeaderboardsByStatKeyWindow | Unset):  Default:
            GetV1GamificationLeaderboardsByStatKeyWindow.TRENDING.
        limit (int | Unset):  Default: 20.
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1GamificationLeaderboardsByStatKeyResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            stat_key=stat_key,
            client=client,
            ecosystem=ecosystem,
            window=window,
            limit=limit,
            expand=expand,
        )
    ).parsed
