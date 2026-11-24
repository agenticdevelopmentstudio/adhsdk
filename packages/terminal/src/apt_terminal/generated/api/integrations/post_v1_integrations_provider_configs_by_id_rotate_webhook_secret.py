from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.post_v1_integrations_provider_configs_by_id_rotate_webhook_secret_body import (
    PostV1IntegrationsProviderConfigsByIdRotateWebhookSecretBody,
)
from ...models.post_v1_integrations_provider_configs_by_id_rotate_webhook_secret_response_200 import (
    PostV1IntegrationsProviderConfigsByIdRotateWebhookSecretResponse200,
)
from ...models.stripe_error import StripeError
from ...types import UNSET, Response, Unset


def _get_kwargs(
    id: str,
    *,
    body: PostV1IntegrationsProviderConfigsByIdRotateWebhookSecretBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/integrations/provider_configs/{id}/rotate_webhook_secret".format(
            id=quote(str(id), safe=""),
        ),
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostV1IntegrationsProviderConfigsByIdRotateWebhookSecretResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = (
            PostV1IntegrationsProviderConfigsByIdRotateWebhookSecretResponse200.from_dict(
                response.json()
            )
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

    if response.status_code == 503:
        response_503 = StripeError.from_dict(response.json())

        return response_503

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[PostV1IntegrationsProviderConfigsByIdRotateWebhookSecretResponse200 | StripeError]:
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
    body: PostV1IntegrationsProviderConfigsByIdRotateWebhookSecretBody | Unset = UNSET,
) -> Response[PostV1IntegrationsProviderConfigsByIdRotateWebhookSecretResponse200 | StripeError]:
    """Rotate a postmark config's inbound deliverability webhook secret

     Mints a NEW per-config webhook secret and returns it on the config's `deliverabilityWebhook.secret`.
    The previous secret stops authenticating immediately, so any Postmark webhook still sending it
    starts failing until the operator pastes the new value — the same "this breaks what is already
    deployed" contract as POST /audience/lists/{listId}/rotate-key. Also the way a config created before
    the per-config secret existed gets its first one. 400 on a provider with no inbound webhook; 404
    when the config is absent or not owned by the ecosystem.

    Replaces POST /integrations/ecosystems/{ecosystemId}/provider-configs/{configId}/rotate-webhook-
    secret.

    Args:
        id (str):
        body (PostV1IntegrationsProviderConfigsByIdRotateWebhookSecretBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1IntegrationsProviderConfigsByIdRotateWebhookSecretResponse200 | StripeError]
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
    body: PostV1IntegrationsProviderConfigsByIdRotateWebhookSecretBody | Unset = UNSET,
) -> PostV1IntegrationsProviderConfigsByIdRotateWebhookSecretResponse200 | StripeError | None:
    """Rotate a postmark config's inbound deliverability webhook secret

     Mints a NEW per-config webhook secret and returns it on the config's `deliverabilityWebhook.secret`.
    The previous secret stops authenticating immediately, so any Postmark webhook still sending it
    starts failing until the operator pastes the new value — the same "this breaks what is already
    deployed" contract as POST /audience/lists/{listId}/rotate-key. Also the way a config created before
    the per-config secret existed gets its first one. 400 on a provider with no inbound webhook; 404
    when the config is absent or not owned by the ecosystem.

    Replaces POST /integrations/ecosystems/{ecosystemId}/provider-configs/{configId}/rotate-webhook-
    secret.

    Args:
        id (str):
        body (PostV1IntegrationsProviderConfigsByIdRotateWebhookSecretBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1IntegrationsProviderConfigsByIdRotateWebhookSecretResponse200 | StripeError
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
    body: PostV1IntegrationsProviderConfigsByIdRotateWebhookSecretBody | Unset = UNSET,
) -> Response[PostV1IntegrationsProviderConfigsByIdRotateWebhookSecretResponse200 | StripeError]:
    """Rotate a postmark config's inbound deliverability webhook secret

     Mints a NEW per-config webhook secret and returns it on the config's `deliverabilityWebhook.secret`.
    The previous secret stops authenticating immediately, so any Postmark webhook still sending it
    starts failing until the operator pastes the new value — the same "this breaks what is already
    deployed" contract as POST /audience/lists/{listId}/rotate-key. Also the way a config created before
    the per-config secret existed gets its first one. 400 on a provider with no inbound webhook; 404
    when the config is absent or not owned by the ecosystem.

    Replaces POST /integrations/ecosystems/{ecosystemId}/provider-configs/{configId}/rotate-webhook-
    secret.

    Args:
        id (str):
        body (PostV1IntegrationsProviderConfigsByIdRotateWebhookSecretBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1IntegrationsProviderConfigsByIdRotateWebhookSecretResponse200 | StripeError]
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
    body: PostV1IntegrationsProviderConfigsByIdRotateWebhookSecretBody | Unset = UNSET,
) -> PostV1IntegrationsProviderConfigsByIdRotateWebhookSecretResponse200 | StripeError | None:
    """Rotate a postmark config's inbound deliverability webhook secret

     Mints a NEW per-config webhook secret and returns it on the config's `deliverabilityWebhook.secret`.
    The previous secret stops authenticating immediately, so any Postmark webhook still sending it
    starts failing until the operator pastes the new value — the same "this breaks what is already
    deployed" contract as POST /audience/lists/{listId}/rotate-key. Also the way a config created before
    the per-config secret existed gets its first one. 400 on a provider with no inbound webhook; 404
    when the config is absent or not owned by the ecosystem.

    Replaces POST /integrations/ecosystems/{ecosystemId}/provider-configs/{configId}/rotate-webhook-
    secret.

    Args:
        id (str):
        body (PostV1IntegrationsProviderConfigsByIdRotateWebhookSecretBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1IntegrationsProviderConfigsByIdRotateWebhookSecretResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            body=body,
        )
    ).parsed
