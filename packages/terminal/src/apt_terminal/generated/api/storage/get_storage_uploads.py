from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.storage_attachment import StorageAttachment
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    parent_type: str | Unset = UNSET,
    parent_id: str | Unset = UNSET,
    owner_type: str | Unset = UNSET,
    owner_id: str | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["parentType"] = parent_type

    params["parentId"] = parent_id

    params["ownerType"] = owner_type

    params["ownerId"] = owner_id

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/storage/uploads",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | list[StorageAttachment] | None:
    if response.status_code == 200:
        response_200 = []
        _response_200 = response.json()
        for response_200_item_data in _response_200:
            response_200_item = StorageAttachment.from_dict(response_200_item_data)

            response_200.append(response_200_item)

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
) -> Response[Error | list[StorageAttachment]]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    parent_type: str | Unset = UNSET,
    parent_id: str | Unset = UNSET,
    owner_type: str | Unset = UNSET,
    owner_id: str | Unset = UNSET,
) -> Response[Error | list[StorageAttachment]]:
    """List the caller's attachments (newest first)

    Args:
        parent_type (str | Unset):
        parent_id (str | Unset):
        owner_type (str | Unset):
        owner_id (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | list[StorageAttachment]]
    """

    kwargs = _get_kwargs(
        parent_type=parent_type,
        parent_id=parent_id,
        owner_type=owner_type,
        owner_id=owner_id,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    parent_type: str | Unset = UNSET,
    parent_id: str | Unset = UNSET,
    owner_type: str | Unset = UNSET,
    owner_id: str | Unset = UNSET,
) -> Error | list[StorageAttachment] | None:
    """List the caller's attachments (newest first)

    Args:
        parent_type (str | Unset):
        parent_id (str | Unset):
        owner_type (str | Unset):
        owner_id (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | list[StorageAttachment]
    """

    return sync_detailed(
        client=client,
        parent_type=parent_type,
        parent_id=parent_id,
        owner_type=owner_type,
        owner_id=owner_id,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    parent_type: str | Unset = UNSET,
    parent_id: str | Unset = UNSET,
    owner_type: str | Unset = UNSET,
    owner_id: str | Unset = UNSET,
) -> Response[Error | list[StorageAttachment]]:
    """List the caller's attachments (newest first)

    Args:
        parent_type (str | Unset):
        parent_id (str | Unset):
        owner_type (str | Unset):
        owner_id (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | list[StorageAttachment]]
    """

    kwargs = _get_kwargs(
        parent_type=parent_type,
        parent_id=parent_id,
        owner_type=owner_type,
        owner_id=owner_id,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    parent_type: str | Unset = UNSET,
    parent_id: str | Unset = UNSET,
    owner_type: str | Unset = UNSET,
    owner_id: str | Unset = UNSET,
) -> Error | list[StorageAttachment] | None:
    """List the caller's attachments (newest first)

    Args:
        parent_type (str | Unset):
        parent_id (str | Unset):
        owner_type (str | Unset):
        owner_id (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | list[StorageAttachment]
    """

    return (
        await asyncio_detailed(
            client=client,
            parent_type=parent_type,
            parent_id=parent_id,
            owner_type=owner_type,
            owner_id=owner_id,
        )
    ).parsed
