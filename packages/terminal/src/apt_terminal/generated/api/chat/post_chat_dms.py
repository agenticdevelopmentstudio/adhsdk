from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.dm_create_request import DmCreateRequest
from ...models.dm_create_result import DmCreateResult
from ...models.error import Error
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    body: DmCreateRequest | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/chat/dms",
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> DmCreateResult | Error | None:
    if response.status_code == 200:
        response_200 = DmCreateResult.from_dict(response.json())

        return response_200

    if response.status_code == 201:
        response_201 = DmCreateResult.from_dict(response.json())

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
) -> Response[DmCreateResult | Error]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    body: DmCreateRequest | Unset = UNSET,
) -> Response[DmCreateResult | Error]:
    """Open (or reuse) a DM chat with another user

     Idempotent per user pair: 201 when a chat was created, 200 when one already existed. 403 when the
    recipient cannot be contacted (a block, or a privacy setting).

    Args:
        body (DmCreateRequest | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[DmCreateResult | Error]
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
    body: DmCreateRequest | Unset = UNSET,
) -> DmCreateResult | Error | None:
    """Open (or reuse) a DM chat with another user

     Idempotent per user pair: 201 when a chat was created, 200 when one already existed. 403 when the
    recipient cannot be contacted (a block, or a privacy setting).

    Args:
        body (DmCreateRequest | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        DmCreateResult | Error
    """

    return sync_detailed(
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    body: DmCreateRequest | Unset = UNSET,
) -> Response[DmCreateResult | Error]:
    """Open (or reuse) a DM chat with another user

     Idempotent per user pair: 201 when a chat was created, 200 when one already existed. 403 when the
    recipient cannot be contacted (a block, or a privacy setting).

    Args:
        body (DmCreateRequest | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[DmCreateResult | Error]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    body: DmCreateRequest | Unset = UNSET,
) -> DmCreateResult | Error | None:
    """Open (or reuse) a DM chat with another user

     Idempotent per user pair: 201 when a chat was created, 200 when one already existed. 403 when the
    recipient cannot be contacted (a block, or a privacy setting).

    Args:
        body (DmCreateRequest | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        DmCreateResult | Error
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
        )
    ).parsed
