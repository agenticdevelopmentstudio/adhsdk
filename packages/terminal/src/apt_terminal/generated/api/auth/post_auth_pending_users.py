from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.add_pending_users_body import AddPendingUsersBody
from ...models.error import Error
from ...models.pending_user import PendingUser
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    body: AddPendingUsersBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/auth/pending-users",
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | list[PendingUser] | None:
    if response.status_code == 201:
        response_201 = []
        _response_201 = response.json()
        for response_201_item_data in _response_201:
            response_201_item = PendingUser.from_dict(response_201_item_data)

            response_201.append(response_201_item)

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

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | list[PendingUser]]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    body: AddPendingUsersBody | Unset = UNSET,
) -> Response[Error | list[PendingUser]]:
    """Add people to the pending list

     Adds one or more people without inviting them — sending is a separate step (POST /auth/invitations).
    Each gets the next `userNumber` for the ecosystem.

    Args:
        body (AddPendingUsersBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | list[PendingUser]]
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
    body: AddPendingUsersBody | Unset = UNSET,
) -> Error | list[PendingUser] | None:
    """Add people to the pending list

     Adds one or more people without inviting them — sending is a separate step (POST /auth/invitations).
    Each gets the next `userNumber` for the ecosystem.

    Args:
        body (AddPendingUsersBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | list[PendingUser]
    """

    return sync_detailed(
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    body: AddPendingUsersBody | Unset = UNSET,
) -> Response[Error | list[PendingUser]]:
    """Add people to the pending list

     Adds one or more people without inviting them — sending is a separate step (POST /auth/invitations).
    Each gets the next `userNumber` for the ecosystem.

    Args:
        body (AddPendingUsersBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | list[PendingUser]]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    body: AddPendingUsersBody | Unset = UNSET,
) -> Error | list[PendingUser] | None:
    """Add people to the pending list

     Adds one or more people without inviting them — sending is a separate step (POST /auth/invitations).
    Each gets the next `userNumber` for the ecosystem.

    Args:
        body (AddPendingUsersBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | list[PendingUser]
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
        )
    ).parsed
