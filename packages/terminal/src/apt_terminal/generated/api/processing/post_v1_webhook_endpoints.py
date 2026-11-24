from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.post_v1_webhook_endpoints_body import PostV1WebhookEndpointsBody
from ...models.post_v1_webhook_endpoints_response_201 import PostV1WebhookEndpointsResponse201
from ...models.stripe_error import StripeError
from ...types import Response


def _get_kwargs(
    *,
    body: PostV1WebhookEndpointsBody,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/webhook_endpoints",
    }

    _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostV1WebhookEndpointsResponse201 | StripeError | None:
    if response.status_code == 201:
        response_201 = PostV1WebhookEndpointsResponse201.from_dict(response.json())

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
) -> Response[PostV1WebhookEndpointsResponse201 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    body: PostV1WebhookEndpointsBody,
) -> Response[PostV1WebhookEndpointsResponse201 | StripeError]:
    """Register a webhook endpoint

     Register a new outbound webhook target. The signing secret (`secret`) is returned exactly once in
    the response — store it; it cannot be retrieved again. The URL must be https:// and resolve to a
    publicly routable address (SSRF guard).

    Replaces POST /processing/webhooks.

    Args:
        body (PostV1WebhookEndpointsBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1WebhookEndpointsResponse201 | StripeError]
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
    body: PostV1WebhookEndpointsBody,
) -> PostV1WebhookEndpointsResponse201 | StripeError | None:
    """Register a webhook endpoint

     Register a new outbound webhook target. The signing secret (`secret`) is returned exactly once in
    the response — store it; it cannot be retrieved again. The URL must be https:// and resolve to a
    publicly routable address (SSRF guard).

    Replaces POST /processing/webhooks.

    Args:
        body (PostV1WebhookEndpointsBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1WebhookEndpointsResponse201 | StripeError
    """

    return sync_detailed(
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    body: PostV1WebhookEndpointsBody,
) -> Response[PostV1WebhookEndpointsResponse201 | StripeError]:
    """Register a webhook endpoint

     Register a new outbound webhook target. The signing secret (`secret`) is returned exactly once in
    the response — store it; it cannot be retrieved again. The URL must be https:// and resolve to a
    publicly routable address (SSRF guard).

    Replaces POST /processing/webhooks.

    Args:
        body (PostV1WebhookEndpointsBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1WebhookEndpointsResponse201 | StripeError]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    body: PostV1WebhookEndpointsBody,
) -> PostV1WebhookEndpointsResponse201 | StripeError | None:
    """Register a webhook endpoint

     Register a new outbound webhook target. The signing secret (`secret`) is returned exactly once in
    the response — store it; it cannot be retrieved again. The URL must be https:// and resolve to a
    publicly routable address (SSRF guard).

    Replaces POST /processing/webhooks.

    Args:
        body (PostV1WebhookEndpointsBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1WebhookEndpointsResponse201 | StripeError
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
        )
    ).parsed
