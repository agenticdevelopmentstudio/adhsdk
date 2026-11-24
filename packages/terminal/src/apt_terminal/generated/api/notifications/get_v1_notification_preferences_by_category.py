from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.get_v1_notification_preferences_by_category_response_200 import (
    GetV1NotificationPreferencesByCategoryResponse200,
)
from ...models.stripe_error import StripeError
from ...types import UNSET, Response, Unset


def _get_kwargs(
    category: str,
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
        "url": "/v1/notification_preferences/{category}".format(
            category=quote(str(category), safe=""),
        ),
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> GetV1NotificationPreferencesByCategoryResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = GetV1NotificationPreferencesByCategoryResponse200.from_dict(response.json())

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
) -> Response[GetV1NotificationPreferencesByCategoryResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    category: str,
    *,
    client: AuthenticatedClient,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1NotificationPreferencesByCategoryResponse200 | StripeError]:
    """Get the caller's preference for one category (defaults if unset)

     Replaces GET /notifications/preferences/{category}.

    Args:
        category (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1NotificationPreferencesByCategoryResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        category=category,
        expand=expand,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    category: str,
    *,
    client: AuthenticatedClient,
    expand: list[str] | Unset = UNSET,
) -> GetV1NotificationPreferencesByCategoryResponse200 | StripeError | None:
    """Get the caller's preference for one category (defaults if unset)

     Replaces GET /notifications/preferences/{category}.

    Args:
        category (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1NotificationPreferencesByCategoryResponse200 | StripeError
    """

    return sync_detailed(
        category=category,
        client=client,
        expand=expand,
    ).parsed


async def asyncio_detailed(
    category: str,
    *,
    client: AuthenticatedClient,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1NotificationPreferencesByCategoryResponse200 | StripeError]:
    """Get the caller's preference for one category (defaults if unset)

     Replaces GET /notifications/preferences/{category}.

    Args:
        category (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1NotificationPreferencesByCategoryResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        category=category,
        expand=expand,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    category: str,
    *,
    client: AuthenticatedClient,
    expand: list[str] | Unset = UNSET,
) -> GetV1NotificationPreferencesByCategoryResponse200 | StripeError | None:
    """Get the caller's preference for one category (defaults if unset)

     Replaces GET /notifications/preferences/{category}.

    Args:
        category (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1NotificationPreferencesByCategoryResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            category=category,
            client=client,
            expand=expand,
        )
    ).parsed
