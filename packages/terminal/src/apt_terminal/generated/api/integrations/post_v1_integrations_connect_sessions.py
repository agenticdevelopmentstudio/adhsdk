from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.post_v1_integrations_connect_sessions_body import (
    PostV1IntegrationsConnectSessionsBody,
)
from ...models.post_v1_integrations_connect_sessions_response_200 import (
    PostV1IntegrationsConnectSessionsResponse200,
)
from ...models.stripe_error import StripeError
from ...types import Response


def _get_kwargs(
    *,
    body: PostV1IntegrationsConnectSessionsBody,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/integrations/connect_sessions",
    }

    _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostV1IntegrationsConnectSessionsResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = PostV1IntegrationsConnectSessionsResponse200.from_dict(response.json())

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

    if response.status_code == 404:
        response_404 = StripeError.from_dict(response.json())

        return response_404

    if response.status_code == 503:
        response_503 = StripeError.from_dict(response.json())

        return response_503

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[PostV1IntegrationsConnectSessionsResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    body: PostV1IntegrationsConnectSessionsBody,
) -> Response[PostV1IntegrationsConnectSessionsResponse200 | StripeError]:
    """Connect an integration (polymorphic by auth method)

     Finishes any auth method's connect flow and persists the connection under the target ecosystem
    `ecosystemId` the client names; the caller must manage it (404/403 otherwise). Returns the redacted
    connection (tokens never echoed).

    Replaces POST /integrations/connect, POST /integrations/me/connect, GET
    /integrations/me/providers/{providerId}/auth-url, GET /integrations/providers/{providerId}/auth-url,
    GET /integrations/providers/{providerId}/install-url, POST
    /integrations/providers/{providerId}/link-token.

    Args:
        body (PostV1IntegrationsConnectSessionsBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1IntegrationsConnectSessionsResponse200 | StripeError]
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
    body: PostV1IntegrationsConnectSessionsBody,
) -> PostV1IntegrationsConnectSessionsResponse200 | StripeError | None:
    """Connect an integration (polymorphic by auth method)

     Finishes any auth method's connect flow and persists the connection under the target ecosystem
    `ecosystemId` the client names; the caller must manage it (404/403 otherwise). Returns the redacted
    connection (tokens never echoed).

    Replaces POST /integrations/connect, POST /integrations/me/connect, GET
    /integrations/me/providers/{providerId}/auth-url, GET /integrations/providers/{providerId}/auth-url,
    GET /integrations/providers/{providerId}/install-url, POST
    /integrations/providers/{providerId}/link-token.

    Args:
        body (PostV1IntegrationsConnectSessionsBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1IntegrationsConnectSessionsResponse200 | StripeError
    """

    return sync_detailed(
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    body: PostV1IntegrationsConnectSessionsBody,
) -> Response[PostV1IntegrationsConnectSessionsResponse200 | StripeError]:
    """Connect an integration (polymorphic by auth method)

     Finishes any auth method's connect flow and persists the connection under the target ecosystem
    `ecosystemId` the client names; the caller must manage it (404/403 otherwise). Returns the redacted
    connection (tokens never echoed).

    Replaces POST /integrations/connect, POST /integrations/me/connect, GET
    /integrations/me/providers/{providerId}/auth-url, GET /integrations/providers/{providerId}/auth-url,
    GET /integrations/providers/{providerId}/install-url, POST
    /integrations/providers/{providerId}/link-token.

    Args:
        body (PostV1IntegrationsConnectSessionsBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1IntegrationsConnectSessionsResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    body: PostV1IntegrationsConnectSessionsBody,
) -> PostV1IntegrationsConnectSessionsResponse200 | StripeError | None:
    """Connect an integration (polymorphic by auth method)

     Finishes any auth method's connect flow and persists the connection under the target ecosystem
    `ecosystemId` the client names; the caller must manage it (404/403 otherwise). Returns the redacted
    connection (tokens never echoed).

    Replaces POST /integrations/connect, POST /integrations/me/connect, GET
    /integrations/me/providers/{providerId}/auth-url, GET /integrations/providers/{providerId}/auth-url,
    GET /integrations/providers/{providerId}/install-url, POST
    /integrations/providers/{providerId}/link-token.

    Args:
        body (PostV1IntegrationsConnectSessionsBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1IntegrationsConnectSessionsResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
        )
    ).parsed
