from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.chat_message_list import ChatMessageList
from ...models.error import Error
from ...types import UNSET, Response, Unset


def _get_kwargs(
    id: str,
    *,
    after: int | Unset = UNSET,
    limit: int | Unset = 50,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["after"] = after

    params["limit"] = limit

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/chat/chats/{id}/messages".format(
            id=quote(str(id), safe=""),
        ),
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> ChatMessageList | Error | None:
    if response.status_code == 200:
        response_200 = ChatMessageList.from_dict(response.json())

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
) -> Response[ChatMessageList | Error]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
    after: int | Unset = UNSET,
    limit: int | Unset = 50,
) -> Response[ChatMessageList | Error]:
    """List messages in a chat, ascending by seq

     With `after`, the oldest `limit` messages whose `seq` is greater — the catch-up read a live client
    runs on a `message` event. Without it, the newest `limit` messages. Only user and assistant text is
    listed: a persona’s tool traffic is stored but never shown, previewed or counted unread.

    Args:
        id (str):
        after (int | Unset):
        limit (int | Unset):  Default: 50.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[ChatMessageList | Error]
    """

    kwargs = _get_kwargs(
        id=id,
        after=after,
        limit=limit,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    *,
    client: AuthenticatedClient,
    after: int | Unset = UNSET,
    limit: int | Unset = 50,
) -> ChatMessageList | Error | None:
    """List messages in a chat, ascending by seq

     With `after`, the oldest `limit` messages whose `seq` is greater — the catch-up read a live client
    runs on a `message` event. Without it, the newest `limit` messages. Only user and assistant text is
    listed: a persona’s tool traffic is stored but never shown, previewed or counted unread.

    Args:
        id (str):
        after (int | Unset):
        limit (int | Unset):  Default: 50.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        ChatMessageList | Error
    """

    return sync_detailed(
        id=id,
        client=client,
        after=after,
        limit=limit,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
    after: int | Unset = UNSET,
    limit: int | Unset = 50,
) -> Response[ChatMessageList | Error]:
    """List messages in a chat, ascending by seq

     With `after`, the oldest `limit` messages whose `seq` is greater — the catch-up read a live client
    runs on a `message` event. Without it, the newest `limit` messages. Only user and assistant text is
    listed: a persona’s tool traffic is stored but never shown, previewed or counted unread.

    Args:
        id (str):
        after (int | Unset):
        limit (int | Unset):  Default: 50.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[ChatMessageList | Error]
    """

    kwargs = _get_kwargs(
        id=id,
        after=after,
        limit=limit,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    *,
    client: AuthenticatedClient,
    after: int | Unset = UNSET,
    limit: int | Unset = 50,
) -> ChatMessageList | Error | None:
    """List messages in a chat, ascending by seq

     With `after`, the oldest `limit` messages whose `seq` is greater — the catch-up read a live client
    runs on a `message` event. Without it, the newest `limit` messages. Only user and assistant text is
    listed: a persona’s tool traffic is stored but never shown, previewed or counted unread.

    Args:
        id (str):
        after (int | Unset):
        limit (int | Unset):  Default: 50.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        ChatMessageList | Error
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            after=after,
            limit=limit,
        )
    ).parsed
