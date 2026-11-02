from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.get_integrations_providers_provider_id_install_url_response_200 import (
    GetIntegrationsProvidersProviderIdInstallUrlResponse200,
)
from ...models.problem_details import ProblemDetails
from ...types import UNSET, Response, Unset


def _get_kwargs(
    provider_id: str,
    *,
    ecosystem_id: str,
    service_type: str | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["ecosystemId"] = ecosystem_id

    params["serviceType"] = service_type

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/integrations/providers/{provider_id}/install-url".format(
            provider_id=quote(str(provider_id), safe=""),
        ),
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> GetIntegrationsProvidersProviderIdInstallUrlResponse200 | ProblemDetails | None:
    if response.status_code == 200:
        response_200 = GetIntegrationsProvidersProviderIdInstallUrlResponse200.from_dict(
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

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[GetIntegrationsProvidersProviderIdInstallUrlResponse200 | ProblemDetails]:
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
    ecosystem_id: str,
    service_type: str | Unset = UNSET,
) -> Response[GetIntegrationsProvidersProviderIdInstallUrlResponse200 | ProblemDetails]:
    """Get the app-installation URL for a provider

     Only valid for github_app providers (400 otherwise). 404 for an unknown provider. The URL points at
    the provider's own installation page, where the installer picks the account and the repositories;
    the app returns to the setup URL configured on the app itself, so no redirectUri is taken. The
    caller must manage the target ecosystem `ecosystemId` (400 when omitted; 404/403 when unknown / not
    the caller's).

    Args:
        provider_id (str):
        ecosystem_id (str):
        service_type (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetIntegrationsProvidersProviderIdInstallUrlResponse200 | ProblemDetails]
    """

    kwargs = _get_kwargs(
        provider_id=provider_id,
        ecosystem_id=ecosystem_id,
        service_type=service_type,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    provider_id: str,
    *,
    client: AuthenticatedClient,
    ecosystem_id: str,
    service_type: str | Unset = UNSET,
) -> GetIntegrationsProvidersProviderIdInstallUrlResponse200 | ProblemDetails | None:
    """Get the app-installation URL for a provider

     Only valid for github_app providers (400 otherwise). 404 for an unknown provider. The URL points at
    the provider's own installation page, where the installer picks the account and the repositories;
    the app returns to the setup URL configured on the app itself, so no redirectUri is taken. The
    caller must manage the target ecosystem `ecosystemId` (400 when omitted; 404/403 when unknown / not
    the caller's).

    Args:
        provider_id (str):
        ecosystem_id (str):
        service_type (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetIntegrationsProvidersProviderIdInstallUrlResponse200 | ProblemDetails
    """

    return sync_detailed(
        provider_id=provider_id,
        client=client,
        ecosystem_id=ecosystem_id,
        service_type=service_type,
    ).parsed


async def asyncio_detailed(
    provider_id: str,
    *,
    client: AuthenticatedClient,
    ecosystem_id: str,
    service_type: str | Unset = UNSET,
) -> Response[GetIntegrationsProvidersProviderIdInstallUrlResponse200 | ProblemDetails]:
    """Get the app-installation URL for a provider

     Only valid for github_app providers (400 otherwise). 404 for an unknown provider. The URL points at
    the provider's own installation page, where the installer picks the account and the repositories;
    the app returns to the setup URL configured on the app itself, so no redirectUri is taken. The
    caller must manage the target ecosystem `ecosystemId` (400 when omitted; 404/403 when unknown / not
    the caller's).

    Args:
        provider_id (str):
        ecosystem_id (str):
        service_type (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetIntegrationsProvidersProviderIdInstallUrlResponse200 | ProblemDetails]
    """

    kwargs = _get_kwargs(
        provider_id=provider_id,
        ecosystem_id=ecosystem_id,
        service_type=service_type,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    provider_id: str,
    *,
    client: AuthenticatedClient,
    ecosystem_id: str,
    service_type: str | Unset = UNSET,
) -> GetIntegrationsProvidersProviderIdInstallUrlResponse200 | ProblemDetails | None:
    """Get the app-installation URL for a provider

     Only valid for github_app providers (400 otherwise). 404 for an unknown provider. The URL points at
    the provider's own installation page, where the installer picks the account and the repositories;
    the app returns to the setup URL configured on the app itself, so no redirectUri is taken. The
    caller must manage the target ecosystem `ecosystemId` (400 when omitted; 404/403 when unknown / not
    the caller's).

    Args:
        provider_id (str):
        ecosystem_id (str):
        service_type (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetIntegrationsProvidersProviderIdInstallUrlResponse200 | ProblemDetails
    """

    return (
        await asyncio_detailed(
            provider_id=provider_id,
            client=client,
            ecosystem_id=ecosystem_id,
            service_type=service_type,
        )
    ).parsed
