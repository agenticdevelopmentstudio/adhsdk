from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.get_v1_chats_stream_response_200 import GetV1ChatsStreamResponse200
from ...models.stripe_error import StripeError
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    access_token: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["access_token"] = access_token

    json_expand: list[str] | Unset = UNSET
    if not isinstance(expand, Unset):
        json_expand = expand

    params["expand[]"] = json_expand

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/v1/chats/stream",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> GetV1ChatsStreamResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = GetV1ChatsStreamResponse200.from_dict(response.json())

        return response_200

    if response.status_code == 401:
        response_401 = StripeError.from_dict(response.json())

        return response_401

    if response.status_code == 403:
        response_403 = StripeError.from_dict(response.json())

        return response_403

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[GetV1ChatsStreamResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    access_token: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1ChatsStreamResponse200 | StripeError]:
    """Stream live events across all of the caller's chats (SSE)

     Server-Sent Events (`text/event-stream`), multiplexed over every chat the caller has joined — group
    chats, and DMs while the ecosystem's `messaging` flag is on. Each chat event is sent as `event:
    <kind>` with `data: {chatId, ...}`:

    - `message` / `message_updated` `{chatId, seq}` — a message landed / was edited.
    - `typing` `{chatId, participantId, state: start|stop, expiresAt}` — drop the indicator at
    `expiresAt` if no newer event arrives.
    - `chat_updated` `{chatId}` — the chat itself changed.
    - `participants_changed` `{chatId, added, removed}` — participant ids.
    - `resync` `{chatId}` — events may have been missed; refetch that chat.

    Stream-level events: `ready` `{chatIds}` once the subscription is live (refetch after it — earlier
    changes were not streamed), and `chats_changed` `{added, removed}` when the caller joins or leaves a
    chat.

    If the backend was started without a notification hub, the stream emits `ready` and closes
    immediately — poll instead. Otherwise it stays open for at most 5 minutes, with keep-alive comments,
    and closes with no terminal event; reconnect.

    Because a browser `EventSource` cannot set headers, the bearer token may be passed as an
    `access_token` query parameter. Requires the `chat` feature.

    Replaces GET /chat/stream.

    Args:
        access_token (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1ChatsStreamResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        access_token=access_token,
        expand=expand,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    access_token: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> GetV1ChatsStreamResponse200 | StripeError | None:
    """Stream live events across all of the caller's chats (SSE)

     Server-Sent Events (`text/event-stream`), multiplexed over every chat the caller has joined — group
    chats, and DMs while the ecosystem's `messaging` flag is on. Each chat event is sent as `event:
    <kind>` with `data: {chatId, ...}`:

    - `message` / `message_updated` `{chatId, seq}` — a message landed / was edited.
    - `typing` `{chatId, participantId, state: start|stop, expiresAt}` — drop the indicator at
    `expiresAt` if no newer event arrives.
    - `chat_updated` `{chatId}` — the chat itself changed.
    - `participants_changed` `{chatId, added, removed}` — participant ids.
    - `resync` `{chatId}` — events may have been missed; refetch that chat.

    Stream-level events: `ready` `{chatIds}` once the subscription is live (refetch after it — earlier
    changes were not streamed), and `chats_changed` `{added, removed}` when the caller joins or leaves a
    chat.

    If the backend was started without a notification hub, the stream emits `ready` and closes
    immediately — poll instead. Otherwise it stays open for at most 5 minutes, with keep-alive comments,
    and closes with no terminal event; reconnect.

    Because a browser `EventSource` cannot set headers, the bearer token may be passed as an
    `access_token` query parameter. Requires the `chat` feature.

    Replaces GET /chat/stream.

    Args:
        access_token (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1ChatsStreamResponse200 | StripeError
    """

    return sync_detailed(
        client=client,
        access_token=access_token,
        expand=expand,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    access_token: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1ChatsStreamResponse200 | StripeError]:
    """Stream live events across all of the caller's chats (SSE)

     Server-Sent Events (`text/event-stream`), multiplexed over every chat the caller has joined — group
    chats, and DMs while the ecosystem's `messaging` flag is on. Each chat event is sent as `event:
    <kind>` with `data: {chatId, ...}`:

    - `message` / `message_updated` `{chatId, seq}` — a message landed / was edited.
    - `typing` `{chatId, participantId, state: start|stop, expiresAt}` — drop the indicator at
    `expiresAt` if no newer event arrives.
    - `chat_updated` `{chatId}` — the chat itself changed.
    - `participants_changed` `{chatId, added, removed}` — participant ids.
    - `resync` `{chatId}` — events may have been missed; refetch that chat.

    Stream-level events: `ready` `{chatIds}` once the subscription is live (refetch after it — earlier
    changes were not streamed), and `chats_changed` `{added, removed}` when the caller joins or leaves a
    chat.

    If the backend was started without a notification hub, the stream emits `ready` and closes
    immediately — poll instead. Otherwise it stays open for at most 5 minutes, with keep-alive comments,
    and closes with no terminal event; reconnect.

    Because a browser `EventSource` cannot set headers, the bearer token may be passed as an
    `access_token` query parameter. Requires the `chat` feature.

    Replaces GET /chat/stream.

    Args:
        access_token (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1ChatsStreamResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        access_token=access_token,
        expand=expand,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    access_token: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> GetV1ChatsStreamResponse200 | StripeError | None:
    """Stream live events across all of the caller's chats (SSE)

     Server-Sent Events (`text/event-stream`), multiplexed over every chat the caller has joined — group
    chats, and DMs while the ecosystem's `messaging` flag is on. Each chat event is sent as `event:
    <kind>` with `data: {chatId, ...}`:

    - `message` / `message_updated` `{chatId, seq}` — a message landed / was edited.
    - `typing` `{chatId, participantId, state: start|stop, expiresAt}` — drop the indicator at
    `expiresAt` if no newer event arrives.
    - `chat_updated` `{chatId}` — the chat itself changed.
    - `participants_changed` `{chatId, added, removed}` — participant ids.
    - `resync` `{chatId}` — events may have been missed; refetch that chat.

    Stream-level events: `ready` `{chatIds}` once the subscription is live (refetch after it — earlier
    changes were not streamed), and `chats_changed` `{added, removed}` when the caller joins or leaves a
    chat.

    If the backend was started without a notification hub, the stream emits `ready` and closes
    immediately — poll instead. Otherwise it stays open for at most 5 minutes, with keep-alive comments,
    and closes with no terminal event; reconnect.

    Because a browser `EventSource` cannot set headers, the bearer token may be passed as an
    `access_token` query parameter. Requires the `chat` feature.

    Replaces GET /chat/stream.

    Args:
        access_token (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1ChatsStreamResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            client=client,
            access_token=access_token,
            expand=expand,
        )
    ).parsed
