from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.post_v1_billing_tier_entitlements_body import PostV1BillingTierEntitlementsBody
from ...models.post_v1_billing_tier_entitlements_response_201 import (
    PostV1BillingTierEntitlementsResponse201,
)
from ...models.stripe_error import StripeError
from ...types import Response


def _get_kwargs(
    *,
    body: PostV1BillingTierEntitlementsBody,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/billing/tier_entitlements",
    }

    _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostV1BillingTierEntitlementsResponse201 | StripeError | None:
    if response.status_code == 201:
        response_201 = PostV1BillingTierEntitlementsResponse201.from_dict(response.json())

        return response_201

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
) -> Response[PostV1BillingTierEntitlementsResponse201 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    body: PostV1BillingTierEntitlementsBody,
) -> Response[PostV1BillingTierEntitlementsResponse201 | StripeError]:
    """Create tier_entitlements

     Replaces POST /billing/tier-entitlements.

    Args:
        body (PostV1BillingTierEntitlementsBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1BillingTierEntitlementsResponse201 | StripeError]
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
    body: PostV1BillingTierEntitlementsBody,
) -> PostV1BillingTierEntitlementsResponse201 | StripeError | None:
    """Create tier_entitlements

     Replaces POST /billing/tier-entitlements.

    Args:
        body (PostV1BillingTierEntitlementsBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1BillingTierEntitlementsResponse201 | StripeError
    """

    return sync_detailed(
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    body: PostV1BillingTierEntitlementsBody,
) -> Response[PostV1BillingTierEntitlementsResponse201 | StripeError]:
    """Create tier_entitlements

     Replaces POST /billing/tier-entitlements.

    Args:
        body (PostV1BillingTierEntitlementsBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1BillingTierEntitlementsResponse201 | StripeError]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    body: PostV1BillingTierEntitlementsBody,
) -> PostV1BillingTierEntitlementsResponse201 | StripeError | None:
    """Create tier_entitlements

     Replaces POST /billing/tier-entitlements.

    Args:
        body (PostV1BillingTierEntitlementsBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1BillingTierEntitlementsResponse201 | StripeError
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
        )
    ).parsed
