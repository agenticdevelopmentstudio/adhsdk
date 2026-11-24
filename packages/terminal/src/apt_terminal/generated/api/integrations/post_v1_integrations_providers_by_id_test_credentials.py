from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.post_v1_integrations_providers_by_id_test_credentials_body import (
    PostV1IntegrationsProvidersByIdTestCredentialsBody,
)
from ...models.post_v1_integrations_providers_by_id_test_credentials_response_200 import (
    PostV1IntegrationsProvidersByIdTestCredentialsResponse200,
)
from ...models.stripe_error import StripeError
from ...types import Response


def _get_kwargs(
    id: str,
    *,
    body: PostV1IntegrationsProvidersByIdTestCredentialsBody,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/integrations/providers/{id}/test_credentials".format(
            id=quote(str(id), safe=""),
        ),
    }

    _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostV1IntegrationsProvidersByIdTestCredentialsResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = PostV1IntegrationsProvidersByIdTestCredentialsResponse200.from_dict(
            response.json()
        )

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

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[PostV1IntegrationsProvidersByIdTestCredentialsResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
    body: PostV1IntegrationsProvidersByIdTestCredentialsBody,
) -> Response[PostV1IntegrationsProvidersByIdTestCredentialsResponse200 | StripeError]:
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

    Replaces POST /integrations/providers/{providerId}/test-credentials.

    Args:
        id (str):
        body (PostV1IntegrationsProvidersByIdTestCredentialsBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1IntegrationsProvidersByIdTestCredentialsResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    *,
    client: AuthenticatedClient,
    body: PostV1IntegrationsProvidersByIdTestCredentialsBody,
) -> PostV1IntegrationsProvidersByIdTestCredentialsResponse200 | StripeError | None:
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

    Replaces POST /integrations/providers/{providerId}/test-credentials.

    Args:
        id (str):
        body (PostV1IntegrationsProvidersByIdTestCredentialsBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1IntegrationsProvidersByIdTestCredentialsResponse200 | StripeError
    """

    return sync_detailed(
        id=id,
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
    body: PostV1IntegrationsProvidersByIdTestCredentialsBody,
) -> Response[PostV1IntegrationsProvidersByIdTestCredentialsResponse200 | StripeError]:
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

    Replaces POST /integrations/providers/{providerId}/test-credentials.

    Args:
        id (str):
        body (PostV1IntegrationsProvidersByIdTestCredentialsBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1IntegrationsProvidersByIdTestCredentialsResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    *,
    client: AuthenticatedClient,
    body: PostV1IntegrationsProvidersByIdTestCredentialsBody,
) -> PostV1IntegrationsProvidersByIdTestCredentialsResponse200 | StripeError | None:
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

    Replaces POST /integrations/providers/{providerId}/test-credentials.

    Args:
        id (str):
        body (PostV1IntegrationsProvidersByIdTestCredentialsBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1IntegrationsProvidersByIdTestCredentialsResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            body=body,
        )
    ).parsed
