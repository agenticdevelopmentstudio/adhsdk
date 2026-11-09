from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.get_v1_content_feed_items_include_item import GetV1ContentFeedItemsIncludeItem
from ...models.get_v1_content_feed_items_response_200 import GetV1ContentFeedItemsResponse200
from ...models.stripe_error import StripeError
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    entity_type: str | Unset = UNSET,
    action: str | Unset = UNSET,
    source: str | Unset = UNSET,
    since: str | Unset = UNSET,
    until: str | Unset = UNSET,
    unread: str | Unset = UNSET,
    limit: int | Unset = 10,
    starting_after: str | Unset = UNSET,
    ending_before: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
    include: list[GetV1ContentFeedItemsIncludeItem] | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["entity_type"] = entity_type

    params["action"] = action

    params["source"] = source

    params["since"] = since

    params["until"] = until

    params["unread"] = unread

    params["limit"] = limit

    params["starting_after"] = starting_after

    params["ending_before"] = ending_before

    json_expand: list[str] | Unset = UNSET
    if not isinstance(expand, Unset):
        json_expand = expand

    params["expand[]"] = json_expand

    json_include: list[str] | Unset = UNSET
    if not isinstance(include, Unset):
        json_include = []
        for include_item_data in include:
            include_item = include_item_data.value
            json_include.append(include_item)

    params["include[]"] = json_include

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/v1/content/feed_items",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> GetV1ContentFeedItemsResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = GetV1ContentFeedItemsResponse200.from_dict(response.json())

        return response_200

    if response.status_code == 400:
        response_400 = StripeError.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = StripeError.from_dict(response.json())

        return response_401

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[GetV1ContentFeedItemsResponse200 | StripeError]:
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
    limit: int | Unset = 10,
    starting_after: str | Unset = UNSET,
    ending_before: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
    include: list[GetV1ContentFeedItemsIncludeItem] | Unset = UNSET,
) -> Response[GetV1ContentFeedItemsResponse200 | StripeError]:
    """List the caller's activity feed (filterable, paginated)

     Replaces GET /content/feed, GET /content/feed/unread-count (include unread_count).

    Args:
        entity_type (str | Unset):
        action (str | Unset):
        source (str | Unset):
        since (str | Unset):
        until (str | Unset):
        unread (str | Unset):
        limit (int | Unset):  Default: 10.
        starting_after (str | Unset):
        ending_before (str | Unset):
        expand (list[str] | Unset):
        include (list[GetV1ContentFeedItemsIncludeItem] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1ContentFeedItemsResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        entity_type=entity_type,
        action=action,
        source=source,
        since=since,
        until=until,
        unread=unread,
        limit=limit,
        starting_after=starting_after,
        ending_before=ending_before,
        expand=expand,
        include=include,
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
    limit: int | Unset = 10,
    starting_after: str | Unset = UNSET,
    ending_before: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
    include: list[GetV1ContentFeedItemsIncludeItem] | Unset = UNSET,
) -> GetV1ContentFeedItemsResponse200 | StripeError | None:
    """List the caller's activity feed (filterable, paginated)

     Replaces GET /content/feed, GET /content/feed/unread-count (include unread_count).

    Args:
        entity_type (str | Unset):
        action (str | Unset):
        source (str | Unset):
        since (str | Unset):
        until (str | Unset):
        unread (str | Unset):
        limit (int | Unset):  Default: 10.
        starting_after (str | Unset):
        ending_before (str | Unset):
        expand (list[str] | Unset):
        include (list[GetV1ContentFeedItemsIncludeItem] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1ContentFeedItemsResponse200 | StripeError
    """

    return sync_detailed(
        client=client,
        entity_type=entity_type,
        action=action,
        source=source,
        since=since,
        until=until,
        unread=unread,
        limit=limit,
        starting_after=starting_after,
        ending_before=ending_before,
        expand=expand,
        include=include,
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
    limit: int | Unset = 10,
    starting_after: str | Unset = UNSET,
    ending_before: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
    include: list[GetV1ContentFeedItemsIncludeItem] | Unset = UNSET,
) -> Response[GetV1ContentFeedItemsResponse200 | StripeError]:
    """List the caller's activity feed (filterable, paginated)

     Replaces GET /content/feed, GET /content/feed/unread-count (include unread_count).

    Args:
        entity_type (str | Unset):
        action (str | Unset):
        source (str | Unset):
        since (str | Unset):
        until (str | Unset):
        unread (str | Unset):
        limit (int | Unset):  Default: 10.
        starting_after (str | Unset):
        ending_before (str | Unset):
        expand (list[str] | Unset):
        include (list[GetV1ContentFeedItemsIncludeItem] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1ContentFeedItemsResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        entity_type=entity_type,
        action=action,
        source=source,
        since=since,
        until=until,
        unread=unread,
        limit=limit,
        starting_after=starting_after,
        ending_before=ending_before,
        expand=expand,
        include=include,
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
    limit: int | Unset = 10,
    starting_after: str | Unset = UNSET,
    ending_before: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
    include: list[GetV1ContentFeedItemsIncludeItem] | Unset = UNSET,
) -> GetV1ContentFeedItemsResponse200 | StripeError | None:
    """List the caller's activity feed (filterable, paginated)

     Replaces GET /content/feed, GET /content/feed/unread-count (include unread_count).

    Args:
        entity_type (str | Unset):
        action (str | Unset):
        source (str | Unset):
        since (str | Unset):
        until (str | Unset):
        unread (str | Unset):
        limit (int | Unset):  Default: 10.
        starting_after (str | Unset):
        ending_before (str | Unset):
        expand (list[str] | Unset):
        include (list[GetV1ContentFeedItemsIncludeItem] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1ContentFeedItemsResponse200 | StripeError
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
            limit=limit,
            starting_after=starting_after,
            ending_before=ending_before,
            expand=expand,
            include=include,
        )
    ).parsed
