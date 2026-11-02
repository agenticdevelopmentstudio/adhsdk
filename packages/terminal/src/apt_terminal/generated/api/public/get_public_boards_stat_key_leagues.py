from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.gamification_league import GamificationLeague
from ...types import UNSET, Response, Unset


def _get_kwargs(
    stat_key: str,
    *,
    league: int | Unset = 0,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["league"] = league

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/public/boards/{stat_key}/leagues".format(
            stat_key=quote(str(stat_key), safe=""),
        ),
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | GamificationLeague | None:
    if response.status_code == 200:
        response_200 = GamificationLeague.from_dict(response.json())

        return response_200

    if response.status_code == 400:
        response_400 = Error.from_dict(response.json())

        return response_400

    if response.status_code == 404:
        response_404 = Error.from_dict(response.json())

        return response_404

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | GamificationLeague]:
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
) -> Response[Error | GamificationLeague]:
    """Public hub league cohort of the current season board (surface-gated)

    Args:
        stat_key (str):
        league (int | Unset):  Default: 0.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GamificationLeague]
    """

    kwargs = _get_kwargs(
        stat_key=stat_key,
        league=league,
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
) -> Error | GamificationLeague | None:
    """Public hub league cohort of the current season board (surface-gated)

    Args:
        stat_key (str):
        league (int | Unset):  Default: 0.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GamificationLeague
    """

    return sync_detailed(
        stat_key=stat_key,
        client=client,
        league=league,
    ).parsed


async def asyncio_detailed(
    stat_key: str,
    *,
    client: AuthenticatedClient | Client,
    league: int | Unset = 0,
) -> Response[Error | GamificationLeague]:
    """Public hub league cohort of the current season board (surface-gated)

    Args:
        stat_key (str):
        league (int | Unset):  Default: 0.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GamificationLeague]
    """

    kwargs = _get_kwargs(
        stat_key=stat_key,
        league=league,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    stat_key: str,
    *,
    client: AuthenticatedClient | Client,
    league: int | Unset = 0,
) -> Error | GamificationLeague | None:
    """Public hub league cohort of the current season board (surface-gated)

    Args:
        stat_key (str):
        league (int | Unset):  Default: 0.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GamificationLeague
    """

    return (
        await asyncio_detailed(
            stat_key=stat_key,
            client=client,
            league=league,
        )
    ).parsed
