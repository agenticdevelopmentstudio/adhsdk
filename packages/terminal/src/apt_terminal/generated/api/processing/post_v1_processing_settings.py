from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.ai_processing_settings import AiProcessingSettings
from ...models.post_v1_processing_settings_response_200 import PostV1ProcessingSettingsResponse200
from ...models.stripe_error import StripeError
from ...types import Response


def _get_kwargs(
    *,
    body: AiProcessingSettings,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/processing/settings",
    }

    _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostV1ProcessingSettingsResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = PostV1ProcessingSettingsResponse200.from_dict(response.json())

        return response_200

    if response.status_code == 400:
        response_400 = StripeError.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = StripeError.from_dict(response.json())

        return response_401

    if response.status_code == 403:
        response_403 = StripeError.from_dict(response.json())

        return response_403

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[PostV1ProcessingSettingsResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    body: AiProcessingSettings,
) -> Response[PostV1ProcessingSettingsResponse200 | StripeError]:
    """Update AI processing settings (admin)

     Sets the node log retention window (server-bag ai_processing.node_log_retention_days).

    Replaces PUT /processing/admin/settings.

    Args:
        body (AiProcessingSettings):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1ProcessingSettingsResponse200 | StripeError]
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
    body: AiProcessingSettings,
) -> PostV1ProcessingSettingsResponse200 | StripeError | None:
    """Update AI processing settings (admin)

     Sets the node log retention window (server-bag ai_processing.node_log_retention_days).

    Replaces PUT /processing/admin/settings.

    Args:
        body (AiProcessingSettings):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1ProcessingSettingsResponse200 | StripeError
    """

    return sync_detailed(
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    body: AiProcessingSettings,
) -> Response[PostV1ProcessingSettingsResponse200 | StripeError]:
    """Update AI processing settings (admin)

     Sets the node log retention window (server-bag ai_processing.node_log_retention_days).

    Replaces PUT /processing/admin/settings.

    Args:
        body (AiProcessingSettings):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1ProcessingSettingsResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    body: AiProcessingSettings,
) -> PostV1ProcessingSettingsResponse200 | StripeError | None:
    """Update AI processing settings (admin)

     Sets the node log retention window (server-bag ai_processing.node_log_retention_days).

    Replaces PUT /processing/admin/settings.

    Args:
        body (AiProcessingSettings):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1ProcessingSettingsResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
        )
    ).parsed
