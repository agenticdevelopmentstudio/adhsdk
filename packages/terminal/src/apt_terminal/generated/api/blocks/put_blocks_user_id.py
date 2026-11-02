from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.user_block import UserBlock
from ...types import Response


def _get_kwargs(
    user_id: str,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "put",
        "url": "/blocks/{user_id}".format(
            user_id=quote(str(user_id), safe=""),
        ),
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | UserBlock | None:
    if response.status_code == 200:
        response_200 = UserBlock.from_dict(response.json())

        return response_200

    if response.status_code == 201:
        response_201 = UserBlock.from_dict(response.json())

        return response_201

    if response.status_code == 400:
        response_400 = Error.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = Error.from_dict(response.json())

        return response_401

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
) -> Response[Error | UserBlock]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    user_id: str,
    *,
    client: AuthenticatedClient,
) -> Response[Error | UserBlock]:
    """Block a user (idempotent; severs any friendship between the pair)

     Creates the caller→user block. Blocking removes any existing friendship or pending request between
    the two users in the same transaction, and new friend requests are refused (403) while a block
    exists in either direction. Follows are untouched — they carry no permission weight. Idempotent —
    repeating the call returns the existing block (200) instead of creating a second row.

    Args:
        user_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | UserBlock]
    """

    kwargs = _get_kwargs(
        user_id=user_id,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    user_id: str,
    *,
    client: AuthenticatedClient,
) -> Error | UserBlock | None:
    """Block a user (idempotent; severs any friendship between the pair)

     Creates the caller→user block. Blocking removes any existing friendship or pending request between
    the two users in the same transaction, and new friend requests are refused (403) while a block
    exists in either direction. Follows are untouched — they carry no permission weight. Idempotent —
    repeating the call returns the existing block (200) instead of creating a second row.

    Args:
        user_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | UserBlock
    """

    return sync_detailed(
        user_id=user_id,
        client=client,
    ).parsed


async def asyncio_detailed(
    user_id: str,
    *,
    client: AuthenticatedClient,
) -> Response[Error | UserBlock]:
    """Block a user (idempotent; severs any friendship between the pair)

     Creates the caller→user block. Blocking removes any existing friendship or pending request between
    the two users in the same transaction, and new friend requests are refused (403) while a block
    exists in either direction. Follows are untouched — they carry no permission weight. Idempotent —
    repeating the call returns the existing block (200) instead of creating a second row.

    Args:
        user_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | UserBlock]
    """

    kwargs = _get_kwargs(
        user_id=user_id,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    user_id: str,
    *,
    client: AuthenticatedClient,
) -> Error | UserBlock | None:
    """Block a user (idempotent; severs any friendship between the pair)

     Creates the caller→user block. Blocking removes any existing friendship or pending request between
    the two users in the same transaction, and new friend requests are refused (403) while a block
    exists in either direction. Follows are untouched — they carry no permission weight. Idempotent —
    repeating the call returns the existing block (200) instead of creating a second row.

    Args:
        user_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | UserBlock
    """

    return (
        await asyncio_detailed(
            user_id=user_id,
            client=client,
        )
    ).parsed
