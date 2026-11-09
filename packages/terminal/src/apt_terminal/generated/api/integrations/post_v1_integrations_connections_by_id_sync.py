from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.post_v1_integrations_connections_by_id_sync_response_202 import (
    PostV1IntegrationsConnectionsByIdSyncResponse202,
)
from ...models.stripe_error import StripeError
from ...types import Response


def _get_kwargs(
    id: str,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/integrations/connections/{id}/sync".format(
            id=quote(str(id), safe=""),
        ),
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostV1IntegrationsConnectionsByIdSyncResponse202 | StripeError | None:
    if response.status_code == 202:
        response_202 = PostV1IntegrationsConnectionsByIdSyncResponse202.from_dict(response.json())

        return response_202

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
) -> Response[PostV1IntegrationsConnectionsByIdSyncResponse202 | StripeError]:
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
) -> Response[PostV1IntegrationsConnectionsByIdSyncResponse202 | StripeError]:
    """Sync one of the caller's connections now

     503 when no worker is registered for its provider and service type.

    Replaces POST /integrations/me/connections/{id}/sync, POST /integrations/{connectionId}/sync.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1IntegrationsConnectionsByIdSyncResponse202 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    *,
    client: AuthenticatedClient,
) -> PostV1IntegrationsConnectionsByIdSyncResponse202 | StripeError | None:
    """Sync one of the caller's connections now

     503 when no worker is registered for its provider and service type.

    Replaces POST /integrations/me/connections/{id}/sync, POST /integrations/{connectionId}/sync.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1IntegrationsConnectionsByIdSyncResponse202 | StripeError
    """

    return sync_detailed(
        id=id,
        client=client,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
) -> Response[PostV1IntegrationsConnectionsByIdSyncResponse202 | StripeError]:
    """Sync one of the caller's connections now

     503 when no worker is registered for its provider and service type.

    Replaces POST /integrations/me/connections/{id}/sync, POST /integrations/{connectionId}/sync.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1IntegrationsConnectionsByIdSyncResponse202 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    *,
    client: AuthenticatedClient,
) -> PostV1IntegrationsConnectionsByIdSyncResponse202 | StripeError | None:
    """Sync one of the caller's connections now

     503 when no worker is registered for its provider and service type.

    Replaces POST /integrations/me/connections/{id}/sync, POST /integrations/{connectionId}/sync.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1IntegrationsConnectionsByIdSyncResponse202 | StripeError
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
        )
    ).parsed
