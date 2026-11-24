from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.get_v1_chats_by_id_stream_response_200 import GetV1ChatsByIdStreamResponse200
from ...models.stripe_error import StripeError
from ...types import UNSET, Response, Unset


def _get_kwargs(
    id: str,
    *,
    after: int | Unset = 0,
    access_token: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["after"] = after

    params["access_token"] = access_token

    json_expand: list[str] | Unset = UNSET
    if not isinstance(expand, Unset):
        json_expand = expand

    params["expand[]"] = json_expand

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/v1/chats/{id}/stream".format(
            id=quote(str(id), safe=""),
        ),
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> GetV1ChatsByIdStreamResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = GetV1ChatsByIdStreamResponse200.from_dict(response.json())

        return response_200

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
) -> Response[GetV1ChatsByIdStreamResponse200 | StripeError]:
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
    after: int | Unset = 0,
    access_token: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1ChatsByIdStreamResponse200 | StripeError]:
    """Stream new DMs in a chat (SSE)

     Server-Sent Events (`text/event-stream`). Emits one `message` event per DM with `seq` greater than
    the `after` cursor — first the backlog, then each new message as it arrives. There is no `open`,
    `error`, or keepalive event, and no terminal event: the stream simply closes after at most 5
    minutes, and the client reconnects with `after` set to the last `seq` it saw. Unlike the
    conversation turn stream, failures here are real HTTP statuses raised before the stream opens, never
    in-band.

    Because a browser `EventSource` cannot set headers, this route (alone among the DM routes) also
    accepts the bearer token as an `access_token` query parameter.

    Replaces GET /chat/dms/{chatId}/stream.

    Args:
        id (str):
        after (int | Unset):  Default: 0.
        access_token (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1ChatsByIdStreamResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
        after=after,
        access_token=access_token,
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
    after: int | Unset = 0,
    access_token: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> GetV1ChatsByIdStreamResponse200 | StripeError | None:
    """Stream new DMs in a chat (SSE)

     Server-Sent Events (`text/event-stream`). Emits one `message` event per DM with `seq` greater than
    the `after` cursor — first the backlog, then each new message as it arrives. There is no `open`,
    `error`, or keepalive event, and no terminal event: the stream simply closes after at most 5
    minutes, and the client reconnects with `after` set to the last `seq` it saw. Unlike the
    conversation turn stream, failures here are real HTTP statuses raised before the stream opens, never
    in-band.

    Because a browser `EventSource` cannot set headers, this route (alone among the DM routes) also
    accepts the bearer token as an `access_token` query parameter.

    Replaces GET /chat/dms/{chatId}/stream.

    Args:
        id (str):
        after (int | Unset):  Default: 0.
        access_token (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1ChatsByIdStreamResponse200 | StripeError
    """

    return sync_detailed(
        id=id,
        client=client,
        after=after,
        access_token=access_token,
        expand=expand,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
    after: int | Unset = 0,
    access_token: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1ChatsByIdStreamResponse200 | StripeError]:
    """Stream new DMs in a chat (SSE)

     Server-Sent Events (`text/event-stream`). Emits one `message` event per DM with `seq` greater than
    the `after` cursor — first the backlog, then each new message as it arrives. There is no `open`,
    `error`, or keepalive event, and no terminal event: the stream simply closes after at most 5
    minutes, and the client reconnects with `after` set to the last `seq` it saw. Unlike the
    conversation turn stream, failures here are real HTTP statuses raised before the stream opens, never
    in-band.

    Because a browser `EventSource` cannot set headers, this route (alone among the DM routes) also
    accepts the bearer token as an `access_token` query parameter.

    Replaces GET /chat/dms/{chatId}/stream.

    Args:
        id (str):
        after (int | Unset):  Default: 0.
        access_token (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1ChatsByIdStreamResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
        after=after,
        access_token=access_token,
        expand=expand,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    *,
    client: AuthenticatedClient,
    after: int | Unset = 0,
    access_token: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> GetV1ChatsByIdStreamResponse200 | StripeError | None:
    """Stream new DMs in a chat (SSE)

     Server-Sent Events (`text/event-stream`). Emits one `message` event per DM with `seq` greater than
    the `after` cursor — first the backlog, then each new message as it arrives. There is no `open`,
    `error`, or keepalive event, and no terminal event: the stream simply closes after at most 5
    minutes, and the client reconnects with `after` set to the last `seq` it saw. Unlike the
    conversation turn stream, failures here are real HTTP statuses raised before the stream opens, never
    in-band.

    Because a browser `EventSource` cannot set headers, this route (alone among the DM routes) also
    accepts the bearer token as an `access_token` query parameter.

    Replaces GET /chat/dms/{chatId}/stream.

    Args:
        id (str):
        after (int | Unset):  Default: 0.
        access_token (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1ChatsByIdStreamResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            after=after,
            access_token=access_token,
            expand=expand,
        )
    ).parsed
