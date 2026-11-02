from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.dm_read_request import DmReadRequest
from ...models.dm_read_result import DmReadResult
from ...models.error import Error
from ...types import UNSET, Response, Unset


def _get_kwargs(
    chat_id: str,
    *,
    body: DmReadRequest | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/chat/dms/{chat_id}/read".format(
            chat_id=quote(str(chat_id), safe=""),
        ),
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> DmReadResult | Error | None:
    if response.status_code == 200:
        response_200 = DmReadResult.from_dict(response.json())

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
) -> Response[DmReadResult | Error]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    chat_id: str,
    *,
    client: AuthenticatedClient,
    body: DmReadRequest | Unset = UNSET,
) -> Response[DmReadResult | Error]:
    """Mark a DM chat read up to a message

     Marks the chat read through `messageId`. Omit it — or name a message that is not this chat's — to
    mark the latest message read, which always leaves `unreadCount` 0.

    Args:
        chat_id (str):
        body (DmReadRequest | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[DmReadResult | Error]
    """

    kwargs = _get_kwargs(
        chat_id=chat_id,
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    chat_id: str,
    *,
    client: AuthenticatedClient,
    body: DmReadRequest | Unset = UNSET,
) -> DmReadResult | Error | None:
    """Mark a DM chat read up to a message

     Marks the chat read through `messageId`. Omit it — or name a message that is not this chat's — to
    mark the latest message read, which always leaves `unreadCount` 0.

    Args:
        chat_id (str):
        body (DmReadRequest | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        DmReadResult | Error
    """

    return sync_detailed(
        chat_id=chat_id,
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    chat_id: str,
    *,
    client: AuthenticatedClient,
    body: DmReadRequest | Unset = UNSET,
) -> Response[DmReadResult | Error]:
    """Mark a DM chat read up to a message

     Marks the chat read through `messageId`. Omit it — or name a message that is not this chat's — to
    mark the latest message read, which always leaves `unreadCount` 0.

    Args:
        chat_id (str):
        body (DmReadRequest | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[DmReadResult | Error]
    """

    kwargs = _get_kwargs(
        chat_id=chat_id,
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    chat_id: str,
    *,
    client: AuthenticatedClient,
    body: DmReadRequest | Unset = UNSET,
) -> DmReadResult | Error | None:
    """Mark a DM chat read up to a message

     Marks the chat read through `messageId`. Omit it — or name a message that is not this chat's — to
    mark the latest message read, which always leaves `unreadCount` 0.

    Args:
        chat_id (str):
        body (DmReadRequest | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        DmReadResult | Error
    """

    return (
        await asyncio_detailed(
            chat_id=chat_id,
            client=client,
            body=body,
        )
    ).parsed
