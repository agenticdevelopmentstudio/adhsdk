from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.friendship import Friendship
from ...models.post_friends_requests_body import PostFriendsRequestsBody
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    body: PostFriendsRequestsBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/friends/requests",
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | Friendship | None:
    if response.status_code == 200:
        response_200 = Friendship.from_dict(response.json())

        return response_200

    if response.status_code == 201:
        response_201 = Friendship.from_dict(response.json())

        return response_201

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

    if response.status_code == 409:
        response_409 = Error.from_dict(response.json())

        return response_409

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | Friendship]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    body: PostFriendsRequestsBody | Unset = UNSET,
) -> Response[Error | Friendship]:
    """Send a friend request (idempotent on the unordered pair; mutual → auto-accept)

     Creates a pending friendship with the caller as requester. If an edge for the unordered pair already
    exists in either direction no second row is created: a pending request FROM the other user is auto-
    accepted (both sides asked), a pending request from the caller or an accepted friendship is returned
    as-is, and a declined edge flips back to pending with the caller as requester. Refused (403) while a
    block exists in either direction between the two users.

    Args:
        body (PostFriendsRequestsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | Friendship]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    body: PostFriendsRequestsBody | Unset = UNSET,
) -> Error | Friendship | None:
    """Send a friend request (idempotent on the unordered pair; mutual → auto-accept)

     Creates a pending friendship with the caller as requester. If an edge for the unordered pair already
    exists in either direction no second row is created: a pending request FROM the other user is auto-
    accepted (both sides asked), a pending request from the caller or an accepted friendship is returned
    as-is, and a declined edge flips back to pending with the caller as requester. Refused (403) while a
    block exists in either direction between the two users.

    Args:
        body (PostFriendsRequestsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | Friendship
    """

    return sync_detailed(
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    body: PostFriendsRequestsBody | Unset = UNSET,
) -> Response[Error | Friendship]:
    """Send a friend request (idempotent on the unordered pair; mutual → auto-accept)

     Creates a pending friendship with the caller as requester. If an edge for the unordered pair already
    exists in either direction no second row is created: a pending request FROM the other user is auto-
    accepted (both sides asked), a pending request from the caller or an accepted friendship is returned
    as-is, and a declined edge flips back to pending with the caller as requester. Refused (403) while a
    block exists in either direction between the two users.

    Args:
        body (PostFriendsRequestsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | Friendship]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    body: PostFriendsRequestsBody | Unset = UNSET,
) -> Error | Friendship | None:
    """Send a friend request (idempotent on the unordered pair; mutual → auto-accept)

     Creates a pending friendship with the caller as requester. If an edge for the unordered pair already
    exists in either direction no second row is created: a pending request FROM the other user is auto-
    accepted (both sides asked), a pending request from the caller or an accepted friendship is returned
    as-is, and a declined edge flips back to pending with the caller as requester. Refused (403) while a
    block exists in either direction between the two users.

    Args:
        body (PostFriendsRequestsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | Friendship
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
        )
    ).parsed
