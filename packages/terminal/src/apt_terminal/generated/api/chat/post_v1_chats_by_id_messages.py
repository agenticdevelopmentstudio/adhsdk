from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.chat_send_message import ChatSendMessage
from ...models.dm_send_message import DmSendMessage
from ...models.post_v1_chats_by_id_messages_response_200 import PostV1ChatsByIdMessagesResponse200
from ...models.stripe_error import StripeError
from ...types import Response


def _get_kwargs(
    id: str,
    *,
    body: ChatSendMessage | DmSendMessage,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/chats/{id}/messages".format(
            id=quote(str(id), safe=""),
        ),
    }

    if isinstance(body, DmSendMessage):
        _kwargs["json"] = body.to_dict()
    else:
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostV1ChatsByIdMessagesResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = PostV1ChatsByIdMessagesResponse200.from_dict(response.json())

        return response_200

    if response.status_code == 400:
        response_400 = StripeError.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = StripeError.from_dict(response.json())

        return response_401

    if response.status_code == 402:
        response_402 = StripeError.from_dict(response.json())

        return response_402

    if response.status_code == 403:
        response_403 = StripeError.from_dict(response.json())

        return response_403

    if response.status_code == 404:
        response_404 = StripeError.from_dict(response.json())

        return response_404

    if response.status_code == 409:
        response_409 = StripeError.from_dict(response.json())

        return response_409

    if response.status_code == 503:
        response_503 = StripeError.from_dict(response.json())

        return response_503

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[PostV1ChatsByIdMessagesResponse200 | StripeError]:
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
    body: ChatSendMessage | DmSendMessage,
) -> Response[PostV1ChatsByIdMessagesResponse200 | StripeError]:
    """Send a message; the chat’s personas may reply (SSE)

     WHO REPLIES follows the definition's `personaReplyPolicy`: `every_message` — every persona seated in
    the chat; `when_mentioned` — only the personas the body mentions. A MENTION is `@<persona slug>`,
    case-insensitive, standing as its own word (`ann@scout.dev` and `@scouting` do not mention `scout`;
    `(@scout)` and `@scout,` do). Mentions are recorded under either policy.

    With nobody to reply (every DM, and a message no persona answers) this is a plain JSON send: 201
    with the message, 200 for a `clientMessageId` replay (a replay never re-runs replies).

    With personas to reply it answers `text/event-stream`: `open` `{message}` (the sent message,
    committed), then per persona in the order they joined: `persona_start` `{participantId, personaId}`;
    the turn’s own events (`token`, `tool_call_started`, `tool_call_completed`, `status`, `award`,
    `done`, `ended`), each with the persona’s `participantId` added; at most one `error`
    `{participantId, message}` if that persona could not reply; and `message` `{participantId, message}`
    for each visible row of its reply, once committed. The persona’s `typing` (kept alive for the whole
    turn, and stopped however it ends) and its messages are also published to the chat’s streams.

    Each persona’s turn is metered. The FIRST persona’s budget refusal (402) or unavailable metering
    (503) is returned before the message is stored; a later persona’s is its `error` event, and the
    personas after it still reply. The replies belong to the chat: they finish even if the sender
    disconnects.

    A persona sees the chat as a transcript: its own messages as its turns, everyone else’s as `Name:
    text` — including the replies of the personas before it.

    Replaces POST /chat/chats/{id}/messages, POST /chat/conversations/{id}/messages, POST
    /chat/dms/{chatId}/messages.

    Args:
        id (str):
        body (ChatSendMessage | DmSendMessage):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1ChatsByIdMessagesResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    *,
    client: AuthenticatedClient,
    body: ChatSendMessage | DmSendMessage,
) -> PostV1ChatsByIdMessagesResponse200 | StripeError | None:
    """Send a message; the chat’s personas may reply (SSE)

     WHO REPLIES follows the definition's `personaReplyPolicy`: `every_message` — every persona seated in
    the chat; `when_mentioned` — only the personas the body mentions. A MENTION is `@<persona slug>`,
    case-insensitive, standing as its own word (`ann@scout.dev` and `@scouting` do not mention `scout`;
    `(@scout)` and `@scout,` do). Mentions are recorded under either policy.

    With nobody to reply (every DM, and a message no persona answers) this is a plain JSON send: 201
    with the message, 200 for a `clientMessageId` replay (a replay never re-runs replies).

    With personas to reply it answers `text/event-stream`: `open` `{message}` (the sent message,
    committed), then per persona in the order they joined: `persona_start` `{participantId, personaId}`;
    the turn’s own events (`token`, `tool_call_started`, `tool_call_completed`, `status`, `award`,
    `done`, `ended`), each with the persona’s `participantId` added; at most one `error`
    `{participantId, message}` if that persona could not reply; and `message` `{participantId, message}`
    for each visible row of its reply, once committed. The persona’s `typing` (kept alive for the whole
    turn, and stopped however it ends) and its messages are also published to the chat’s streams.

    Each persona’s turn is metered. The FIRST persona’s budget refusal (402) or unavailable metering
    (503) is returned before the message is stored; a later persona’s is its `error` event, and the
    personas after it still reply. The replies belong to the chat: they finish even if the sender
    disconnects.

    A persona sees the chat as a transcript: its own messages as its turns, everyone else’s as `Name:
    text` — including the replies of the personas before it.

    Replaces POST /chat/chats/{id}/messages, POST /chat/conversations/{id}/messages, POST
    /chat/dms/{chatId}/messages.

    Args:
        id (str):
        body (ChatSendMessage | DmSendMessage):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1ChatsByIdMessagesResponse200 | StripeError
    """

    return sync_detailed(
        id=id,
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
    body: ChatSendMessage | DmSendMessage,
) -> Response[PostV1ChatsByIdMessagesResponse200 | StripeError]:
    """Send a message; the chat’s personas may reply (SSE)

     WHO REPLIES follows the definition's `personaReplyPolicy`: `every_message` — every persona seated in
    the chat; `when_mentioned` — only the personas the body mentions. A MENTION is `@<persona slug>`,
    case-insensitive, standing as its own word (`ann@scout.dev` and `@scouting` do not mention `scout`;
    `(@scout)` and `@scout,` do). Mentions are recorded under either policy.

    With nobody to reply (every DM, and a message no persona answers) this is a plain JSON send: 201
    with the message, 200 for a `clientMessageId` replay (a replay never re-runs replies).

    With personas to reply it answers `text/event-stream`: `open` `{message}` (the sent message,
    committed), then per persona in the order they joined: `persona_start` `{participantId, personaId}`;
    the turn’s own events (`token`, `tool_call_started`, `tool_call_completed`, `status`, `award`,
    `done`, `ended`), each with the persona’s `participantId` added; at most one `error`
    `{participantId, message}` if that persona could not reply; and `message` `{participantId, message}`
    for each visible row of its reply, once committed. The persona’s `typing` (kept alive for the whole
    turn, and stopped however it ends) and its messages are also published to the chat’s streams.

    Each persona’s turn is metered. The FIRST persona’s budget refusal (402) or unavailable metering
    (503) is returned before the message is stored; a later persona’s is its `error` event, and the
    personas after it still reply. The replies belong to the chat: they finish even if the sender
    disconnects.

    A persona sees the chat as a transcript: its own messages as its turns, everyone else’s as `Name:
    text` — including the replies of the personas before it.

    Replaces POST /chat/chats/{id}/messages, POST /chat/conversations/{id}/messages, POST
    /chat/dms/{chatId}/messages.

    Args:
        id (str):
        body (ChatSendMessage | DmSendMessage):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1ChatsByIdMessagesResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    *,
    client: AuthenticatedClient,
    body: ChatSendMessage | DmSendMessage,
) -> PostV1ChatsByIdMessagesResponse200 | StripeError | None:
    """Send a message; the chat’s personas may reply (SSE)

     WHO REPLIES follows the definition's `personaReplyPolicy`: `every_message` — every persona seated in
    the chat; `when_mentioned` — only the personas the body mentions. A MENTION is `@<persona slug>`,
    case-insensitive, standing as its own word (`ann@scout.dev` and `@scouting` do not mention `scout`;
    `(@scout)` and `@scout,` do). Mentions are recorded under either policy.

    With nobody to reply (every DM, and a message no persona answers) this is a plain JSON send: 201
    with the message, 200 for a `clientMessageId` replay (a replay never re-runs replies).

    With personas to reply it answers `text/event-stream`: `open` `{message}` (the sent message,
    committed), then per persona in the order they joined: `persona_start` `{participantId, personaId}`;
    the turn’s own events (`token`, `tool_call_started`, `tool_call_completed`, `status`, `award`,
    `done`, `ended`), each with the persona’s `participantId` added; at most one `error`
    `{participantId, message}` if that persona could not reply; and `message` `{participantId, message}`
    for each visible row of its reply, once committed. The persona’s `typing` (kept alive for the whole
    turn, and stopped however it ends) and its messages are also published to the chat’s streams.

    Each persona’s turn is metered. The FIRST persona’s budget refusal (402) or unavailable metering
    (503) is returned before the message is stored; a later persona’s is its `error` event, and the
    personas after it still reply. The replies belong to the chat: they finish even if the sender
    disconnects.

    A persona sees the chat as a transcript: its own messages as its turns, everyone else’s as `Name:
    text` — including the replies of the personas before it.

    Replaces POST /chat/chats/{id}/messages, POST /chat/conversations/{id}/messages, POST
    /chat/dms/{chatId}/messages.

    Args:
        id (str):
        body (ChatSendMessage | DmSendMessage):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1ChatsByIdMessagesResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            body=body,
        )
    ).parsed
