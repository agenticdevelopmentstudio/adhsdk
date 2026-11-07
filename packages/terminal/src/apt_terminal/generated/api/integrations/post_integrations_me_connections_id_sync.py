from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.post_integrations_me_connections_id_sync_response_202 import (
    PostIntegrationsMeConnectionsIdSyncResponse202,
)
from ...models.problem_details import ProblemDetails
from ...types import Response


def _get_kwargs(
    id: str,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/integrations/me/connections/{id}/sync".format(
            id=quote(str(id), safe=""),
        ),
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostIntegrationsMeConnectionsIdSyncResponse202 | ProblemDetails | None:
    if response.status_code == 202:
        response_202 = PostIntegrationsMeConnectionsIdSyncResponse202.from_dict(response.json())

        return response_202

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
) -> Response[PostIntegrationsMeConnectionsIdSyncResponse202 | ProblemDetails]:
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
) -> Response[PostIntegrationsMeConnectionsIdSyncResponse202 | ProblemDetails]:
    """Sync one of the caller's connections now

     503 when no worker is registered for its provider and service type.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostIntegrationsMeConnectionsIdSyncResponse202 | ProblemDetails]
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
) -> PostIntegrationsMeConnectionsIdSyncResponse202 | ProblemDetails | None:
    """Sync one of the caller's connections now

     503 when no worker is registered for its provider and service type.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostIntegrationsMeConnectionsIdSyncResponse202 | ProblemDetails
    """

    return sync_detailed(
        id=id,
        client=client,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
) -> Response[PostIntegrationsMeConnectionsIdSyncResponse202 | ProblemDetails]:
    """Sync one of the caller's connections now

     503 when no worker is registered for its provider and service type.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostIntegrationsMeConnectionsIdSyncResponse202 | ProblemDetails]
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
) -> PostIntegrationsMeConnectionsIdSyncResponse202 | ProblemDetails | None:
    """Sync one of the caller's connections now

     503 when no worker is registered for its provider and service type.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostIntegrationsMeConnectionsIdSyncResponse202 | ProblemDetails
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
        )
    ).parsed
