from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.post_v1_access_items_restore_body import PostV1AccessItemsRestoreBody
from ...models.post_v1_access_items_restore_response_200 import PostV1AccessItemsRestoreResponse200
from ...models.stripe_error import StripeError
from ...types import UNSET, Response


def _get_kwargs(
    *,
    body: PostV1AccessItemsRestoreBody,
    workspace: str,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    params: dict[str, Any] = {}

    params["workspace"] = workspace

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/access/items/restore",
        "params": params,
    }

    _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostV1AccessItemsRestoreResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = PostV1AccessItemsRestoreResponse200.from_dict(response.json())

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

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[PostV1AccessItemsRestoreResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    body: PostV1AccessItemsRestoreBody,
    workspace: str,
) -> Response[PostV1AccessItemsRestoreResponse200 | StripeError]:
    """Restore an item to inherited access (deletes its restriction row)

     Replaces POST /access/items/restore.

    Args:
        workspace (str):
        body (PostV1AccessItemsRestoreBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1AccessItemsRestoreResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        body=body,
        workspace=workspace,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    body: PostV1AccessItemsRestoreBody,
    workspace: str,
) -> PostV1AccessItemsRestoreResponse200 | StripeError | None:
    """Restore an item to inherited access (deletes its restriction row)

     Replaces POST /access/items/restore.

    Args:
        workspace (str):
        body (PostV1AccessItemsRestoreBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1AccessItemsRestoreResponse200 | StripeError
    """

    return sync_detailed(
        client=client,
        body=body,
        workspace=workspace,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    body: PostV1AccessItemsRestoreBody,
    workspace: str,
) -> Response[PostV1AccessItemsRestoreResponse200 | StripeError]:
    """Restore an item to inherited access (deletes its restriction row)

     Replaces POST /access/items/restore.

    Args:
        workspace (str):
        body (PostV1AccessItemsRestoreBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1AccessItemsRestoreResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        body=body,
        workspace=workspace,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    body: PostV1AccessItemsRestoreBody,
    workspace: str,
) -> PostV1AccessItemsRestoreResponse200 | StripeError | None:
    """Restore an item to inherited access (deletes its restriction row)

     Replaces POST /access/items/restore.

    Args:
        workspace (str):
        body (PostV1AccessItemsRestoreBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1AccessItemsRestoreResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
            workspace=workspace,
        )
    ).parsed
