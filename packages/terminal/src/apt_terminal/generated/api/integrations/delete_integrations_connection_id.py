from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.delete_integrations_connection_id_response_200 import (
    DeleteIntegrationsConnectionIdResponse200,
)
from ...models.problem_details import ProblemDetails
from ...types import Response


def _get_kwargs(
    connection_id: str,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "delete",
        "url": "/integrations/{connection_id}".format(
            connection_id=quote(str(connection_id), safe=""),
        ),
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> DeleteIntegrationsConnectionIdResponse200 | ProblemDetails | None:
    if response.status_code == 200:
        response_200 = DeleteIntegrationsConnectionIdResponse200.from_dict(response.json())

        return response_200

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
) -> Response[DeleteIntegrationsConnectionIdResponse200 | ProblemDetails]:
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
) -> Response[DeleteIntegrationsConnectionIdResponse200 | ProblemDetails]:
    """Disconnect a connection (ecosystem-authorized)

     Soft-deletes the connection and tombstones every synced-data row it produced. The owning ecosystem
    is derived from the connection; the caller must manage it. 404 when the connection is
    absent/deleted; 403 when the caller cannot manage its ecosystem.

    Args:
        connection_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[DeleteIntegrationsConnectionIdResponse200 | ProblemDetails]
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
) -> DeleteIntegrationsConnectionIdResponse200 | ProblemDetails | None:
    """Disconnect a connection (ecosystem-authorized)

     Soft-deletes the connection and tombstones every synced-data row it produced. The owning ecosystem
    is derived from the connection; the caller must manage it. 404 when the connection is
    absent/deleted; 403 when the caller cannot manage its ecosystem.

    Args:
        connection_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        DeleteIntegrationsConnectionIdResponse200 | ProblemDetails
    """

    return sync_detailed(
        connection_id=connection_id,
        client=client,
    ).parsed


async def asyncio_detailed(
    connection_id: str,
    *,
    client: AuthenticatedClient,
) -> Response[DeleteIntegrationsConnectionIdResponse200 | ProblemDetails]:
    """Disconnect a connection (ecosystem-authorized)

     Soft-deletes the connection and tombstones every synced-data row it produced. The owning ecosystem
    is derived from the connection; the caller must manage it. 404 when the connection is
    absent/deleted; 403 when the caller cannot manage its ecosystem.

    Args:
        connection_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[DeleteIntegrationsConnectionIdResponse200 | ProblemDetails]
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
) -> DeleteIntegrationsConnectionIdResponse200 | ProblemDetails | None:
    """Disconnect a connection (ecosystem-authorized)

     Soft-deletes the connection and tombstones every synced-data row it produced. The owning ecosystem
    is derived from the connection; the caller must manage it. 404 when the connection is
    absent/deleted; 403 when the caller cannot manage its ecosystem.

    Args:
        connection_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        DeleteIntegrationsConnectionIdResponse200 | ProblemDetails
    """

    return (
        await asyncio_detailed(
            connection_id=connection_id,
            client=client,
        )
    ).parsed
