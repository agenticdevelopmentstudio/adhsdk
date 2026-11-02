from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.get_friends_requests_direction import GetFriendsRequestsDirection
from ...models.get_friends_requests_response_200 import GetFriendsRequestsResponse200
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    direction: GetFriendsRequestsDirection | Unset = GetFriendsRequestsDirection.RECEIVED,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    json_direction: str | Unset = UNSET
    if not isinstance(direction, Unset):
        json_direction = direction.value

    params["direction"] = json_direction

    params["page"] = page

    params["pageSize"] = page_size

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/friends/requests",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | GetFriendsRequestsResponse200 | None:
    if response.status_code == 200:
        response_200 = GetFriendsRequestsResponse200.from_dict(response.json())

        return response_200

    if response.status_code == 400:
        response_400 = Error.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = Error.from_dict(response.json())

        return response_401

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | GetFriendsRequestsResponse200]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    direction: GetFriendsRequestsDirection | Unset = GetFriendsRequestsDirection.RECEIVED,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
) -> Response[Error | GetFriendsRequestsResponse200]:
    """Pending friend requests — ?direction=received (default, the caller's inbox) | sent

    Args:
        direction (GetFriendsRequestsDirection | Unset):  Default:
            GetFriendsRequestsDirection.RECEIVED.
        page (str | Unset):
        page_size (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GetFriendsRequestsResponse200]
    """

    kwargs = _get_kwargs(
        direction=direction,
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
    direction: GetFriendsRequestsDirection | Unset = GetFriendsRequestsDirection.RECEIVED,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
) -> Error | GetFriendsRequestsResponse200 | None:
    """Pending friend requests — ?direction=received (default, the caller's inbox) | sent

    Args:
        direction (GetFriendsRequestsDirection | Unset):  Default:
            GetFriendsRequestsDirection.RECEIVED.
        page (str | Unset):
        page_size (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GetFriendsRequestsResponse200
    """

    return sync_detailed(
        client=client,
        direction=direction,
        page=page,
        page_size=page_size,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    direction: GetFriendsRequestsDirection | Unset = GetFriendsRequestsDirection.RECEIVED,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
) -> Response[Error | GetFriendsRequestsResponse200]:
    """Pending friend requests — ?direction=received (default, the caller's inbox) | sent

    Args:
        direction (GetFriendsRequestsDirection | Unset):  Default:
            GetFriendsRequestsDirection.RECEIVED.
        page (str | Unset):
        page_size (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GetFriendsRequestsResponse200]
    """

    kwargs = _get_kwargs(
        direction=direction,
        page=page,
        page_size=page_size,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    direction: GetFriendsRequestsDirection | Unset = GetFriendsRequestsDirection.RECEIVED,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
) -> Error | GetFriendsRequestsResponse200 | None:
    """Pending friend requests — ?direction=received (default, the caller's inbox) | sent

    Args:
        direction (GetFriendsRequestsDirection | Unset):  Default:
            GetFriendsRequestsDirection.RECEIVED.
        page (str | Unset):
        page_size (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GetFriendsRequestsResponse200
    """

    return (
        await asyncio_detailed(
            client=client,
            direction=direction,
            page=page,
            page_size=page_size,
        )
    ).parsed
