from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.post_v1_visitor_chats_by_id_turns_response_200 import (
    PostV1VisitorChatsByIdTurnsResponse200,
)
from ...models.stripe_error import StripeError
from ...models.visitor_turn_request import VisitorTurnRequest
from ...types import Response


def _get_kwargs(
    id: str,
    *,
    body: VisitorTurnRequest,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/visitor_chats/{id}/turns".format(
            id=quote(str(id), safe=""),
        ),
    }

    _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostV1VisitorChatsByIdTurnsResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = PostV1VisitorChatsByIdTurnsResponse200.from_dict(response.json())

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

    if response.status_code == 422:
        response_422 = StripeError.from_dict(response.json())

        return response_422

    if response.status_code == 429:
        response_429 = StripeError.from_dict(response.json())

        return response_429

    if response.status_code == 503:
        response_503 = StripeError.from_dict(response.json())

        return response_503

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[PostV1VisitorChatsByIdTurnsResponse200 | StripeError]:
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
    body: VisitorTurnRequest,
) -> Response[PostV1VisitorChatsByIdTurnsResponse200 | StripeError]:
    """Take a turn in a visitor conversation (SSE)

     Streams the persona's reply as Server-Sent Events (`text/event-stream`): an `open` event, then
    `token`, `tool_call_started`, `tool_call_completed`, `status` and `award` events, ending in `done`,
    `ended` (the persona closed the chat) or `error`.

    Every check happens BEFORE the stream opens, so a refusal is always a real HTTP status: 409 when the
    conversation is closed or full, 422 when the message is too long or is screened out, 429 past a rate
    window, 503 when capacity or budget is exhausted. Once the stream is open, HTTP is already 200 and
    any later failure arrives as an `error` event instead.

    Replaces POST /public/visitor-chat/conversations/{id}/turns.

    Args:
        id (str):
        body (VisitorTurnRequest):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1VisitorChatsByIdTurnsResponse200 | StripeError]
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
    body: VisitorTurnRequest,
) -> PostV1VisitorChatsByIdTurnsResponse200 | StripeError | None:
    """Take a turn in a visitor conversation (SSE)

     Streams the persona's reply as Server-Sent Events (`text/event-stream`): an `open` event, then
    `token`, `tool_call_started`, `tool_call_completed`, `status` and `award` events, ending in `done`,
    `ended` (the persona closed the chat) or `error`.

    Every check happens BEFORE the stream opens, so a refusal is always a real HTTP status: 409 when the
    conversation is closed or full, 422 when the message is too long or is screened out, 429 past a rate
    window, 503 when capacity or budget is exhausted. Once the stream is open, HTTP is already 200 and
    any later failure arrives as an `error` event instead.

    Replaces POST /public/visitor-chat/conversations/{id}/turns.

    Args:
        id (str):
        body (VisitorTurnRequest):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1VisitorChatsByIdTurnsResponse200 | StripeError
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
    body: VisitorTurnRequest,
) -> Response[PostV1VisitorChatsByIdTurnsResponse200 | StripeError]:
    """Take a turn in a visitor conversation (SSE)

     Streams the persona's reply as Server-Sent Events (`text/event-stream`): an `open` event, then
    `token`, `tool_call_started`, `tool_call_completed`, `status` and `award` events, ending in `done`,
    `ended` (the persona closed the chat) or `error`.

    Every check happens BEFORE the stream opens, so a refusal is always a real HTTP status: 409 when the
    conversation is closed or full, 422 when the message is too long or is screened out, 429 past a rate
    window, 503 when capacity or budget is exhausted. Once the stream is open, HTTP is already 200 and
    any later failure arrives as an `error` event instead.

    Replaces POST /public/visitor-chat/conversations/{id}/turns.

    Args:
        id (str):
        body (VisitorTurnRequest):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1VisitorChatsByIdTurnsResponse200 | StripeError]
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
    body: VisitorTurnRequest,
) -> PostV1VisitorChatsByIdTurnsResponse200 | StripeError | None:
    """Take a turn in a visitor conversation (SSE)

     Streams the persona's reply as Server-Sent Events (`text/event-stream`): an `open` event, then
    `token`, `tool_call_started`, `tool_call_completed`, `status` and `award` events, ending in `done`,
    `ended` (the persona closed the chat) or `error`.

    Every check happens BEFORE the stream opens, so a refusal is always a real HTTP status: 409 when the
    conversation is closed or full, 422 when the message is too long or is screened out, 429 past a rate
    window, 503 when capacity or budget is exhausted. Once the stream is open, HTTP is already 200 and
    any later failure arrives as an `error` event instead.

    Replaces POST /public/visitor-chat/conversations/{id}/turns.

    Args:
        id (str):
        body (VisitorTurnRequest):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1VisitorChatsByIdTurnsResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            body=body,
        )
    ).parsed
