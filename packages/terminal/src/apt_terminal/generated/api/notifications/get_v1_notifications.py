from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.get_v1_notifications_include_item import GetV1NotificationsIncludeItem
from ...models.get_v1_notifications_response_200 import GetV1NotificationsResponse200
from ...models.get_v1_notifications_status import GetV1NotificationsStatus
from ...models.stripe_error import StripeError
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    category: list[str] | Unset = UNSET,
    status: GetV1NotificationsStatus | Unset = GetV1NotificationsStatus.INBOX,
    read: bool | Unset = UNSET,
    limit: int | Unset = 10,
    starting_after: str | Unset = UNSET,
    ending_before: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
    include: list[GetV1NotificationsIncludeItem] | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    json_category: list[str] | Unset = UNSET
    if not isinstance(category, Unset):
        json_category = category

    params["category"] = json_category

    json_status: str | Unset = UNSET
    if not isinstance(status, Unset):
        json_status = status.value

    params["status"] = json_status

    params["read"] = read

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
        "url": "/v1/notifications",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> GetV1NotificationsResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = GetV1NotificationsResponse200.from_dict(response.json())

        return response_200

    if response.status_code == 401:
        response_401 = StripeError.from_dict(response.json())

        return response_401

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[GetV1NotificationsResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    category: list[str] | Unset = UNSET,
    status: GetV1NotificationsStatus | Unset = GetV1NotificationsStatus.INBOX,
    read: bool | Unset = UNSET,
    limit: int | Unset = 10,
    starting_after: str | Unset = UNSET,
    ending_before: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
    include: list[GetV1NotificationsIncludeItem] | Unset = UNSET,
) -> Response[GetV1NotificationsResponse200 | StripeError]:
    """List the caller's in-app notifications (paginated, filterable)

     Replaces GET /notifications, GET /notifications/unread-count (include unread_count).

    Args:
        category (list[str] | Unset):
        status (GetV1NotificationsStatus | Unset):  Default: GetV1NotificationsStatus.INBOX.
        read (bool | Unset):
        limit (int | Unset):  Default: 10.
        starting_after (str | Unset):
        ending_before (str | Unset):
        expand (list[str] | Unset):
        include (list[GetV1NotificationsIncludeItem] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1NotificationsResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        category=category,
        status=status,
        read=read,
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
    category: list[str] | Unset = UNSET,
    status: GetV1NotificationsStatus | Unset = GetV1NotificationsStatus.INBOX,
    read: bool | Unset = UNSET,
    limit: int | Unset = 10,
    starting_after: str | Unset = UNSET,
    ending_before: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
    include: list[GetV1NotificationsIncludeItem] | Unset = UNSET,
) -> GetV1NotificationsResponse200 | StripeError | None:
    """List the caller's in-app notifications (paginated, filterable)

     Replaces GET /notifications, GET /notifications/unread-count (include unread_count).

    Args:
        category (list[str] | Unset):
        status (GetV1NotificationsStatus | Unset):  Default: GetV1NotificationsStatus.INBOX.
        read (bool | Unset):
        limit (int | Unset):  Default: 10.
        starting_after (str | Unset):
        ending_before (str | Unset):
        expand (list[str] | Unset):
        include (list[GetV1NotificationsIncludeItem] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1NotificationsResponse200 | StripeError
    """

    return sync_detailed(
        client=client,
        category=category,
        status=status,
        read=read,
        limit=limit,
        starting_after=starting_after,
        ending_before=ending_before,
        expand=expand,
        include=include,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    category: list[str] | Unset = UNSET,
    status: GetV1NotificationsStatus | Unset = GetV1NotificationsStatus.INBOX,
    read: bool | Unset = UNSET,
    limit: int | Unset = 10,
    starting_after: str | Unset = UNSET,
    ending_before: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
    include: list[GetV1NotificationsIncludeItem] | Unset = UNSET,
) -> Response[GetV1NotificationsResponse200 | StripeError]:
    """List the caller's in-app notifications (paginated, filterable)

     Replaces GET /notifications, GET /notifications/unread-count (include unread_count).

    Args:
        category (list[str] | Unset):
        status (GetV1NotificationsStatus | Unset):  Default: GetV1NotificationsStatus.INBOX.
        read (bool | Unset):
        limit (int | Unset):  Default: 10.
        starting_after (str | Unset):
        ending_before (str | Unset):
        expand (list[str] | Unset):
        include (list[GetV1NotificationsIncludeItem] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1NotificationsResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        category=category,
        status=status,
        read=read,
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
    category: list[str] | Unset = UNSET,
    status: GetV1NotificationsStatus | Unset = GetV1NotificationsStatus.INBOX,
    read: bool | Unset = UNSET,
    limit: int | Unset = 10,
    starting_after: str | Unset = UNSET,
    ending_before: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
    include: list[GetV1NotificationsIncludeItem] | Unset = UNSET,
) -> GetV1NotificationsResponse200 | StripeError | None:
    """List the caller's in-app notifications (paginated, filterable)

     Replaces GET /notifications, GET /notifications/unread-count (include unread_count).

    Args:
        category (list[str] | Unset):
        status (GetV1NotificationsStatus | Unset):  Default: GetV1NotificationsStatus.INBOX.
        read (bool | Unset):
        limit (int | Unset):  Default: 10.
        starting_after (str | Unset):
        ending_before (str | Unset):
        expand (list[str] | Unset):
        include (list[GetV1NotificationsIncludeItem] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1NotificationsResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            client=client,
            category=category,
            status=status,
            read=read,
            limit=limit,
            starting_after=starting_after,
            ending_before=ending_before,
            expand=expand,
            include=include,
        )
    ).parsed
