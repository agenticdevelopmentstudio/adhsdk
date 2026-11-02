from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.notification_wake_event import NotificationWakeEvent
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    access_token: str | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["access_token"] = access_token

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/notifications/stream",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | NotificationWakeEvent | None:
    if response.status_code == 200:
        response_200 = NotificationWakeEvent.from_dict(response.text)

        return response_200

    if response.status_code == 401:
        response_401 = Error.from_dict(response.json())

        return response_401

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | NotificationWakeEvent]:
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
) -> Response[Error | NotificationWakeEvent]:
    """Wake on new notifications (SSE)

     Server-Sent Events (`text/event-stream`). Emits a `notification` event with an empty `{}` payload
    each time something lands for the caller; re-read GET /notifications or /notifications/unread-count
    to find out what.

    If the backend was started without a notification hub, the stream instead emits a single `ready`
    event and closes immediately — the client should fall back to polling. Otherwise it stays open for
    at most 5 minutes and then closes with no terminal event; reconnect.

    Because a browser `EventSource` cannot set headers, the bearer token may be passed as an
    `access_token` query parameter instead. Connecting also marks the caller present, and disconnecting
    marks them away.

    Args:
        access_token (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | NotificationWakeEvent]
    """

    kwargs = _get_kwargs(
        access_token=access_token,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    access_token: str | Unset = UNSET,
) -> Error | NotificationWakeEvent | None:
    """Wake on new notifications (SSE)

     Server-Sent Events (`text/event-stream`). Emits a `notification` event with an empty `{}` payload
    each time something lands for the caller; re-read GET /notifications or /notifications/unread-count
    to find out what.

    If the backend was started without a notification hub, the stream instead emits a single `ready`
    event and closes immediately — the client should fall back to polling. Otherwise it stays open for
    at most 5 minutes and then closes with no terminal event; reconnect.

    Because a browser `EventSource` cannot set headers, the bearer token may be passed as an
    `access_token` query parameter instead. Connecting also marks the caller present, and disconnecting
    marks them away.

    Args:
        access_token (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | NotificationWakeEvent
    """

    return sync_detailed(
        client=client,
        access_token=access_token,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    access_token: str | Unset = UNSET,
) -> Response[Error | NotificationWakeEvent]:
    """Wake on new notifications (SSE)

     Server-Sent Events (`text/event-stream`). Emits a `notification` event with an empty `{}` payload
    each time something lands for the caller; re-read GET /notifications or /notifications/unread-count
    to find out what.

    If the backend was started without a notification hub, the stream instead emits a single `ready`
    event and closes immediately — the client should fall back to polling. Otherwise it stays open for
    at most 5 minutes and then closes with no terminal event; reconnect.

    Because a browser `EventSource` cannot set headers, the bearer token may be passed as an
    `access_token` query parameter instead. Connecting also marks the caller present, and disconnecting
    marks them away.

    Args:
        access_token (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | NotificationWakeEvent]
    """

    kwargs = _get_kwargs(
        access_token=access_token,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    access_token: str | Unset = UNSET,
) -> Error | NotificationWakeEvent | None:
    """Wake on new notifications (SSE)

     Server-Sent Events (`text/event-stream`). Emits a `notification` event with an empty `{}` payload
    each time something lands for the caller; re-read GET /notifications or /notifications/unread-count
    to find out what.

    If the backend was started without a notification hub, the stream instead emits a single `ready`
    event and closes immediately — the client should fall back to polling. Otherwise it stays open for
    at most 5 minutes and then closes with no terminal event; reconnect.

    Because a browser `EventSource` cannot set headers, the bearer token may be passed as an
    `access_token` query parameter instead. Connecting also marks the caller present, and disconnecting
    marks them away.

    Args:
        access_token (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | NotificationWakeEvent
    """

    return (
        await asyncio_detailed(
            client=client,
            access_token=access_token,
        )
    ).parsed
