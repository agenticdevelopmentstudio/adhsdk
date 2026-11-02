from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.team_reach_grant_list import TeamReachGrantList
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    ecosystem_id: str,
    team_id: str | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["ecosystemId"] = ecosystem_id

    params["teamId"] = team_id

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/access/team-reach",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | TeamReachGrantList | None:
    if response.status_code == 200:
        response_200 = TeamReachGrantList.from_dict(response.json())

        return response_200

    if response.status_code == 400:
        response_400 = Error.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = Error.from_dict(response.json())

        return response_401

    if response.status_code == 403:
        response_403 = Error.from_dict(response.json())

        return response_403

    if response.status_code == 404:
        response_404 = Error.from_dict(response.json())

        return response_404

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | TeamReachGrantList]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    ecosystem_id: str,
    team_id: str | Unset = UNSET,
) -> Response[Error | TeamReachGrantList]:
    """List the team reach grants INTO one ecosystem

    Args:
        ecosystem_id (str):
        team_id (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | TeamReachGrantList]
    """

    kwargs = _get_kwargs(
        ecosystem_id=ecosystem_id,
        team_id=team_id,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    ecosystem_id: str,
    team_id: str | Unset = UNSET,
) -> Error | TeamReachGrantList | None:
    """List the team reach grants INTO one ecosystem

    Args:
        ecosystem_id (str):
        team_id (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | TeamReachGrantList
    """

    return sync_detailed(
        client=client,
        ecosystem_id=ecosystem_id,
        team_id=team_id,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    ecosystem_id: str,
    team_id: str | Unset = UNSET,
) -> Response[Error | TeamReachGrantList]:
    """List the team reach grants INTO one ecosystem

    Args:
        ecosystem_id (str):
        team_id (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | TeamReachGrantList]
    """

    kwargs = _get_kwargs(
        ecosystem_id=ecosystem_id,
        team_id=team_id,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    ecosystem_id: str,
    team_id: str | Unset = UNSET,
) -> Error | TeamReachGrantList | None:
    """List the team reach grants INTO one ecosystem

    Args:
        ecosystem_id (str):
        team_id (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | TeamReachGrantList
    """

    return (
        await asyncio_detailed(
            client=client,
            ecosystem_id=ecosystem_id,
            team_id=team_id,
        )
    ).parsed
