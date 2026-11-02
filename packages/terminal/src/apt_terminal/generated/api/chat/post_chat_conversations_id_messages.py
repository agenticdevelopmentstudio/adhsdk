from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.chat_done_event import ChatDoneEvent
from ...models.chat_error_event import ChatErrorEvent
from ...models.chat_send_message import ChatSendMessage
from ...models.chat_token_event import ChatTokenEvent
from ...models.chat_tool_call_completed_event import ChatToolCallCompletedEvent
from ...models.chat_tool_call_started_event import ChatToolCallStartedEvent
from ...models.error import Error
from ...types import UNSET, Response, Unset


def _get_kwargs(
    id: str,
    *,
    body: ChatSendMessage | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/chat/conversations/{id}/messages".format(
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
) -> (
    ChatDoneEvent
    | ChatErrorEvent
    | ChatTokenEvent
    | ChatToolCallCompletedEvent
    | ChatToolCallStartedEvent
    | Error
    | None
):
    if response.status_code == 200:

        def _parse_response_200(
            data: object,
        ) -> (
            ChatDoneEvent
            | ChatErrorEvent
            | ChatTokenEvent
            | ChatToolCallCompletedEvent
            | ChatToolCallStartedEvent
        ):
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                componentsschemas_chat_stream_event_chat_token_event = ChatTokenEvent.from_dict(
                    data
                )

                return componentsschemas_chat_stream_event_chat_token_event
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                componentsschemas_chat_stream_event_chat_tool_call_started_event = (
                    ChatToolCallStartedEvent.from_dict(data)
                )

                return componentsschemas_chat_stream_event_chat_tool_call_started_event
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                componentsschemas_chat_stream_event_chat_tool_call_completed_event = (
                    ChatToolCallCompletedEvent.from_dict(data)
                )

                return componentsschemas_chat_stream_event_chat_tool_call_completed_event
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                componentsschemas_chat_stream_event_chat_done_event = ChatDoneEvent.from_dict(data)

                return componentsschemas_chat_stream_event_chat_done_event
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            if not isinstance(data, dict):
                raise TypeError()
            componentsschemas_chat_stream_event_chat_error_event = ChatErrorEvent.from_dict(data)

            return componentsschemas_chat_stream_event_chat_error_event

        response_200 = _parse_response_200(response.text)

        return response_200

    if response.status_code == 400:
        response_400 = Error.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = Error.from_dict(response.json())

        return response_401

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[
    ChatDoneEvent
    | ChatErrorEvent
    | ChatTokenEvent
    | ChatToolCallCompletedEvent
    | ChatToolCallStartedEvent
    | Error
]:
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
    body: ChatSendMessage | Unset = UNSET,
) -> Response[
    ChatDoneEvent
    | ChatErrorEvent
    | ChatTokenEvent
    | ChatToolCallCompletedEvent
    | ChatToolCallStartedEvent
    | Error
]:
    """Send a message and stream the assistant turn (SSE)

     Sends a user message and streams the assistant response as Server-Sent Events (`text/event-stream`).
    The stream emits an `open` event, then `token`, `tool_call_started`, `tool_call_completed`, and a
    terminal `done` event; failures surface as an `error` event. The response is always 200 even when
    the conversation is missing or the turn fails — those conditions are reported in-band via the
    `error` event rather than an HTTP status.

    Args:
        id (str):
        body (ChatSendMessage | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[ChatDoneEvent | ChatErrorEvent | ChatTokenEvent | ChatToolCallCompletedEvent | ChatToolCallStartedEvent | Error]
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
    body: ChatSendMessage | Unset = UNSET,
) -> (
    ChatDoneEvent
    | ChatErrorEvent
    | ChatTokenEvent
    | ChatToolCallCompletedEvent
    | ChatToolCallStartedEvent
    | Error
    | None
):
    """Send a message and stream the assistant turn (SSE)

     Sends a user message and streams the assistant response as Server-Sent Events (`text/event-stream`).
    The stream emits an `open` event, then `token`, `tool_call_started`, `tool_call_completed`, and a
    terminal `done` event; failures surface as an `error` event. The response is always 200 even when
    the conversation is missing or the turn fails — those conditions are reported in-band via the
    `error` event rather than an HTTP status.

    Args:
        id (str):
        body (ChatSendMessage | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        ChatDoneEvent | ChatErrorEvent | ChatTokenEvent | ChatToolCallCompletedEvent | ChatToolCallStartedEvent | Error
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
    body: ChatSendMessage | Unset = UNSET,
) -> Response[
    ChatDoneEvent
    | ChatErrorEvent
    | ChatTokenEvent
    | ChatToolCallCompletedEvent
    | ChatToolCallStartedEvent
    | Error
]:
    """Send a message and stream the assistant turn (SSE)

     Sends a user message and streams the assistant response as Server-Sent Events (`text/event-stream`).
    The stream emits an `open` event, then `token`, `tool_call_started`, `tool_call_completed`, and a
    terminal `done` event; failures surface as an `error` event. The response is always 200 even when
    the conversation is missing or the turn fails — those conditions are reported in-band via the
    `error` event rather than an HTTP status.

    Args:
        id (str):
        body (ChatSendMessage | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[ChatDoneEvent | ChatErrorEvent | ChatTokenEvent | ChatToolCallCompletedEvent | ChatToolCallStartedEvent | Error]
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
    body: ChatSendMessage | Unset = UNSET,
) -> (
    ChatDoneEvent
    | ChatErrorEvent
    | ChatTokenEvent
    | ChatToolCallCompletedEvent
    | ChatToolCallStartedEvent
    | Error
    | None
):
    """Send a message and stream the assistant turn (SSE)

     Sends a user message and streams the assistant response as Server-Sent Events (`text/event-stream`).
    The stream emits an `open` event, then `token`, `tool_call_started`, `tool_call_completed`, and a
    terminal `done` event; failures surface as an `error` event. The response is always 200 even when
    the conversation is missing or the turn fails — those conditions are reported in-band via the
    `error` event rather than an HTTP status.

    Args:
        id (str):
        body (ChatSendMessage | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        ChatDoneEvent | ChatErrorEvent | ChatTokenEvent | ChatToolCallCompletedEvent | ChatToolCallStartedEvent | Error
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            body=body,
        )
    ).parsed
