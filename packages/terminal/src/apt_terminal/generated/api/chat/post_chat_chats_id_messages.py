from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.dm_message import DmMessage
from ...models.dm_send_message import DmSendMessage
from ...models.error import Error
from ...types import UNSET, Response, Unset


def _get_kwargs(
    id: str,
    *,
    body: DmSendMessage | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/chat/chats/{id}/messages".format(
            id=quote(str(id), safe=""),
        ),
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> DmMessage | Error | None:
    if response.status_code == 200:
        response_200 = DmMessage.from_dict(response.json())

        return response_200

    if response.status_code == 201:
        response_201 = DmMessage.from_dict(response.json())

        return response_201

    if response.status_code == 400:
        response_400 = Error.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = Error.from_dict(response.json())

        return response_401

    if response.status_code == 402:
        response_402 = Error.from_dict(response.json())

        return response_402

    if response.status_code == 403:
        response_403 = Error.from_dict(response.json())

        return response_403

    if response.status_code == 404:
        response_404 = Error.from_dict(response.json())

        return response_404

    if response.status_code == 409:
        response_409 = Error.from_dict(response.json())

        return response_409

    if response.status_code == 503:
        response_503 = Error.from_dict(response.json())

        return response_503

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[DmMessage | Error]:
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
    body: DmSendMessage | Unset = UNSET,
) -> Response[DmMessage | Error]:
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

    Args:
        id (str):
        body (DmSendMessage | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[DmMessage | Error]
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
    body: DmSendMessage | Unset = UNSET,
) -> DmMessage | Error | None:
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

    Args:
        id (str):
        body (DmSendMessage | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        DmMessage | Error
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
    body: DmSendMessage | Unset = UNSET,
) -> Response[DmMessage | Error]:
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

    Args:
        id (str):
        body (DmSendMessage | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[DmMessage | Error]
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
    body: DmSendMessage | Unset = UNSET,
) -> DmMessage | Error | None:
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

    Args:
        id (str):
        body (DmSendMessage | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        DmMessage | Error
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            body=body,
        )
    ).parsed
