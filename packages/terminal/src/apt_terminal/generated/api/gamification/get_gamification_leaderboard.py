from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.gamification_leaderboard import GamificationLeaderboard
from ...models.get_gamification_leaderboard_period import GetGamificationLeaderboardPeriod
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    subject_type: str | Unset = "user",
    period: GetGamificationLeaderboardPeriod | Unset = GetGamificationLeaderboardPeriod.ALL,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["subjectType"] = subject_type

    json_period: str | Unset = UNSET
    if not isinstance(period, Unset):
        json_period = period.value

    params["period"] = json_period

    params["page"] = page

    params["pageSize"] = page_size

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/gamification/leaderboard",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | GamificationLeaderboard | None:
    if response.status_code == 200:
        response_200 = GamificationLeaderboard.from_dict(response.json())

        return response_200

    if response.status_code == 401:
        response_401 = Error.from_dict(response.json())

        return response_401

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | GamificationLeaderboard]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    subject_type: str | Unset = "user",
    period: GetGamificationLeaderboardPeriod | Unset = GetGamificationLeaderboardPeriod.ALL,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
) -> Response[Error | GamificationLeaderboard]:
    """Ranked leaderboard by summed points for a subject kind

    Args:
        subject_type (str | Unset):  Default: 'user'.
        period (GetGamificationLeaderboardPeriod | Unset):  Default:
            GetGamificationLeaderboardPeriod.ALL.
        page (str | Unset):
        page_size (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GamificationLeaderboard]
    """

    kwargs = _get_kwargs(
        subject_type=subject_type,
        period=period,
        page=page,
        page_size=page_size,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    subject_type: str | Unset = "user",
    period: GetGamificationLeaderboardPeriod | Unset = GetGamificationLeaderboardPeriod.ALL,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
) -> Error | GamificationLeaderboard | None:
    """Ranked leaderboard by summed points for a subject kind

    Args:
        subject_type (str | Unset):  Default: 'user'.
        period (GetGamificationLeaderboardPeriod | Unset):  Default:
            GetGamificationLeaderboardPeriod.ALL.
        page (str | Unset):
        page_size (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GamificationLeaderboard
    """

    return sync_detailed(
        client=client,
        subject_type=subject_type,
        period=period,
        page=page,
        page_size=page_size,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    subject_type: str | Unset = "user",
    period: GetGamificationLeaderboardPeriod | Unset = GetGamificationLeaderboardPeriod.ALL,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
) -> Response[Error | GamificationLeaderboard]:
    """Ranked leaderboard by summed points for a subject kind

    Args:
        subject_type (str | Unset):  Default: 'user'.
        period (GetGamificationLeaderboardPeriod | Unset):  Default:
            GetGamificationLeaderboardPeriod.ALL.
        page (str | Unset):
        page_size (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GamificationLeaderboard]
    """

    kwargs = _get_kwargs(
        subject_type=subject_type,
        period=period,
        page=page,
        page_size=page_size,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    subject_type: str | Unset = "user",
    period: GetGamificationLeaderboardPeriod | Unset = GetGamificationLeaderboardPeriod.ALL,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
) -> Error | GamificationLeaderboard | None:
    """Ranked leaderboard by summed points for a subject kind

    Args:
        subject_type (str | Unset):  Default: 'user'.
        period (GetGamificationLeaderboardPeriod | Unset):  Default:
            GetGamificationLeaderboardPeriod.ALL.
        page (str | Unset):
        page_size (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GamificationLeaderboard
    """

    return (
        await asyncio_detailed(
            client=client,
            subject_type=subject_type,
            period=period,
            page=page,
            page_size=page_size,
        )
    ).parsed
