from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.get_customer_transfer_preview_response_200 import (
    GetCustomerTransferPreviewResponse200,
)
from ...types import UNSET, Response


def _get_kwargs(
    *,
    user_ids: str,
    target: str,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["userIds"] = user_ids

    params["target"] = target

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/customer/transfer/preview",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | GetCustomerTransferPreviewResponse200 | None:
    if response.status_code == 200:
        response_200 = GetCustomerTransferPreviewResponse200.from_dict(response.json())

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
) -> Response[Error | GetCustomerTransferPreviewResponse200]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    user_ids: str,
    target: str,
) -> Response[Error | GetCustomerTransferPreviewResponse200]:
    """What would collide if these users moved, without moving them (admin)

    Args:
        user_ids (str):
        target (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GetCustomerTransferPreviewResponse200]
    """

    kwargs = _get_kwargs(
        user_ids=user_ids,
        target=target,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    user_ids: str,
    target: str,
) -> Error | GetCustomerTransferPreviewResponse200 | None:
    """What would collide if these users moved, without moving them (admin)

    Args:
        user_ids (str):
        target (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GetCustomerTransferPreviewResponse200
    """

    return sync_detailed(
        client=client,
        user_ids=user_ids,
        target=target,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    user_ids: str,
    target: str,
) -> Response[Error | GetCustomerTransferPreviewResponse200]:
    """What would collide if these users moved, without moving them (admin)

    Args:
        user_ids (str):
        target (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GetCustomerTransferPreviewResponse200]
    """

    kwargs = _get_kwargs(
        user_ids=user_ids,
        target=target,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    user_ids: str,
    target: str,
) -> Error | GetCustomerTransferPreviewResponse200 | None:
    """What would collide if these users moved, without moving them (admin)

    Args:
        user_ids (str):
        target (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GetCustomerTransferPreviewResponse200
    """

    return (
        await asyncio_detailed(
            client=client,
            user_ids=user_ids,
            target=target,
        )
    ).parsed
