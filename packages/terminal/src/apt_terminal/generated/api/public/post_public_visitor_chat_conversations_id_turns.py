from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.visitor_award_event import VisitorAwardEvent
from ...models.visitor_done_event import VisitorDoneEvent
from ...models.visitor_ended_event import VisitorEndedEvent
from ...models.visitor_error_event import VisitorErrorEvent
from ...models.visitor_open_event import VisitorOpenEvent
from ...models.visitor_status_event import VisitorStatusEvent
from ...models.visitor_token_event import VisitorTokenEvent
from ...models.visitor_tool_call_completed_event import VisitorToolCallCompletedEvent
from ...models.visitor_tool_call_started_event import VisitorToolCallStartedEvent
from ...models.visitor_turn_request import VisitorTurnRequest
from ...types import UNSET, Response, Unset


def _get_kwargs(
    id: str,
    *,
    body: VisitorTurnRequest | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/public/visitor-chat/conversations/{id}/turns".format(
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
    Error
    | VisitorAwardEvent
    | VisitorDoneEvent
    | VisitorEndedEvent
    | VisitorErrorEvent
    | VisitorOpenEvent
    | VisitorStatusEvent
    | VisitorTokenEvent
    | VisitorToolCallCompletedEvent
    | VisitorToolCallStartedEvent
    | None
):
    if response.status_code == 200:

        def _parse_response_200(
            data: object,
        ) -> (
            VisitorAwardEvent
            | VisitorDoneEvent
            | VisitorEndedEvent
            | VisitorErrorEvent
            | VisitorOpenEvent
            | VisitorStatusEvent
            | VisitorTokenEvent
            | VisitorToolCallCompletedEvent
            | VisitorToolCallStartedEvent
        ):
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                componentsschemas_visitor_turn_event_visitor_open_event = (
                    VisitorOpenEvent.from_dict(data)
                )

                return componentsschemas_visitor_turn_event_visitor_open_event
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                componentsschemas_visitor_turn_event_visitor_token_event = (
                    VisitorTokenEvent.from_dict(data)
                )

                return componentsschemas_visitor_turn_event_visitor_token_event
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                componentsschemas_visitor_turn_event_visitor_tool_call_started_event = (
                    VisitorToolCallStartedEvent.from_dict(data)
                )

                return componentsschemas_visitor_turn_event_visitor_tool_call_started_event
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                componentsschemas_visitor_turn_event_visitor_tool_call_completed_event = (
                    VisitorToolCallCompletedEvent.from_dict(data)
                )

                return componentsschemas_visitor_turn_event_visitor_tool_call_completed_event
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                componentsschemas_visitor_turn_event_visitor_status_event = (
                    VisitorStatusEvent.from_dict(data)
                )

                return componentsschemas_visitor_turn_event_visitor_status_event
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                componentsschemas_visitor_turn_event_visitor_award_event = (
                    VisitorAwardEvent.from_dict(data)
                )

                return componentsschemas_visitor_turn_event_visitor_award_event
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                componentsschemas_visitor_turn_event_visitor_done_event = (
                    VisitorDoneEvent.from_dict(data)
                )

                return componentsschemas_visitor_turn_event_visitor_done_event
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                componentsschemas_visitor_turn_event_visitor_ended_event = (
                    VisitorEndedEvent.from_dict(data)
                )

                return componentsschemas_visitor_turn_event_visitor_ended_event
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            if not isinstance(data, dict):
                raise TypeError()
            componentsschemas_visitor_turn_event_visitor_error_event = VisitorErrorEvent.from_dict(
                data
            )

            return componentsschemas_visitor_turn_event_visitor_error_event

        response_200 = _parse_response_200(response.text)

        return response_200

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

    if response.status_code == 422:
        response_422 = Error.from_dict(response.json())

        return response_422

    if response.status_code == 429:
        response_429 = Error.from_dict(response.json())

        return response_429

    if response.status_code == 503:
        response_503 = Error.from_dict(response.json())

        return response_503

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[
    Error
    | VisitorAwardEvent
    | VisitorDoneEvent
    | VisitorEndedEvent
    | VisitorErrorEvent
    | VisitorOpenEvent
    | VisitorStatusEvent
    | VisitorTokenEvent
    | VisitorToolCallCompletedEvent
    | VisitorToolCallStartedEvent
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
    body: VisitorTurnRequest | Unset = UNSET,
) -> Response[
    Error
    | VisitorAwardEvent
    | VisitorDoneEvent
    | VisitorEndedEvent
    | VisitorErrorEvent
    | VisitorOpenEvent
    | VisitorStatusEvent
    | VisitorTokenEvent
    | VisitorToolCallCompletedEvent
    | VisitorToolCallStartedEvent
]:
    """Take a turn in a visitor conversation (SSE)

     Streams the persona's reply as Server-Sent Events (`text/event-stream`): an `open` event, then
    `token`, `tool_call_started`, `tool_call_completed`, `status` and `award` events, ending in `done`,
    `ended` (the persona closed the chat) or `error`.

    Every check happens BEFORE the stream opens, so a refusal is always a real HTTP status: 409 when the
    conversation is closed or full, 422 when the message is too long or is screened out, 429 past a rate
    window, 503 when capacity or budget is exhausted. Once the stream is open, HTTP is already 200 and
    any later failure arrives as an `error` event instead.

    Args:
        id (str):
        body (VisitorTurnRequest | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | VisitorAwardEvent | VisitorDoneEvent | VisitorEndedEvent | VisitorErrorEvent | VisitorOpenEvent | VisitorStatusEvent | VisitorTokenEvent | VisitorToolCallCompletedEvent | VisitorToolCallStartedEvent]
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
    body: VisitorTurnRequest | Unset = UNSET,
) -> (
    Error
    | VisitorAwardEvent
    | VisitorDoneEvent
    | VisitorEndedEvent
    | VisitorErrorEvent
    | VisitorOpenEvent
    | VisitorStatusEvent
    | VisitorTokenEvent
    | VisitorToolCallCompletedEvent
    | VisitorToolCallStartedEvent
    | None
):
    """Take a turn in a visitor conversation (SSE)

     Streams the persona's reply as Server-Sent Events (`text/event-stream`): an `open` event, then
    `token`, `tool_call_started`, `tool_call_completed`, `status` and `award` events, ending in `done`,
    `ended` (the persona closed the chat) or `error`.

    Every check happens BEFORE the stream opens, so a refusal is always a real HTTP status: 409 when the
    conversation is closed or full, 422 when the message is too long or is screened out, 429 past a rate
    window, 503 when capacity or budget is exhausted. Once the stream is open, HTTP is already 200 and
    any later failure arrives as an `error` event instead.

    Args:
        id (str):
        body (VisitorTurnRequest | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | VisitorAwardEvent | VisitorDoneEvent | VisitorEndedEvent | VisitorErrorEvent | VisitorOpenEvent | VisitorStatusEvent | VisitorTokenEvent | VisitorToolCallCompletedEvent | VisitorToolCallStartedEvent
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
    body: VisitorTurnRequest | Unset = UNSET,
) -> Response[
    Error
    | VisitorAwardEvent
    | VisitorDoneEvent
    | VisitorEndedEvent
    | VisitorErrorEvent
    | VisitorOpenEvent
    | VisitorStatusEvent
    | VisitorTokenEvent
    | VisitorToolCallCompletedEvent
    | VisitorToolCallStartedEvent
]:
    """Take a turn in a visitor conversation (SSE)

     Streams the persona's reply as Server-Sent Events (`text/event-stream`): an `open` event, then
    `token`, `tool_call_started`, `tool_call_completed`, `status` and `award` events, ending in `done`,
    `ended` (the persona closed the chat) or `error`.

    Every check happens BEFORE the stream opens, so a refusal is always a real HTTP status: 409 when the
    conversation is closed or full, 422 when the message is too long or is screened out, 429 past a rate
    window, 503 when capacity or budget is exhausted. Once the stream is open, HTTP is already 200 and
    any later failure arrives as an `error` event instead.

    Args:
        id (str):
        body (VisitorTurnRequest | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | VisitorAwardEvent | VisitorDoneEvent | VisitorEndedEvent | VisitorErrorEvent | VisitorOpenEvent | VisitorStatusEvent | VisitorTokenEvent | VisitorToolCallCompletedEvent | VisitorToolCallStartedEvent]
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
    body: VisitorTurnRequest | Unset = UNSET,
) -> (
    Error
    | VisitorAwardEvent
    | VisitorDoneEvent
    | VisitorEndedEvent
    | VisitorErrorEvent
    | VisitorOpenEvent
    | VisitorStatusEvent
    | VisitorTokenEvent
    | VisitorToolCallCompletedEvent
    | VisitorToolCallStartedEvent
    | None
):
    """Take a turn in a visitor conversation (SSE)

     Streams the persona's reply as Server-Sent Events (`text/event-stream`): an `open` event, then
    `token`, `tool_call_started`, `tool_call_completed`, `status` and `award` events, ending in `done`,
    `ended` (the persona closed the chat) or `error`.

    Every check happens BEFORE the stream opens, so a refusal is always a real HTTP status: 409 when the
    conversation is closed or full, 422 when the message is too long or is screened out, 429 past a rate
    window, 503 when capacity or budget is exhausted. Once the stream is open, HTTP is already 200 and
    any later failure arrives as an `error` event instead.

    Args:
        id (str):
        body (VisitorTurnRequest | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | VisitorAwardEvent | VisitorDoneEvent | VisitorEndedEvent | VisitorErrorEvent | VisitorOpenEvent | VisitorStatusEvent | VisitorTokenEvent | VisitorToolCallCompletedEvent | VisitorToolCallStartedEvent
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            body=body,
        )
    ).parsed
