from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.get_v1_chats_by_id_messages_response_200 import GetV1ChatsByIdMessagesResponse200
from ...models.stripe_error import StripeError
from ...types import UNSET, Response, Unset


def _get_kwargs(
    id: str,
    *,
    after: int | Unset = UNSET,
    limit: int | Unset = 10,
    starting_after: str | Unset = UNSET,
    ending_before: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["after"] = after

    params["limit"] = limit

    params["starting_after"] = starting_after

    params["ending_before"] = ending_before

    json_expand: list[str] | Unset = UNSET
    if not isinstance(expand, Unset):
        json_expand = expand

    params["expand[]"] = json_expand

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/v1/chats/{id}/messages".format(
            id=quote(str(id), safe=""),
        ),
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> GetV1ChatsByIdMessagesResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = GetV1ChatsByIdMessagesResponse200.from_dict(response.json())

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
) -> Response[GetV1ChatsByIdMessagesResponse200 | StripeError]:
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
    limit: int | Unset = 10,
    starting_after: str | Unset = UNSET,
    ending_before: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1ChatsByIdMessagesResponse200 | StripeError]:
    """List messages in a chat, ascending by seq

     With `after`, the oldest `limit` messages whose `seq` is greater — the catch-up read a live client
    runs on a `message` event. Without it, the newest `limit` messages. Only user and assistant text is
    listed: a persona’s tool traffic is stored but never shown, previewed or counted unread.

    Replaces GET /chat/chats/{id}/messages, GET /chat/dms/{chatId}/messages.

    Args:
        id (str):
        after (int | Unset):
        limit (int | Unset):  Default: 10.
        starting_after (str | Unset):
        ending_before (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1ChatsByIdMessagesResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
        after=after,
        limit=limit,
        starting_after=starting_after,
        ending_before=ending_before,
        expand=expand,
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
    limit: int | Unset = 10,
    starting_after: str | Unset = UNSET,
    ending_before: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> GetV1ChatsByIdMessagesResponse200 | StripeError | None:
    """List messages in a chat, ascending by seq

     With `after`, the oldest `limit` messages whose `seq` is greater — the catch-up read a live client
    runs on a `message` event. Without it, the newest `limit` messages. Only user and assistant text is
    listed: a persona’s tool traffic is stored but never shown, previewed or counted unread.

    Replaces GET /chat/chats/{id}/messages, GET /chat/dms/{chatId}/messages.

    Args:
        id (str):
        after (int | Unset):
        limit (int | Unset):  Default: 10.
        starting_after (str | Unset):
        ending_before (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1ChatsByIdMessagesResponse200 | StripeError
    """

    return sync_detailed(
        id=id,
        client=client,
        after=after,
        limit=limit,
        starting_after=starting_after,
        ending_before=ending_before,
        expand=expand,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
    after: int | Unset = UNSET,
    limit: int | Unset = 10,
    starting_after: str | Unset = UNSET,
    ending_before: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1ChatsByIdMessagesResponse200 | StripeError]:
    """List messages in a chat, ascending by seq

     With `after`, the oldest `limit` messages whose `seq` is greater — the catch-up read a live client
    runs on a `message` event. Without it, the newest `limit` messages. Only user and assistant text is
    listed: a persona’s tool traffic is stored but never shown, previewed or counted unread.

    Replaces GET /chat/chats/{id}/messages, GET /chat/dms/{chatId}/messages.

    Args:
        id (str):
        after (int | Unset):
        limit (int | Unset):  Default: 10.
        starting_after (str | Unset):
        ending_before (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1ChatsByIdMessagesResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
        after=after,
        limit=limit,
        starting_after=starting_after,
        ending_before=ending_before,
        expand=expand,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    *,
    client: AuthenticatedClient,
    after: int | Unset = UNSET,
    limit: int | Unset = 10,
    starting_after: str | Unset = UNSET,
    ending_before: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> GetV1ChatsByIdMessagesResponse200 | StripeError | None:
    """List messages in a chat, ascending by seq

     With `after`, the oldest `limit` messages whose `seq` is greater — the catch-up read a live client
    runs on a `message` event. Without it, the newest `limit` messages. Only user and assistant text is
    listed: a persona’s tool traffic is stored but never shown, previewed or counted unread.

    Replaces GET /chat/chats/{id}/messages, GET /chat/dms/{chatId}/messages.

    Args:
        id (str):
        after (int | Unset):
        limit (int | Unset):  Default: 10.
        starting_after (str | Unset):
        ending_before (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1ChatsByIdMessagesResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            after=after,
            limit=limit,
            starting_after=starting_after,
            ending_before=ending_before,
            expand=expand,
        )
    ).parsed
