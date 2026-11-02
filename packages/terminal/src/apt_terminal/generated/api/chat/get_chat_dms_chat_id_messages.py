from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.dm_message_list import DmMessageList
from ...models.error import Error
from ...types import UNSET, Response, Unset


def _get_kwargs(
    chat_id: str,
    *,
    page: int | Unset = 1,
    page_size: int | Unset = 50,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["page"] = page

    params["pageSize"] = page_size

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/chat/dms/{chat_id}/messages".format(
            chat_id=quote(str(chat_id), safe=""),
        ),
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> DmMessageList | Error | None:
    if response.status_code == 200:
        response_200 = DmMessageList.from_dict(response.json())

        return response_200

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
) -> Response[DmMessageList | Error]:
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
    page: int | Unset = 1,
    page_size: int | Unset = 50,
) -> Response[DmMessageList | Error]:
    """List the messages in a DM chat, oldest first

     Paginates from the newest end — page 1 is the most recent window — but returns each page in
    ascending `seq` order. 404 (not 403) when the caller is not a participant, so a chat id cannot be
    probed for existence.

    Args:
        chat_id (str):
        page (int | Unset):  Default: 1.
        page_size (int | Unset):  Default: 50.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[DmMessageList | Error]
    """

    kwargs = _get_kwargs(
        chat_id=chat_id,
        page=page,
        page_size=page_size,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    chat_id: str,
    *,
    client: AuthenticatedClient,
    page: int | Unset = 1,
    page_size: int | Unset = 50,
) -> DmMessageList | Error | None:
    """List the messages in a DM chat, oldest first

     Paginates from the newest end — page 1 is the most recent window — but returns each page in
    ascending `seq` order. 404 (not 403) when the caller is not a participant, so a chat id cannot be
    probed for existence.

    Args:
        chat_id (str):
        page (int | Unset):  Default: 1.
        page_size (int | Unset):  Default: 50.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        DmMessageList | Error
    """

    return sync_detailed(
        chat_id=chat_id,
        client=client,
        page=page,
        page_size=page_size,
    ).parsed


async def asyncio_detailed(
    chat_id: str,
    *,
    client: AuthenticatedClient,
    page: int | Unset = 1,
    page_size: int | Unset = 50,
) -> Response[DmMessageList | Error]:
    """List the messages in a DM chat, oldest first

     Paginates from the newest end — page 1 is the most recent window — but returns each page in
    ascending `seq` order. 404 (not 403) when the caller is not a participant, so a chat id cannot be
    probed for existence.

    Args:
        chat_id (str):
        page (int | Unset):  Default: 1.
        page_size (int | Unset):  Default: 50.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[DmMessageList | Error]
    """

    kwargs = _get_kwargs(
        chat_id=chat_id,
        page=page,
        page_size=page_size,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    chat_id: str,
    *,
    client: AuthenticatedClient,
    page: int | Unset = 1,
    page_size: int | Unset = 50,
) -> DmMessageList | Error | None:
    """List the messages in a DM chat, oldest first

     Paginates from the newest end — page 1 is the most recent window — but returns each page in
    ascending `seq` order. 404 (not 403) when the caller is not a participant, so a chat id cannot be
    probed for existence.

    Args:
        chat_id (str):
        page (int | Unset):  Default: 1.
        page_size (int | Unset):  Default: 50.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        DmMessageList | Error
    """

    return (
        await asyncio_detailed(
            chat_id=chat_id,
            client=client,
            page=page,
            page_size=page_size,
        )
    ).parsed
