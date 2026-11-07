from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.post_integrations_me_providers_provider_id_register_instance_body import (
    PostIntegrationsMeProvidersProviderIdRegisterInstanceBody,
)
from ...models.post_integrations_me_providers_provider_id_register_instance_response_200 import (
    PostIntegrationsMeProvidersProviderIdRegisterInstanceResponse200,
)
from ...models.problem_details import ProblemDetails
from ...types import UNSET, Response, Unset


def _get_kwargs(
    provider_id: str,
    *,
    body: PostIntegrationsMeProvidersProviderIdRegisterInstanceBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/integrations/me/providers/{provider_id}/register-instance".format(
            provider_id=quote(str(provider_id), safe=""),
        ),
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostIntegrationsMeProvidersProviderIdRegisterInstanceResponse200 | ProblemDetails | None:
    if response.status_code == 200:
        response_200 = PostIntegrationsMeProvidersProviderIdRegisterInstanceResponse200.from_dict(
            response.json()
        )

        return response_200

    if response.status_code == 400:
        response_400 = ProblemDetails.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = ProblemDetails.from_dict(response.json())

        return response_401

    if response.status_code == 403:
        response_403 = ProblemDetails.from_dict(response.json())

        return response_403

    if response.status_code == 404:
        response_404 = ProblemDetails.from_dict(response.json())

        return response_404

    if response.status_code == 503:
        response_503 = ProblemDetails.from_dict(response.json())

        return response_503

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[PostIntegrationsMeProvidersProviderIdRegisterInstanceResponse200 | ProblemDetails]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    provider_id: str,
    *,
    client: AuthenticatedClient,
    body: PostIntegrationsMeProvidersProviderIdRegisterInstanceBody | Unset = UNSET,
) -> Response[PostIntegrationsMeProvidersProviderIdRegisterInstanceResponse200 | ProblemDetails]:
    """Register a self-hosted OAuth instance (end user)

     oauth_instance providers only (400 otherwise). The body is strict: `ecosystemId` and
    `providerConfigId` are refused. `serviceType` must be one the provider offers (400 otherwise).

    Args:
        provider_id (str):
        body (PostIntegrationsMeProvidersProviderIdRegisterInstanceBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostIntegrationsMeProvidersProviderIdRegisterInstanceResponse200 | ProblemDetails]
    """

    kwargs = _get_kwargs(
        provider_id=provider_id,
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    provider_id: str,
    *,
    client: AuthenticatedClient,
    body: PostIntegrationsMeProvidersProviderIdRegisterInstanceBody | Unset = UNSET,
) -> PostIntegrationsMeProvidersProviderIdRegisterInstanceResponse200 | ProblemDetails | None:
    """Register a self-hosted OAuth instance (end user)

     oauth_instance providers only (400 otherwise). The body is strict: `ecosystemId` and
    `providerConfigId` are refused. `serviceType` must be one the provider offers (400 otherwise).

    Args:
        provider_id (str):
        body (PostIntegrationsMeProvidersProviderIdRegisterInstanceBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostIntegrationsMeProvidersProviderIdRegisterInstanceResponse200 | ProblemDetails
    """

    return sync_detailed(
        provider_id=provider_id,
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    provider_id: str,
    *,
    client: AuthenticatedClient,
    body: PostIntegrationsMeProvidersProviderIdRegisterInstanceBody | Unset = UNSET,
) -> Response[PostIntegrationsMeProvidersProviderIdRegisterInstanceResponse200 | ProblemDetails]:
    """Register a self-hosted OAuth instance (end user)

     oauth_instance providers only (400 otherwise). The body is strict: `ecosystemId` and
    `providerConfigId` are refused. `serviceType` must be one the provider offers (400 otherwise).

    Args:
        provider_id (str):
        body (PostIntegrationsMeProvidersProviderIdRegisterInstanceBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostIntegrationsMeProvidersProviderIdRegisterInstanceResponse200 | ProblemDetails]
    """

    kwargs = _get_kwargs(
        provider_id=provider_id,
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    provider_id: str,
    *,
    client: AuthenticatedClient,
    body: PostIntegrationsMeProvidersProviderIdRegisterInstanceBody | Unset = UNSET,
) -> PostIntegrationsMeProvidersProviderIdRegisterInstanceResponse200 | ProblemDetails | None:
    """Register a self-hosted OAuth instance (end user)

     oauth_instance providers only (400 otherwise). The body is strict: `ecosystemId` and
    `providerConfigId` are refused. `serviceType` must be one the provider offers (400 otherwise).

    Args:
        provider_id (str):
        body (PostIntegrationsMeProvidersProviderIdRegisterInstanceBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostIntegrationsMeProvidersProviderIdRegisterInstanceResponse200 | ProblemDetails
    """

    return (
        await asyncio_detailed(
            provider_id=provider_id,
            client=client,
            body=body,
        )
    ).parsed
