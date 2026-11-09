from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.post_v1_notification_preferences_body_type_0 import (
    PostV1NotificationPreferencesBodyType0,
)
from ...models.post_v1_notification_preferences_body_type_1 import (
    PostV1NotificationPreferencesBodyType1,
)
from ...models.post_v1_notification_preferences_response_200 import (
    PostV1NotificationPreferencesResponse200,
)
from ...models.post_v1_notification_preferences_response_201 import (
    PostV1NotificationPreferencesResponse201,
)
from ...models.stripe_error import StripeError
from ...types import Response


def _get_kwargs(
    *,
    body: PostV1NotificationPreferencesBodyType0 | PostV1NotificationPreferencesBodyType1,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/notification_preferences",
    }

    if isinstance(body, PostV1NotificationPreferencesBodyType0):
        _kwargs["json"] = body.to_dict()
    else:
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> (
    PostV1NotificationPreferencesResponse200
    | PostV1NotificationPreferencesResponse201
    | StripeError
    | None
):
    if response.status_code == 200:
        response_200 = PostV1NotificationPreferencesResponse200.from_dict(response.json())

        return response_200

    if response.status_code == 201:
        response_201 = PostV1NotificationPreferencesResponse201.from_dict(response.json())

        return response_201

    if response.status_code == 400:
        response_400 = StripeError.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = StripeError.from_dict(response.json())

        return response_401

    if response.status_code == 409:
        response_409 = StripeError.from_dict(response.json())

        return response_409

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[
    PostV1NotificationPreferencesResponse200
    | PostV1NotificationPreferencesResponse201
    | StripeError
]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    body: PostV1NotificationPreferencesBodyType0 | PostV1NotificationPreferencesBodyType1,
) -> Response[
    PostV1NotificationPreferencesResponse200
    | PostV1NotificationPreferencesResponse201
    | StripeError
]:
    """Create a notification preference for one category

     Replaces POST /notifications/preferences, PUT /notifications/preferences.

    Args:
        body (PostV1NotificationPreferencesBodyType0 | PostV1NotificationPreferencesBodyType1):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1NotificationPreferencesResponse200 | PostV1NotificationPreferencesResponse201 | StripeError]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    body: PostV1NotificationPreferencesBodyType0 | PostV1NotificationPreferencesBodyType1,
) -> (
    PostV1NotificationPreferencesResponse200
    | PostV1NotificationPreferencesResponse201
    | StripeError
    | None
):
    """Create a notification preference for one category

     Replaces POST /notifications/preferences, PUT /notifications/preferences.

    Args:
        body (PostV1NotificationPreferencesBodyType0 | PostV1NotificationPreferencesBodyType1):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1NotificationPreferencesResponse200 | PostV1NotificationPreferencesResponse201 | StripeError
    """

    return sync_detailed(
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    body: PostV1NotificationPreferencesBodyType0 | PostV1NotificationPreferencesBodyType1,
) -> Response[
    PostV1NotificationPreferencesResponse200
    | PostV1NotificationPreferencesResponse201
    | StripeError
]:
    """Create a notification preference for one category

     Replaces POST /notifications/preferences, PUT /notifications/preferences.

    Args:
        body (PostV1NotificationPreferencesBodyType0 | PostV1NotificationPreferencesBodyType1):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1NotificationPreferencesResponse200 | PostV1NotificationPreferencesResponse201 | StripeError]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    body: PostV1NotificationPreferencesBodyType0 | PostV1NotificationPreferencesBodyType1,
) -> (
    PostV1NotificationPreferencesResponse200
    | PostV1NotificationPreferencesResponse201
    | StripeError
    | None
):
    """Create a notification preference for one category

     Replaces POST /notifications/preferences, PUT /notifications/preferences.

    Args:
        body (PostV1NotificationPreferencesBodyType0 | PostV1NotificationPreferencesBodyType1):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1NotificationPreferencesResponse200 | PostV1NotificationPreferencesResponse201 | StripeError
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
        )
    ).parsed
