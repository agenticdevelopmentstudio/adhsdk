from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.get_integrations_end_user_connections_response_200 import (
    GetIntegrationsEndUserConnectionsResponse200,
)
from ...models.problem_details import ProblemDetails
from ...types import UNSET, Response


def _get_kwargs(
    *,
    ecosystem_id: str,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["ecosystemId"] = ecosystem_id

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/integrations/end-user-connections",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> GetIntegrationsEndUserConnectionsResponse200 | ProblemDetails | None:
    if response.status_code == 200:
        response_200 = GetIntegrationsEndUserConnectionsResponse200.from_dict(response.json())

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
) -> Response[GetIntegrationsEndUserConnectionsResponse200 | ProblemDetails]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    ecosystem_id: str,
) -> Response[GetIntegrationsEndUserConnectionsResponse200 | ProblemDetails]:
    """Health of an ecosystem's end-user connections (operator)

     Provider, service type, status, last sync and last error for each END-USER connection in the
    ecosystem. No account name, username, external id or connection id: an operator can see that a
    connection is unhealthy, not whose it is. The caller must manage the ecosystem (400 when
    `ecosystemId` is omitted; 404/403 when unknown / not the caller's).

    Args:
        ecosystem_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetIntegrationsEndUserConnectionsResponse200 | ProblemDetails]
    """

    kwargs = _get_kwargs(
        ecosystem_id=ecosystem_id,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    ecosystem_id: str,
) -> GetIntegrationsEndUserConnectionsResponse200 | ProblemDetails | None:
    """Health of an ecosystem's end-user connections (operator)

     Provider, service type, status, last sync and last error for each END-USER connection in the
    ecosystem. No account name, username, external id or connection id: an operator can see that a
    connection is unhealthy, not whose it is. The caller must manage the ecosystem (400 when
    `ecosystemId` is omitted; 404/403 when unknown / not the caller's).

    Args:
        ecosystem_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetIntegrationsEndUserConnectionsResponse200 | ProblemDetails
    """

    return sync_detailed(
        client=client,
        ecosystem_id=ecosystem_id,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    ecosystem_id: str,
) -> Response[GetIntegrationsEndUserConnectionsResponse200 | ProblemDetails]:
    """Health of an ecosystem's end-user connections (operator)

     Provider, service type, status, last sync and last error for each END-USER connection in the
    ecosystem. No account name, username, external id or connection id: an operator can see that a
    connection is unhealthy, not whose it is. The caller must manage the ecosystem (400 when
    `ecosystemId` is omitted; 404/403 when unknown / not the caller's).

    Args:
        ecosystem_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetIntegrationsEndUserConnectionsResponse200 | ProblemDetails]
    """

    kwargs = _get_kwargs(
        ecosystem_id=ecosystem_id,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    ecosystem_id: str,
) -> GetIntegrationsEndUserConnectionsResponse200 | ProblemDetails | None:
    """Health of an ecosystem's end-user connections (operator)

     Provider, service type, status, last sync and last error for each END-USER connection in the
    ecosystem. No account name, username, external id or connection id: an operator can see that a
    connection is unhealthy, not whose it is. The caller must manage the ecosystem (400 when
    `ecosystemId` is omitted; 404/403 when unknown / not the caller's).

    Args:
        ecosystem_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetIntegrationsEndUserConnectionsResponse200 | ProblemDetails
    """

    return (
        await asyncio_detailed(
            client=client,
            ecosystem_id=ecosystem_id,
        )
    ).parsed
