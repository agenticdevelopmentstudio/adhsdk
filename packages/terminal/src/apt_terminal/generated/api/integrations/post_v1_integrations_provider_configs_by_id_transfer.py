from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.post_v1_integrations_provider_configs_by_id_transfer_body import (
    PostV1IntegrationsProviderConfigsByIdTransferBody,
)
from ...models.post_v1_integrations_provider_configs_by_id_transfer_response_200 import (
    PostV1IntegrationsProviderConfigsByIdTransferResponse200,
)
from ...models.stripe_error import StripeError
from ...types import Response


def _get_kwargs(
    id: str,
    *,
    body: PostV1IntegrationsProviderConfigsByIdTransferBody,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/integrations/provider_configs/{id}/transfer".format(
            id=quote(str(id), safe=""),
        ),
    }

    _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostV1IntegrationsProviderConfigsByIdTransferResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = PostV1IntegrationsProviderConfigsByIdTransferResponse200.from_dict(
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

    if response.status_code == 409:
        response_409 = StripeError.from_dict(response.json())

        return response_409

    if response.status_code == 503:
        response_503 = StripeError.from_dict(response.json())

        return response_503

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[PostV1IntegrationsProviderConfigsByIdTransferResponse200 | StripeError]:
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
    body: PostV1IntegrationsProviderConfigsByIdTransferBody,
) -> Response[PostV1IntegrationsProviderConfigsByIdTransferResponse200 | StripeError]:
    """Move an integration to another ecosystem

     Moves the credential, the connections it minted, and their cached repository lists together, in one
    transaction — an operator taking their own integration from a personal workspace into an
    organization they also own, or the other way. Leaving the connections behind would hand the
    destination a credential it can see no accounts through.

    THE CALLER MUST MANAGE BOTH ENDS: the source is authorized as on every other route here, and the
    destination is authorized before anything moves (404/403 from whichever end the caller does not
    manage). The generic ecosystem-move surface cannot do this — its CRUD policy excludes credential
    tables on purpose.

    The `integration` rdid embeds the owning ecosystem, so it is re-minted at the destination and the
    old address stops resolving. 400 when the config is already in the destination; 404 when it is
    absent or not owned by the source; 409 when the destination already holds an integration of that
    name.

    Replaces POST /integrations/ecosystems/{ecosystemId}/provider-configs/{configId}/transfer.

    Args:
        id (str):
        body (PostV1IntegrationsProviderConfigsByIdTransferBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1IntegrationsProviderConfigsByIdTransferResponse200 | StripeError]
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
    body: PostV1IntegrationsProviderConfigsByIdTransferBody,
) -> PostV1IntegrationsProviderConfigsByIdTransferResponse200 | StripeError | None:
    """Move an integration to another ecosystem

     Moves the credential, the connections it minted, and their cached repository lists together, in one
    transaction — an operator taking their own integration from a personal workspace into an
    organization they also own, or the other way. Leaving the connections behind would hand the
    destination a credential it can see no accounts through.

    THE CALLER MUST MANAGE BOTH ENDS: the source is authorized as on every other route here, and the
    destination is authorized before anything moves (404/403 from whichever end the caller does not
    manage). The generic ecosystem-move surface cannot do this — its CRUD policy excludes credential
    tables on purpose.

    The `integration` rdid embeds the owning ecosystem, so it is re-minted at the destination and the
    old address stops resolving. 400 when the config is already in the destination; 404 when it is
    absent or not owned by the source; 409 when the destination already holds an integration of that
    name.

    Replaces POST /integrations/ecosystems/{ecosystemId}/provider-configs/{configId}/transfer.

    Args:
        id (str):
        body (PostV1IntegrationsProviderConfigsByIdTransferBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1IntegrationsProviderConfigsByIdTransferResponse200 | StripeError
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
    body: PostV1IntegrationsProviderConfigsByIdTransferBody,
) -> Response[PostV1IntegrationsProviderConfigsByIdTransferResponse200 | StripeError]:
    """Move an integration to another ecosystem

     Moves the credential, the connections it minted, and their cached repository lists together, in one
    transaction — an operator taking their own integration from a personal workspace into an
    organization they also own, or the other way. Leaving the connections behind would hand the
    destination a credential it can see no accounts through.

    THE CALLER MUST MANAGE BOTH ENDS: the source is authorized as on every other route here, and the
    destination is authorized before anything moves (404/403 from whichever end the caller does not
    manage). The generic ecosystem-move surface cannot do this — its CRUD policy excludes credential
    tables on purpose.

    The `integration` rdid embeds the owning ecosystem, so it is re-minted at the destination and the
    old address stops resolving. 400 when the config is already in the destination; 404 when it is
    absent or not owned by the source; 409 when the destination already holds an integration of that
    name.

    Replaces POST /integrations/ecosystems/{ecosystemId}/provider-configs/{configId}/transfer.

    Args:
        id (str):
        body (PostV1IntegrationsProviderConfigsByIdTransferBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1IntegrationsProviderConfigsByIdTransferResponse200 | StripeError]
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
    body: PostV1IntegrationsProviderConfigsByIdTransferBody,
) -> PostV1IntegrationsProviderConfigsByIdTransferResponse200 | StripeError | None:
    """Move an integration to another ecosystem

     Moves the credential, the connections it minted, and their cached repository lists together, in one
    transaction — an operator taking their own integration from a personal workspace into an
    organization they also own, or the other way. Leaving the connections behind would hand the
    destination a credential it can see no accounts through.

    THE CALLER MUST MANAGE BOTH ENDS: the source is authorized as on every other route here, and the
    destination is authorized before anything moves (404/403 from whichever end the caller does not
    manage). The generic ecosystem-move surface cannot do this — its CRUD policy excludes credential
    tables on purpose.

    The `integration` rdid embeds the owning ecosystem, so it is re-minted at the destination and the
    old address stops resolving. 400 when the config is already in the destination; 404 when it is
    absent or not owned by the source; 409 when the destination already holds an integration of that
    name.

    Replaces POST /integrations/ecosystems/{ecosystemId}/provider-configs/{configId}/transfer.

    Args:
        id (str):
        body (PostV1IntegrationsProviderConfigsByIdTransferBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1IntegrationsProviderConfigsByIdTransferResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            body=body,
        )
    ).parsed
