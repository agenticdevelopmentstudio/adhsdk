from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.post_public_invitations_response_200 import PostPublicInvitationsResponse200
from ...models.public_invitation_request import PublicInvitationRequest
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    body: PublicInvitationRequest | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/public/invitations",
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | PostPublicInvitationsResponse200 | None:
    if response.status_code == 200:
        response_200 = PostPublicInvitationsResponse200.from_dict(response.json())

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
) -> Response[Error | PostPublicInvitationsResponse200]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient | Client,
    body: PublicInvitationRequest | Unset = UNSET,
) -> Response[Error | PostPublicInvitationsResponse200]:
    """Request to join an ecosystem (unauthenticated). Optionally addressed by ecosystem rdid/uuid;
    defaults to the hub.

    Args:
        body (PublicInvitationRequest | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PostPublicInvitationsResponse200]
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
    client: AuthenticatedClient | Client,
    body: PublicInvitationRequest | Unset = UNSET,
) -> Error | PostPublicInvitationsResponse200 | None:
    """Request to join an ecosystem (unauthenticated). Optionally addressed by ecosystem rdid/uuid;
    defaults to the hub.

    Args:
        body (PublicInvitationRequest | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PostPublicInvitationsResponse200
    """

    return sync_detailed(
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient | Client,
    body: PublicInvitationRequest | Unset = UNSET,
) -> Response[Error | PostPublicInvitationsResponse200]:
    """Request to join an ecosystem (unauthenticated). Optionally addressed by ecosystem rdid/uuid;
    defaults to the hub.

    Args:
        body (PublicInvitationRequest | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PostPublicInvitationsResponse200]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient | Client,
    body: PublicInvitationRequest | Unset = UNSET,
) -> Error | PostPublicInvitationsResponse200 | None:
    """Request to join an ecosystem (unauthenticated). Optionally addressed by ecosystem rdid/uuid;
    defaults to the hub.

    Args:
        body (PublicInvitationRequest | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PostPublicInvitationsResponse200
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
        )
    ).parsed
