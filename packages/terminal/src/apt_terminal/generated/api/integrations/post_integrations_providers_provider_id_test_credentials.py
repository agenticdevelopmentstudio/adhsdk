from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.integration_test_result import IntegrationTestResult
from ...models.post_integrations_providers_provider_id_test_credentials_body import (
    PostIntegrationsProvidersProviderIdTestCredentialsBody,
)
from ...models.problem_details import ProblemDetails
from ...types import UNSET, Response, Unset


def _get_kwargs(
    provider_id: str,
    *,
    body: PostIntegrationsProvidersProviderIdTestCredentialsBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/integrations/providers/{provider_id}/test-credentials".format(
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
) -> IntegrationTestResult | ProblemDetails | None:
    if response.status_code == 200:
        response_200 = IntegrationTestResult.from_dict(response.json())

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
) -> Response[IntegrationTestResult | ProblemDetails]:
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
    body: PostIntegrationsProvidersProviderIdTestCredentialsBody | Unset = UNSET,
) -> Response[IntegrationTestResult | ProblemDetails]:
    """Test credentials that have NOT been saved

     The Test button in an Add-integration dialog, where there is no row to address yet. WRITES NOTHING —
    no config, no connection, no cache — which is the whole difference between this and POST …/provider-
    configs/{configId}/test, where testing a GitHub App deliberately adopts as it verifies.

    Send the draft in whichever shape the provider takes: `clientId`/`clientSecret` for an OAuth or
    GitHub-App provider, `fields` for one with declared config fields. A field the provider does not
    declare is a 400, exactly as it would be on save.

    SECRETS ARE WRITE-ONLY, so the secret box of an EDIT dialog is blank on screen even though a
    credential is stored. Pass `providerConfigId` and a blank secret to test the stored one: without it
    the probe would present an empty secret and report a failure that says nothing about the integration
    being edited.

    A refused credential is 200 with `ok: false`. See IntegrationTestResult.

    Args:
        provider_id (str):
        body (PostIntegrationsProvidersProviderIdTestCredentialsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[IntegrationTestResult | ProblemDetails]
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
    body: PostIntegrationsProvidersProviderIdTestCredentialsBody | Unset = UNSET,
) -> IntegrationTestResult | ProblemDetails | None:
    """Test credentials that have NOT been saved

     The Test button in an Add-integration dialog, where there is no row to address yet. WRITES NOTHING —
    no config, no connection, no cache — which is the whole difference between this and POST …/provider-
    configs/{configId}/test, where testing a GitHub App deliberately adopts as it verifies.

    Send the draft in whichever shape the provider takes: `clientId`/`clientSecret` for an OAuth or
    GitHub-App provider, `fields` for one with declared config fields. A field the provider does not
    declare is a 400, exactly as it would be on save.

    SECRETS ARE WRITE-ONLY, so the secret box of an EDIT dialog is blank on screen even though a
    credential is stored. Pass `providerConfigId` and a blank secret to test the stored one: without it
    the probe would present an empty secret and report a failure that says nothing about the integration
    being edited.

    A refused credential is 200 with `ok: false`. See IntegrationTestResult.

    Args:
        provider_id (str):
        body (PostIntegrationsProvidersProviderIdTestCredentialsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        IntegrationTestResult | ProblemDetails
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
    body: PostIntegrationsProvidersProviderIdTestCredentialsBody | Unset = UNSET,
) -> Response[IntegrationTestResult | ProblemDetails]:
    """Test credentials that have NOT been saved

     The Test button in an Add-integration dialog, where there is no row to address yet. WRITES NOTHING —
    no config, no connection, no cache — which is the whole difference between this and POST …/provider-
    configs/{configId}/test, where testing a GitHub App deliberately adopts as it verifies.

    Send the draft in whichever shape the provider takes: `clientId`/`clientSecret` for an OAuth or
    GitHub-App provider, `fields` for one with declared config fields. A field the provider does not
    declare is a 400, exactly as it would be on save.

    SECRETS ARE WRITE-ONLY, so the secret box of an EDIT dialog is blank on screen even though a
    credential is stored. Pass `providerConfigId` and a blank secret to test the stored one: without it
    the probe would present an empty secret and report a failure that says nothing about the integration
    being edited.

    A refused credential is 200 with `ok: false`. See IntegrationTestResult.

    Args:
        provider_id (str):
        body (PostIntegrationsProvidersProviderIdTestCredentialsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[IntegrationTestResult | ProblemDetails]
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
    body: PostIntegrationsProvidersProviderIdTestCredentialsBody | Unset = UNSET,
) -> IntegrationTestResult | ProblemDetails | None:
    """Test credentials that have NOT been saved

     The Test button in an Add-integration dialog, where there is no row to address yet. WRITES NOTHING —
    no config, no connection, no cache — which is the whole difference between this and POST …/provider-
    configs/{configId}/test, where testing a GitHub App deliberately adopts as it verifies.

    Send the draft in whichever shape the provider takes: `clientId`/`clientSecret` for an OAuth or
    GitHub-App provider, `fields` for one with declared config fields. A field the provider does not
    declare is a 400, exactly as it would be on save.

    SECRETS ARE WRITE-ONLY, so the secret box of an EDIT dialog is blank on screen even though a
    credential is stored. Pass `providerConfigId` and a blank secret to test the stored one: without it
    the probe would present an empty secret and report a failure that says nothing about the integration
    being edited.

    A refused credential is 200 with `ok: false`. See IntegrationTestResult.

    Args:
        provider_id (str):
        body (PostIntegrationsProvidersProviderIdTestCredentialsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        IntegrationTestResult | ProblemDetails
    """

    return (
        await asyncio_detailed(
            provider_id=provider_id,
            client=client,
            body=body,
        )
    ).parsed
