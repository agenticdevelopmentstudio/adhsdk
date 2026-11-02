from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.post_integrations_connection_id_sync_response_202 import (
    PostIntegrationsConnectionIdSyncResponse202,
)
from ...models.problem_details import ProblemDetails
from ...types import Response


def _get_kwargs(
    connection_id: str,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/integrations/{connection_id}/sync".format(
            connection_id=quote(str(connection_id), safe=""),
        ),
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostIntegrationsConnectionIdSyncResponse202 | ProblemDetails | None:
    if response.status_code == 202:
        response_202 = PostIntegrationsConnectionIdSyncResponse202.from_dict(response.json())

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
) -> Response[PostIntegrationsConnectionIdSyncResponse202 | ProblemDetails]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    connection_id: str,
    *,
    client: AuthenticatedClient,
) -> Response[PostIntegrationsConnectionIdSyncResponse202 | ProblemDetails]:
    """Trigger an immediate sync (sync now)

     Runs the connection's worker once, independent of the background scheduler. The owning ecosystem is
    derived from the connection; the caller must manage it. 404 when absent/deleted; 403 when the caller
    cannot manage its ecosystem; 503 when no worker is registered for its provider:serviceType
    (retryable once a worker ships).

    Args:
        connection_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostIntegrationsConnectionIdSyncResponse202 | ProblemDetails]
    """

    kwargs = _get_kwargs(
        connection_id=connection_id,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    connection_id: str,
    *,
    client: AuthenticatedClient,
) -> PostIntegrationsConnectionIdSyncResponse202 | ProblemDetails | None:
    """Trigger an immediate sync (sync now)

     Runs the connection's worker once, independent of the background scheduler. The owning ecosystem is
    derived from the connection; the caller must manage it. 404 when absent/deleted; 403 when the caller
    cannot manage its ecosystem; 503 when no worker is registered for its provider:serviceType
    (retryable once a worker ships).

    Args:
        connection_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostIntegrationsConnectionIdSyncResponse202 | ProblemDetails
    """

    return sync_detailed(
        connection_id=connection_id,
        client=client,
    ).parsed


async def asyncio_detailed(
    connection_id: str,
    *,
    client: AuthenticatedClient,
) -> Response[PostIntegrationsConnectionIdSyncResponse202 | ProblemDetails]:
    """Trigger an immediate sync (sync now)

     Runs the connection's worker once, independent of the background scheduler. The owning ecosystem is
    derived from the connection; the caller must manage it. 404 when absent/deleted; 403 when the caller
    cannot manage its ecosystem; 503 when no worker is registered for its provider:serviceType
    (retryable once a worker ships).

    Args:
        connection_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostIntegrationsConnectionIdSyncResponse202 | ProblemDetails]
    """

    kwargs = _get_kwargs(
        connection_id=connection_id,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    connection_id: str,
    *,
    client: AuthenticatedClient,
) -> PostIntegrationsConnectionIdSyncResponse202 | ProblemDetails | None:
    """Trigger an immediate sync (sync now)

     Runs the connection's worker once, independent of the background scheduler. The owning ecosystem is
    derived from the connection; the caller must manage it. 404 when absent/deleted; 403 when the caller
    cannot manage its ecosystem; 503 when no worker is registered for its provider:serviceType
    (retryable once a worker ships).

    Args:
        connection_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostIntegrationsConnectionIdSyncResponse202 | ProblemDetails
    """

    return (
        await asyncio_detailed(
            connection_id=connection_id,
            client=client,
        )
    ).parsed
