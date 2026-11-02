from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.feed_page import FeedPage
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    entity_type: str | Unset = UNSET,
    action: str | Unset = UNSET,
    source: str | Unset = UNSET,
    since: str | Unset = UNSET,
    until: str | Unset = UNSET,
    unread: str | Unset = UNSET,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["entityType"] = entity_type

    params["action"] = action

    params["source"] = source

    params["since"] = since

    params["until"] = until

    params["unread"] = unread

    params["page"] = page

    params["pageSize"] = page_size

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/content/feed",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | FeedPage | None:
    if response.status_code == 200:
        response_200 = FeedPage.from_dict(response.json())

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
) -> Response[Error | FeedPage]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    entity_type: str | Unset = UNSET,
    action: str | Unset = UNSET,
    source: str | Unset = UNSET,
    since: str | Unset = UNSET,
    until: str | Unset = UNSET,
    unread: str | Unset = UNSET,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
) -> Response[Error | FeedPage]:
    """List the caller's activity feed (filterable, paginated)

    Args:
        entity_type (str | Unset):
        action (str | Unset):
        source (str | Unset):
        since (str | Unset):
        until (str | Unset):
        unread (str | Unset):
        page (str | Unset):
        page_size (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | FeedPage]
    """

    kwargs = _get_kwargs(
        entity_type=entity_type,
        action=action,
        source=source,
        since=since,
        until=until,
        unread=unread,
        page=page,
        page_size=page_size,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    entity_type: str | Unset = UNSET,
    action: str | Unset = UNSET,
    source: str | Unset = UNSET,
    since: str | Unset = UNSET,
    until: str | Unset = UNSET,
    unread: str | Unset = UNSET,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
) -> Error | FeedPage | None:
    """List the caller's activity feed (filterable, paginated)

    Args:
        entity_type (str | Unset):
        action (str | Unset):
        source (str | Unset):
        since (str | Unset):
        until (str | Unset):
        unread (str | Unset):
        page (str | Unset):
        page_size (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | FeedPage
    """

    return sync_detailed(
        client=client,
        entity_type=entity_type,
        action=action,
        source=source,
        since=since,
        until=until,
        unread=unread,
        page=page,
        page_size=page_size,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    entity_type: str | Unset = UNSET,
    action: str | Unset = UNSET,
    source: str | Unset = UNSET,
    since: str | Unset = UNSET,
    until: str | Unset = UNSET,
    unread: str | Unset = UNSET,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
) -> Response[Error | FeedPage]:
    """List the caller's activity feed (filterable, paginated)

    Args:
        entity_type (str | Unset):
        action (str | Unset):
        source (str | Unset):
        since (str | Unset):
        until (str | Unset):
        unread (str | Unset):
        page (str | Unset):
        page_size (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | FeedPage]
    """

    kwargs = _get_kwargs(
        entity_type=entity_type,
        action=action,
        source=source,
        since=since,
        until=until,
        unread=unread,
        page=page,
        page_size=page_size,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    entity_type: str | Unset = UNSET,
    action: str | Unset = UNSET,
    source: str | Unset = UNSET,
    since: str | Unset = UNSET,
    until: str | Unset = UNSET,
    unread: str | Unset = UNSET,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
) -> Error | FeedPage | None:
    """List the caller's activity feed (filterable, paginated)

    Args:
        entity_type (str | Unset):
        action (str | Unset):
        source (str | Unset):
        since (str | Unset):
        until (str | Unset):
        unread (str | Unset):
        page (str | Unset):
        page_size (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | FeedPage
    """

    return (
        await asyncio_detailed(
            client=client,
            entity_type=entity_type,
            action=action,
            source=source,
            since=since,
            until=until,
            unread=unread,
            page=page,
            page_size=page_size,
        )
    ).parsed
