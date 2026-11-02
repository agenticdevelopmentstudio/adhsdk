from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.post_integrations_providers_provider_id_adopt_installations_body import (
    PostIntegrationsProvidersProviderIdAdoptInstallationsBody,
)
from ...models.post_integrations_providers_provider_id_adopt_installations_response_200 import (
    PostIntegrationsProvidersProviderIdAdoptInstallationsResponse200,
)
from ...models.problem_details import ProblemDetails
from ...types import UNSET, Response, Unset


def _get_kwargs(
    provider_id: str,
    *,
    body: PostIntegrationsProvidersProviderIdAdoptInstallationsBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/integrations/providers/{provider_id}/adopt-installations".format(
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
) -> PostIntegrationsProvidersProviderIdAdoptInstallationsResponse200 | ProblemDetails | None:
    if response.status_code == 200:
        response_200 = PostIntegrationsProvidersProviderIdAdoptInstallationsResponse200.from_dict(
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
) -> Response[PostIntegrationsProvidersProviderIdAdoptInstallationsResponse200 | ProblemDetails]:
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
    body: PostIntegrationsProvidersProviderIdAdoptInstallationsBody | Unset = UNSET,
) -> Response[PostIntegrationsProvidersProviderIdAdoptInstallationsResponse200 | ProblemDetails]:
    """Connect every installation the saved GitHub App can already see

     This is what lets ADDING the integration BE the connect. A GitHub App is installed on github.com, by
    a person choosing an account there — so by the time an app id and private key are saved, that choice
    has already been made and the app can read it back. An OAuth redirect at this point would ask a
    question whose answer is already known.

    Only valid for github_app providers (400 otherwise); 404 for an unknown provider or an unknown
    config. `providerConfigId` is REQUIRED and read by id, never resolved: the resolver falls back to
    the platform-global app when an ecosystem has none of its own, and enumerating a shared app's
    installations would list every other tenant's.

    ONE INSTALLATION'S FAILURE IS NOT THE BATCH'S. An app on four orgs, one of them suspended, connects
    three and reports the fourth under `skipped` with GitHub's message. Only a failure to enumerate at
    all — which is the credentials themselves being wrong — is a 400. Calling it again is safe: an
    installation already connected comes back under `connected` with its existing `connectionId`.

    Args:
        provider_id (str):
        body (PostIntegrationsProvidersProviderIdAdoptInstallationsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostIntegrationsProvidersProviderIdAdoptInstallationsResponse200 | ProblemDetails]
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
    body: PostIntegrationsProvidersProviderIdAdoptInstallationsBody | Unset = UNSET,
) -> PostIntegrationsProvidersProviderIdAdoptInstallationsResponse200 | ProblemDetails | None:
    """Connect every installation the saved GitHub App can already see

     This is what lets ADDING the integration BE the connect. A GitHub App is installed on github.com, by
    a person choosing an account there — so by the time an app id and private key are saved, that choice
    has already been made and the app can read it back. An OAuth redirect at this point would ask a
    question whose answer is already known.

    Only valid for github_app providers (400 otherwise); 404 for an unknown provider or an unknown
    config. `providerConfigId` is REQUIRED and read by id, never resolved: the resolver falls back to
    the platform-global app when an ecosystem has none of its own, and enumerating a shared app's
    installations would list every other tenant's.

    ONE INSTALLATION'S FAILURE IS NOT THE BATCH'S. An app on four orgs, one of them suspended, connects
    three and reports the fourth under `skipped` with GitHub's message. Only a failure to enumerate at
    all — which is the credentials themselves being wrong — is a 400. Calling it again is safe: an
    installation already connected comes back under `connected` with its existing `connectionId`.

    Args:
        provider_id (str):
        body (PostIntegrationsProvidersProviderIdAdoptInstallationsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostIntegrationsProvidersProviderIdAdoptInstallationsResponse200 | ProblemDetails
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
    body: PostIntegrationsProvidersProviderIdAdoptInstallationsBody | Unset = UNSET,
) -> Response[PostIntegrationsProvidersProviderIdAdoptInstallationsResponse200 | ProblemDetails]:
    """Connect every installation the saved GitHub App can already see

     This is what lets ADDING the integration BE the connect. A GitHub App is installed on github.com, by
    a person choosing an account there — so by the time an app id and private key are saved, that choice
    has already been made and the app can read it back. An OAuth redirect at this point would ask a
    question whose answer is already known.

    Only valid for github_app providers (400 otherwise); 404 for an unknown provider or an unknown
    config. `providerConfigId` is REQUIRED and read by id, never resolved: the resolver falls back to
    the platform-global app when an ecosystem has none of its own, and enumerating a shared app's
    installations would list every other tenant's.

    ONE INSTALLATION'S FAILURE IS NOT THE BATCH'S. An app on four orgs, one of them suspended, connects
    three and reports the fourth under `skipped` with GitHub's message. Only a failure to enumerate at
    all — which is the credentials themselves being wrong — is a 400. Calling it again is safe: an
    installation already connected comes back under `connected` with its existing `connectionId`.

    Args:
        provider_id (str):
        body (PostIntegrationsProvidersProviderIdAdoptInstallationsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostIntegrationsProvidersProviderIdAdoptInstallationsResponse200 | ProblemDetails]
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
    body: PostIntegrationsProvidersProviderIdAdoptInstallationsBody | Unset = UNSET,
) -> PostIntegrationsProvidersProviderIdAdoptInstallationsResponse200 | ProblemDetails | None:
    """Connect every installation the saved GitHub App can already see

     This is what lets ADDING the integration BE the connect. A GitHub App is installed on github.com, by
    a person choosing an account there — so by the time an app id and private key are saved, that choice
    has already been made and the app can read it back. An OAuth redirect at this point would ask a
    question whose answer is already known.

    Only valid for github_app providers (400 otherwise); 404 for an unknown provider or an unknown
    config. `providerConfigId` is REQUIRED and read by id, never resolved: the resolver falls back to
    the platform-global app when an ecosystem has none of its own, and enumerating a shared app's
    installations would list every other tenant's.

    ONE INSTALLATION'S FAILURE IS NOT THE BATCH'S. An app on four orgs, one of them suspended, connects
    three and reports the fourth under `skipped` with GitHub's message. Only a failure to enumerate at
    all — which is the credentials themselves being wrong — is a 400. Calling it again is safe: an
    installation already connected comes back under `connected` with its existing `connectionId`.

    Args:
        provider_id (str):
        body (PostIntegrationsProvidersProviderIdAdoptInstallationsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostIntegrationsProvidersProviderIdAdoptInstallationsResponse200 | ProblemDetails
    """

    return (
        await asyncio_detailed(
            provider_id=provider_id,
            client=client,
            body=body,
        )
    ).parsed
