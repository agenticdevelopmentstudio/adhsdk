from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.integration_provider_config import IntegrationProviderConfig
from ...models.problem_details import ProblemDetails
from ...types import Response


def _get_kwargs(
    ecosystem_id: str,
    config_id: str,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/integrations/ecosystems/{ecosystem_id}/provider-configs/{config_id}/rotate-webhook-secret".format(
            ecosystem_id=quote(str(ecosystem_id), safe=""),
            config_id=quote(str(config_id), safe=""),
        ),
    }

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
) -> Response[IntegrationProviderConfig | ProblemDetails]:
    """Rotate a postmark config's inbound deliverability webhook secret

     Mints a NEW per-config webhook secret and returns it on the config's `deliverabilityWebhook.secret`.
    The previous secret stops authenticating immediately, so any Postmark webhook still sending it
    starts failing until the operator pastes the new value — the same "this breaks what is already
    deployed" contract as POST /audience/lists/{listId}/rotate-key. Also the way a config created before
    the per-config secret existed gets its first one. 400 on a provider with no inbound webhook; 404
    when the config is absent or not owned by the ecosystem.

    Args:
        ecosystem_id (str):
        config_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[IntegrationProviderConfig | ProblemDetails]
    """

    kwargs = _get_kwargs(
        ecosystem_id=ecosystem_id,
        config_id=config_id,
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
) -> IntegrationProviderConfig | ProblemDetails | None:
    """Rotate a postmark config's inbound deliverability webhook secret

     Mints a NEW per-config webhook secret and returns it on the config's `deliverabilityWebhook.secret`.
    The previous secret stops authenticating immediately, so any Postmark webhook still sending it
    starts failing until the operator pastes the new value — the same "this breaks what is already
    deployed" contract as POST /audience/lists/{listId}/rotate-key. Also the way a config created before
    the per-config secret existed gets its first one. 400 on a provider with no inbound webhook; 404
    when the config is absent or not owned by the ecosystem.

    Args:
        ecosystem_id (str):
        config_id (str):

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
    ).parsed


async def asyncio_detailed(
    ecosystem_id: str,
    config_id: str,
    *,
    client: AuthenticatedClient,
) -> Response[IntegrationProviderConfig | ProblemDetails]:
    """Rotate a postmark config's inbound deliverability webhook secret

     Mints a NEW per-config webhook secret and returns it on the config's `deliverabilityWebhook.secret`.
    The previous secret stops authenticating immediately, so any Postmark webhook still sending it
    starts failing until the operator pastes the new value — the same "this breaks what is already
    deployed" contract as POST /audience/lists/{listId}/rotate-key. Also the way a config created before
    the per-config secret existed gets its first one. 400 on a provider with no inbound webhook; 404
    when the config is absent or not owned by the ecosystem.

    Args:
        ecosystem_id (str):
        config_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[IntegrationProviderConfig | ProblemDetails]
    """

    kwargs = _get_kwargs(
        ecosystem_id=ecosystem_id,
        config_id=config_id,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    ecosystem_id: str,
    config_id: str,
    *,
    client: AuthenticatedClient,
) -> IntegrationProviderConfig | ProblemDetails | None:
    """Rotate a postmark config's inbound deliverability webhook secret

     Mints a NEW per-config webhook secret and returns it on the config's `deliverabilityWebhook.secret`.
    The previous secret stops authenticating immediately, so any Postmark webhook still sending it
    starts failing until the operator pastes the new value — the same "this breaks what is already
    deployed" contract as POST /audience/lists/{listId}/rotate-key. Also the way a config created before
    the per-config secret existed gets its first one. 400 on a provider with no inbound webhook; 404
    when the config is absent or not owned by the ecosystem.

    Args:
        ecosystem_id (str):
        config_id (str):

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
        )
    ).parsed
