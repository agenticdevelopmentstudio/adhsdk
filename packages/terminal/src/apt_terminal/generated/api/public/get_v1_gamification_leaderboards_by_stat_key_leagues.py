from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.get_v1_gamification_leaderboards_by_stat_key_leagues_response_200 import (
    GetV1GamificationLeaderboardsByStatKeyLeaguesResponse200,
)
from ...models.stripe_error import StripeError
from ...types import UNSET, Response, Unset


def _get_kwargs(
    stat_key: str,
    *,
    league: int | Unset = 0,
    expand: list[str] | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["league"] = league

    json_expand: list[str] | Unset = UNSET
    if not isinstance(expand, Unset):
        json_expand = expand

    params["expand[]"] = json_expand

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/v1/gamification/leaderboards/{stat_key}/leagues".format(
            stat_key=quote(str(stat_key), safe=""),
        ),
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> GetV1GamificationLeaderboardsByStatKeyLeaguesResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = GetV1GamificationLeaderboardsByStatKeyLeaguesResponse200.from_dict(
            response.json()
        )

        return response_200

    if response.status_code == 400:
        response_400 = StripeError.from_dict(response.json())

        return response_400

    if response.status_code == 404:
        response_404 = StripeError.from_dict(response.json())

        return response_404

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[GetV1GamificationLeaderboardsByStatKeyLeaguesResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    stat_key: str,
    *,
    client: AuthenticatedClient | Client,
    league: int | Unset = 0,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1GamificationLeaderboardsByStatKeyLeaguesResponse200 | StripeError]:
    """Public hub league cohort of the current season board (surface-gated)

     Replaces GET /public/boards/{statKey}/leagues.

    Args:
        stat_key (str):
        league (int | Unset):  Default: 0.
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1GamificationLeaderboardsByStatKeyLeaguesResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        stat_key=stat_key,
        league=league,
        expand=expand,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    stat_key: str,
    *,
    client: AuthenticatedClient | Client,
    league: int | Unset = 0,
    expand: list[str] | Unset = UNSET,
) -> GetV1GamificationLeaderboardsByStatKeyLeaguesResponse200 | StripeError | None:
    """Public hub league cohort of the current season board (surface-gated)

     Replaces GET /public/boards/{statKey}/leagues.

    Args:
        stat_key (str):
        league (int | Unset):  Default: 0.
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1GamificationLeaderboardsByStatKeyLeaguesResponse200 | StripeError
    """

    return sync_detailed(
        stat_key=stat_key,
        client=client,
        league=league,
        expand=expand,
    ).parsed


async def asyncio_detailed(
    stat_key: str,
    *,
    client: AuthenticatedClient | Client,
    league: int | Unset = 0,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1GamificationLeaderboardsByStatKeyLeaguesResponse200 | StripeError]:
    """Public hub league cohort of the current season board (surface-gated)

     Replaces GET /public/boards/{statKey}/leagues.

    Args:
        stat_key (str):
        league (int | Unset):  Default: 0.
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1GamificationLeaderboardsByStatKeyLeaguesResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        stat_key=stat_key,
        league=league,
        expand=expand,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    stat_key: str,
    *,
    client: AuthenticatedClient | Client,
    league: int | Unset = 0,
    expand: list[str] | Unset = UNSET,
) -> GetV1GamificationLeaderboardsByStatKeyLeaguesResponse200 | StripeError | None:
    """Public hub league cohort of the current season board (surface-gated)

     Replaces GET /public/boards/{statKey}/leagues.

    Args:
        stat_key (str):
        league (int | Unset):  Default: 0.
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1GamificationLeaderboardsByStatKeyLeaguesResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            stat_key=stat_key,
            client=client,
            league=league,
            expand=expand,
        )
    ).parsed
