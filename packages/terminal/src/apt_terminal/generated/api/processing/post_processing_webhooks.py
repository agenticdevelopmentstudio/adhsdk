from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.ai_processing_webhook_endpoint_created import AiProcessingWebhookEndpointCreated
from ...models.error import Error
from ...models.post_processing_webhooks_body import PostProcessingWebhooksBody
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    body: PostProcessingWebhooksBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/processing/webhooks",
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> AiProcessingWebhookEndpointCreated | Error | None:
    if response.status_code == 201:
        response_201 = AiProcessingWebhookEndpointCreated.from_dict(response.json())

        return response_201

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
) -> Response[AiProcessingWebhookEndpointCreated | Error]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    body: PostProcessingWebhooksBody | Unset = UNSET,
) -> Response[AiProcessingWebhookEndpointCreated | Error]:
    """Register a webhook endpoint

     Register a new outbound webhook target. The signing secret (`secret`) is returned exactly once in
    the response — store it; it cannot be retrieved again. The URL must be https:// and resolve to a
    publicly routable address (SSRF guard).

    Args:
        body (PostProcessingWebhooksBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[AiProcessingWebhookEndpointCreated | Error]
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
    body: PostProcessingWebhooksBody | Unset = UNSET,
) -> AiProcessingWebhookEndpointCreated | Error | None:
    """Register a webhook endpoint

     Register a new outbound webhook target. The signing secret (`secret`) is returned exactly once in
    the response — store it; it cannot be retrieved again. The URL must be https:// and resolve to a
    publicly routable address (SSRF guard).

    Args:
        body (PostProcessingWebhooksBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        AiProcessingWebhookEndpointCreated | Error
    """

    return sync_detailed(
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    body: PostProcessingWebhooksBody | Unset = UNSET,
) -> Response[AiProcessingWebhookEndpointCreated | Error]:
    """Register a webhook endpoint

     Register a new outbound webhook target. The signing secret (`secret`) is returned exactly once in
    the response — store it; it cannot be retrieved again. The URL must be https:// and resolve to a
    publicly routable address (SSRF guard).

    Args:
        body (PostProcessingWebhooksBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[AiProcessingWebhookEndpointCreated | Error]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    body: PostProcessingWebhooksBody | Unset = UNSET,
) -> AiProcessingWebhookEndpointCreated | Error | None:
    """Register a webhook endpoint

     Register a new outbound webhook target. The signing secret (`secret`) is returned exactly once in
    the response — store it; it cannot be retrieved again. The URL must be https:// and resolve to a
    publicly routable address (SSRF guard).

    Args:
        body (PostProcessingWebhooksBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        AiProcessingWebhookEndpointCreated | Error
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
        )
    ).parsed
