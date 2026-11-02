from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.integration_provider_config import IntegrationProviderConfig
from ...models.problem_details import ProblemDetails
from ...models.put_integrations_ecosystems_ecosystem_id_provider_configs_config_id_body import (
    PutIntegrationsEcosystemsEcosystemIdProviderConfigsConfigIdBody,
)
from ...types import UNSET, Response, Unset


def _get_kwargs(
    ecosystem_id: str,
    config_id: str,
    *,
    body: PutIntegrationsEcosystemsEcosystemIdProviderConfigsConfigIdBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "put",
        "url": "/integrations/ecosystems/{ecosystem_id}/provider-configs/{config_id}".format(
            ecosystem_id=quote(str(ecosystem_id), safe=""),
            config_id=quote(str(config_id), safe=""),
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
    if response.status_code == 200:
        response_200 = IntegrationProviderConfig.from_dict(response.json())

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
) -> Response[IntegrationProviderConfig | ProblemDetails]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    ecosystem_id: str,
    config_id: str,
    *,
    client: AuthenticatedClient,
    body: PutIntegrationsEcosystemsEcosystemIdProviderConfigsConfigIdBody | Unset = UNSET,
) -> Response[IntegrationProviderConfig | ProblemDetails]:
    """Update an ecosystem's provider config

     Updates the config addressed by `configId`. OAuth providers REPLACE the non-secret config; api_key
    providers MERGE the submitted fields over the stored config. A blank/absent clientSecret preserves
    the stored encrypted secret, a present one is encrypted at rest; `name` renames the instance (the
    rdid is stable). The change invalidates the resolver cache so the ecosystem's new creds drive its
    flows immediately. 404 when the config is absent or not owned by the ecosystem (403 when the caller
    cannot manage the ecosystem).

    Args:
        ecosystem_id (str):
        config_id (str):
        body (PutIntegrationsEcosystemsEcosystemIdProviderConfigsConfigIdBody | Unset): OAuth
            providers send clientId/scopes/…/clientSecret; api_key providers send the spec-driven
            `fields` map (+ optional `enabled`). `name` (optional) renames the instance. The route
            branches by the stored config's auth method.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[IntegrationProviderConfig | ProblemDetails]
    """

    kwargs = _get_kwargs(
        ecosystem_id=ecosystem_id,
        config_id=config_id,
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    ecosystem_id: str,
    config_id: str,
    *,
    client: AuthenticatedClient,
    body: PutIntegrationsEcosystemsEcosystemIdProviderConfigsConfigIdBody | Unset = UNSET,
) -> IntegrationProviderConfig | ProblemDetails | None:
    """Update an ecosystem's provider config

     Updates the config addressed by `configId`. OAuth providers REPLACE the non-secret config; api_key
    providers MERGE the submitted fields over the stored config. A blank/absent clientSecret preserves
    the stored encrypted secret, a present one is encrypted at rest; `name` renames the instance (the
    rdid is stable). The change invalidates the resolver cache so the ecosystem's new creds drive its
    flows immediately. 404 when the config is absent or not owned by the ecosystem (403 when the caller
    cannot manage the ecosystem).

    Args:
        ecosystem_id (str):
        config_id (str):
        body (PutIntegrationsEcosystemsEcosystemIdProviderConfigsConfigIdBody | Unset): OAuth
            providers send clientId/scopes/…/clientSecret; api_key providers send the spec-driven
            `fields` map (+ optional `enabled`). `name` (optional) renames the instance. The route
            branches by the stored config's auth method.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        IntegrationProviderConfig | ProblemDetails
    """

    return sync_detailed(
        ecosystem_id=ecosystem_id,
        config_id=config_id,
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    ecosystem_id: str,
    config_id: str,
    *,
    client: AuthenticatedClient,
    body: PutIntegrationsEcosystemsEcosystemIdProviderConfigsConfigIdBody | Unset = UNSET,
) -> Response[IntegrationProviderConfig | ProblemDetails]:
    """Update an ecosystem's provider config

     Updates the config addressed by `configId`. OAuth providers REPLACE the non-secret config; api_key
    providers MERGE the submitted fields over the stored config. A blank/absent clientSecret preserves
    the stored encrypted secret, a present one is encrypted at rest; `name` renames the instance (the
    rdid is stable). The change invalidates the resolver cache so the ecosystem's new creds drive its
    flows immediately. 404 when the config is absent or not owned by the ecosystem (403 when the caller
    cannot manage the ecosystem).

    Args:
        ecosystem_id (str):
        config_id (str):
        body (PutIntegrationsEcosystemsEcosystemIdProviderConfigsConfigIdBody | Unset): OAuth
            providers send clientId/scopes/…/clientSecret; api_key providers send the spec-driven
            `fields` map (+ optional `enabled`). `name` (optional) renames the instance. The route
            branches by the stored config's auth method.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[IntegrationProviderConfig | ProblemDetails]
    """

    kwargs = _get_kwargs(
        ecosystem_id=ecosystem_id,
        config_id=config_id,
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    ecosystem_id: str,
    config_id: str,
    *,
    client: AuthenticatedClient,
    body: PutIntegrationsEcosystemsEcosystemIdProviderConfigsConfigIdBody | Unset = UNSET,
) -> IntegrationProviderConfig | ProblemDetails | None:
    """Update an ecosystem's provider config

     Updates the config addressed by `configId`. OAuth providers REPLACE the non-secret config; api_key
    providers MERGE the submitted fields over the stored config. A blank/absent clientSecret preserves
    the stored encrypted secret, a present one is encrypted at rest; `name` renames the instance (the
    rdid is stable). The change invalidates the resolver cache so the ecosystem's new creds drive its
    flows immediately. 404 when the config is absent or not owned by the ecosystem (403 when the caller
    cannot manage the ecosystem).

    Args:
        ecosystem_id (str):
        config_id (str):
        body (PutIntegrationsEcosystemsEcosystemIdProviderConfigsConfigIdBody | Unset): OAuth
            providers send clientId/scopes/…/clientSecret; api_key providers send the spec-driven
            `fields` map (+ optional `enabled`). `name` (optional) renames the instance. The route
            branches by the stored config's auth method.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        IntegrationProviderConfig | ProblemDetails
    """

    return (
        await asyncio_detailed(
            ecosystem_id=ecosystem_id,
            config_id=config_id,
            client=client,
            body=body,
        )
    ).parsed
