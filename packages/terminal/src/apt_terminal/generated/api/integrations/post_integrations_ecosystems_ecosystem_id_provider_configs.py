from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.integration_provider_config import IntegrationProviderConfig
from ...models.post_integrations_ecosystems_ecosystem_id_provider_configs_body import (
    PostIntegrationsEcosystemsEcosystemIdProviderConfigsBody,
)
from ...models.problem_details import ProblemDetails
from ...types import UNSET, Response, Unset


def _get_kwargs(
    ecosystem_id: str,
    *,
    body: PostIntegrationsEcosystemsEcosystemIdProviderConfigsBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/integrations/ecosystems/{ecosystem_id}/provider-configs".format(
            ecosystem_id=quote(str(ecosystem_id), safe=""),
        ),
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> IntegrationProviderConfig | ProblemDetails | None:
    if response.status_code == 201:
        response_201 = IntegrationProviderConfig.from_dict(response.json())

        return response_201

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
) -> Response[IntegrationProviderConfig | ProblemDetails]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    ecosystem_id: str,
    *,
    client: AuthenticatedClient,
    body: PostIntegrationsEcosystemsEcosystemIdProviderConfigsBody | Unset = UNSET,
) -> Response[IntegrationProviderConfig | ProblemDetails]:
    """Create a new named provider config for an ecosystem

     Creates a NEW named provider-config instance and mints its `integration` rdid. rdid is the only
    uniqueness gate — a SECOND config for the same provider (different name) is allowed. OAuth providers
    send clientId/scopes/…/clientSecret; api_key providers send the spec-driven `fields` map (+ optional
    `enabled`); the route splits secret vs non-secret by auth method. 404 for an unknown provider. The
    ecosystemId must be the caller's own ecosystem (403 otherwise). Returns the masked row (incl. id +
    rdid + name).

    Args:
        ecosystem_id (str):
        body (PostIntegrationsEcosystemsEcosystemIdProviderConfigsBody | Unset): `providerId` +
            `name` identify the new instance; the remaining keys are the provider-specific config,
            validated by auth method.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[IntegrationProviderConfig | ProblemDetails]
    """

    kwargs = _get_kwargs(
        ecosystem_id=ecosystem_id,
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    ecosystem_id: str,
    *,
    client: AuthenticatedClient,
    body: PostIntegrationsEcosystemsEcosystemIdProviderConfigsBody | Unset = UNSET,
) -> IntegrationProviderConfig | ProblemDetails | None:
    """Create a new named provider config for an ecosystem

     Creates a NEW named provider-config instance and mints its `integration` rdid. rdid is the only
    uniqueness gate — a SECOND config for the same provider (different name) is allowed. OAuth providers
    send clientId/scopes/…/clientSecret; api_key providers send the spec-driven `fields` map (+ optional
    `enabled`); the route splits secret vs non-secret by auth method. 404 for an unknown provider. The
    ecosystemId must be the caller's own ecosystem (403 otherwise). Returns the masked row (incl. id +
    rdid + name).

    Args:
        ecosystem_id (str):
        body (PostIntegrationsEcosystemsEcosystemIdProviderConfigsBody | Unset): `providerId` +
            `name` identify the new instance; the remaining keys are the provider-specific config,
            validated by auth method.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        IntegrationProviderConfig | ProblemDetails
    """

    return sync_detailed(
        ecosystem_id=ecosystem_id,
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    ecosystem_id: str,
    *,
    client: AuthenticatedClient,
    body: PostIntegrationsEcosystemsEcosystemIdProviderConfigsBody | Unset = UNSET,
) -> Response[IntegrationProviderConfig | ProblemDetails]:
    """Create a new named provider config for an ecosystem

     Creates a NEW named provider-config instance and mints its `integration` rdid. rdid is the only
    uniqueness gate — a SECOND config for the same provider (different name) is allowed. OAuth providers
    send clientId/scopes/…/clientSecret; api_key providers send the spec-driven `fields` map (+ optional
    `enabled`); the route splits secret vs non-secret by auth method. 404 for an unknown provider. The
    ecosystemId must be the caller's own ecosystem (403 otherwise). Returns the masked row (incl. id +
    rdid + name).

    Args:
        ecosystem_id (str):
        body (PostIntegrationsEcosystemsEcosystemIdProviderConfigsBody | Unset): `providerId` +
            `name` identify the new instance; the remaining keys are the provider-specific config,
            validated by auth method.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[IntegrationProviderConfig | ProblemDetails]
    """

    kwargs = _get_kwargs(
        ecosystem_id=ecosystem_id,
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    ecosystem_id: str,
    *,
    client: AuthenticatedClient,
    body: PostIntegrationsEcosystemsEcosystemIdProviderConfigsBody | Unset = UNSET,
) -> IntegrationProviderConfig | ProblemDetails | None:
    """Create a new named provider config for an ecosystem

     Creates a NEW named provider-config instance and mints its `integration` rdid. rdid is the only
    uniqueness gate — a SECOND config for the same provider (different name) is allowed. OAuth providers
    send clientId/scopes/…/clientSecret; api_key providers send the spec-driven `fields` map (+ optional
    `enabled`); the route splits secret vs non-secret by auth method. 404 for an unknown provider. The
    ecosystemId must be the caller's own ecosystem (403 otherwise). Returns the masked row (incl. id +
    rdid + name).

    Args:
        ecosystem_id (str):
        body (PostIntegrationsEcosystemsEcosystemIdProviderConfigsBody | Unset): `providerId` +
            `name` identify the new instance; the remaining keys are the provider-specific config,
            validated by auth method.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        IntegrationProviderConfig | ProblemDetails
    """

    return (
        await asyncio_detailed(
            ecosystem_id=ecosystem_id,
            client=client,
            body=body,
        )
    ).parsed
