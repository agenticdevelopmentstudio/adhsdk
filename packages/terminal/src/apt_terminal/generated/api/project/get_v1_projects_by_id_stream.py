from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.get_v1_projects_by_id_stream_response_200 import GetV1ProjectsByIdStreamResponse200
from ...models.stripe_error import StripeError
from ...types import UNSET, Response, Unset


def _get_kwargs(
    id: str,
    *,
    expand: list[str] | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    json_expand: list[str] | Unset = UNSET
    if not isinstance(expand, Unset):
        json_expand = expand

    params["expand[]"] = json_expand

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/v1/projects/{id}/stream".format(
            id=quote(str(id), safe=""),
        ),
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> GetV1ProjectsByIdStreamResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = GetV1ProjectsByIdStreamResponse200.from_dict(response.json())

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
) -> Response[GetV1ProjectsByIdStreamResponse200 | StripeError]:
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
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1ProjectsByIdStreamResponse200 | StripeError]:
    """Server-sent wake stream for one board

     Opens an SSE stream that emits a payload-less `project` event ({}) each time anything on this board
    changes, so an open client refetches through the ordinary routes it already uses. The event
    deliberately carries NO data and NO kind: the stream is held open outside any tenant transaction, so
    the sending side has no caller to authorize a row against — a wake that carries nothing cannot leak
    anything. Several changes made by one gesture arrive as ONE event. Closes after 5 minutes;
    reconnect. When the server has no push channel configured it emits a single `ready` event instead
    and closes, and the client falls back to polling. Reachability is checked before the stream opens
    (404 for a board the caller cannot read), and — uniquely among Projects routes — the access token
    may be passed as `?access_token=`, because a browser EventSource cannot set the Authorization
    header.

    Replaces GET /project/projects/{id}/stream.

    Args:
        id (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1ProjectsByIdStreamResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
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
    expand: list[str] | Unset = UNSET,
) -> GetV1ProjectsByIdStreamResponse200 | StripeError | None:
    """Server-sent wake stream for one board

     Opens an SSE stream that emits a payload-less `project` event ({}) each time anything on this board
    changes, so an open client refetches through the ordinary routes it already uses. The event
    deliberately carries NO data and NO kind: the stream is held open outside any tenant transaction, so
    the sending side has no caller to authorize a row against — a wake that carries nothing cannot leak
    anything. Several changes made by one gesture arrive as ONE event. Closes after 5 minutes;
    reconnect. When the server has no push channel configured it emits a single `ready` event instead
    and closes, and the client falls back to polling. Reachability is checked before the stream opens
    (404 for a board the caller cannot read), and — uniquely among Projects routes — the access token
    may be passed as `?access_token=`, because a browser EventSource cannot set the Authorization
    header.

    Replaces GET /project/projects/{id}/stream.

    Args:
        id (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1ProjectsByIdStreamResponse200 | StripeError
    """

    return sync_detailed(
        id=id,
        client=client,
        expand=expand,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1ProjectsByIdStreamResponse200 | StripeError]:
    """Server-sent wake stream for one board

     Opens an SSE stream that emits a payload-less `project` event ({}) each time anything on this board
    changes, so an open client refetches through the ordinary routes it already uses. The event
    deliberately carries NO data and NO kind: the stream is held open outside any tenant transaction, so
    the sending side has no caller to authorize a row against — a wake that carries nothing cannot leak
    anything. Several changes made by one gesture arrive as ONE event. Closes after 5 minutes;
    reconnect. When the server has no push channel configured it emits a single `ready` event instead
    and closes, and the client falls back to polling. Reachability is checked before the stream opens
    (404 for a board the caller cannot read), and — uniquely among Projects routes — the access token
    may be passed as `?access_token=`, because a browser EventSource cannot set the Authorization
    header.

    Replaces GET /project/projects/{id}/stream.

    Args:
        id (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1ProjectsByIdStreamResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
        expand=expand,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    *,
    client: AuthenticatedClient,
    expand: list[str] | Unset = UNSET,
) -> GetV1ProjectsByIdStreamResponse200 | StripeError | None:
    """Server-sent wake stream for one board

     Opens an SSE stream that emits a payload-less `project` event ({}) each time anything on this board
    changes, so an open client refetches through the ordinary routes it already uses. The event
    deliberately carries NO data and NO kind: the stream is held open outside any tenant transaction, so
    the sending side has no caller to authorize a row against — a wake that carries nothing cannot leak
    anything. Several changes made by one gesture arrive as ONE event. Closes after 5 minutes;
    reconnect. When the server has no push channel configured it emits a single `ready` event instead
    and closes, and the client falls back to polling. Reachability is checked before the stream opens
    (404 for a board the caller cannot read), and — uniquely among Projects routes — the access token
    may be passed as `?access_token=`, because a browser EventSource cannot set the Authorization
    header.

    Replaces GET /project/projects/{id}/stream.

    Args:
        id (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1ProjectsByIdStreamResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            expand=expand,
        )
    ).parsed
