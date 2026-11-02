from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.gamification_board import GamificationBoard
from ...models.get_public_boards_stat_key_window import GetPublicBoardsStatKeyWindow
from ...types import UNSET, Response, Unset


def _get_kwargs(
    stat_key: str,
    *,
    window: GetPublicBoardsStatKeyWindow | Unset = GetPublicBoardsStatKeyWindow.TRENDING,
    limit: int | Unset = 20,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    json_window: str | Unset = UNSET
    if not isinstance(window, Unset):
        json_window = window.value

    params["window"] = json_window

    params["limit"] = limit

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/public/boards/{stat_key}".format(
            stat_key=quote(str(stat_key), safe=""),
        ),
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | GamificationBoard | None:
    if response.status_code == 200:
        response_200 = GamificationBoard.from_dict(response.json())

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
) -> Response[Error | GamificationBoard]:
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
    window: GetPublicBoardsStatKeyWindow | Unset = GetPublicBoardsStatKeyWindow.TRENDING,
    limit: int | Unset = 20,
) -> Response[Error | GamificationBoard]:
    """Public hub leaderboard for one boardable stat (surface-gated)

    Args:
        stat_key (str):
        window (GetPublicBoardsStatKeyWindow | Unset):  Default:
            GetPublicBoardsStatKeyWindow.TRENDING.
        limit (int | Unset):  Default: 20.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GamificationBoard]
    """

    kwargs = _get_kwargs(
        stat_key=stat_key,
        window=window,
        limit=limit,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    stat_key: str,
    *,
    client: AuthenticatedClient | Client,
    window: GetPublicBoardsStatKeyWindow | Unset = GetPublicBoardsStatKeyWindow.TRENDING,
    limit: int | Unset = 20,
) -> Error | GamificationBoard | None:
    """Public hub leaderboard for one boardable stat (surface-gated)

    Args:
        stat_key (str):
        window (GetPublicBoardsStatKeyWindow | Unset):  Default:
            GetPublicBoardsStatKeyWindow.TRENDING.
        limit (int | Unset):  Default: 20.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GamificationBoard
    """

    return sync_detailed(
        stat_key=stat_key,
        client=client,
        window=window,
        limit=limit,
    ).parsed


async def asyncio_detailed(
    stat_key: str,
    *,
    client: AuthenticatedClient | Client,
    window: GetPublicBoardsStatKeyWindow | Unset = GetPublicBoardsStatKeyWindow.TRENDING,
    limit: int | Unset = 20,
) -> Response[Error | GamificationBoard]:
    """Public hub leaderboard for one boardable stat (surface-gated)

    Args:
        stat_key (str):
        window (GetPublicBoardsStatKeyWindow | Unset):  Default:
            GetPublicBoardsStatKeyWindow.TRENDING.
        limit (int | Unset):  Default: 20.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GamificationBoard]
    """

    kwargs = _get_kwargs(
        stat_key=stat_key,
        window=window,
        limit=limit,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    stat_key: str,
    *,
    client: AuthenticatedClient | Client,
    window: GetPublicBoardsStatKeyWindow | Unset = GetPublicBoardsStatKeyWindow.TRENDING,
    limit: int | Unset = 20,
) -> Error | GamificationBoard | None:
    """Public hub leaderboard for one boardable stat (surface-gated)

    Args:
        stat_key (str):
        window (GetPublicBoardsStatKeyWindow | Unset):  Default:
            GetPublicBoardsStatKeyWindow.TRENDING.
        limit (int | Unset):  Default: 20.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GamificationBoard
    """

    return (
        await asyncio_detailed(
            stat_key=stat_key,
            client=client,
            window=window,
            limit=limit,
        )
    ).parsed
