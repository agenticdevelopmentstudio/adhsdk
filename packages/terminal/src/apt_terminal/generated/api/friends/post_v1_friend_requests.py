from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.post_v1_friend_requests_body import PostV1FriendRequestsBody
from ...models.post_v1_friend_requests_response_200 import PostV1FriendRequestsResponse200
from ...models.stripe_error import StripeError
from ...types import Response


def _get_kwargs(
    *,
    body: PostV1FriendRequestsBody,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/friend_requests",
    }

    _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostV1FriendRequestsResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = PostV1FriendRequestsResponse200.from_dict(response.json())

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

    if response.status_code == 409:
        response_409 = StripeError.from_dict(response.json())

        return response_409

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[PostV1FriendRequestsResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    body: PostV1FriendRequestsBody,
) -> Response[PostV1FriendRequestsResponse200 | StripeError]:
    """Send a friend request (idempotent on the unordered pair; mutual → auto-accept)

     Creates a pending friendship with the caller as requester. If an edge for the unordered pair already
    exists in either direction no second row is created: a pending request FROM the other user is auto-
    accepted (both sides asked), a pending request from the caller or an accepted friendship is returned
    as-is, and a declined edge flips back to pending with the caller as requester. Refused (403) while a
    block exists in either direction between the two users.

    Replaces POST /friends/requests.

    Args:
        body (PostV1FriendRequestsBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1FriendRequestsResponse200 | StripeError]
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
    body: PostV1FriendRequestsBody,
) -> PostV1FriendRequestsResponse200 | StripeError | None:
    """Send a friend request (idempotent on the unordered pair; mutual → auto-accept)

     Creates a pending friendship with the caller as requester. If an edge for the unordered pair already
    exists in either direction no second row is created: a pending request FROM the other user is auto-
    accepted (both sides asked), a pending request from the caller or an accepted friendship is returned
    as-is, and a declined edge flips back to pending with the caller as requester. Refused (403) while a
    block exists in either direction between the two users.

    Replaces POST /friends/requests.

    Args:
        body (PostV1FriendRequestsBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1FriendRequestsResponse200 | StripeError
    """

    return sync_detailed(
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    body: PostV1FriendRequestsBody,
) -> Response[PostV1FriendRequestsResponse200 | StripeError]:
    """Send a friend request (idempotent on the unordered pair; mutual → auto-accept)

     Creates a pending friendship with the caller as requester. If an edge for the unordered pair already
    exists in either direction no second row is created: a pending request FROM the other user is auto-
    accepted (both sides asked), a pending request from the caller or an accepted friendship is returned
    as-is, and a declined edge flips back to pending with the caller as requester. Refused (403) while a
    block exists in either direction between the two users.

    Replaces POST /friends/requests.

    Args:
        body (PostV1FriendRequestsBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1FriendRequestsResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    body: PostV1FriendRequestsBody,
) -> PostV1FriendRequestsResponse200 | StripeError | None:
    """Send a friend request (idempotent on the unordered pair; mutual → auto-accept)

     Creates a pending friendship with the caller as requester. If an edge for the unordered pair already
    exists in either direction no second row is created: a pending request FROM the other user is auto-
    accepted (both sides asked), a pending request from the caller or an accepted friendship is returned
    as-is, and a declined edge flips back to pending with the caller as requester. Refused (403) while a
    block exists in either direction between the two users.

    Replaces POST /friends/requests.

    Args:
        body (PostV1FriendRequestsBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1FriendRequestsResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
        )
    ).parsed
