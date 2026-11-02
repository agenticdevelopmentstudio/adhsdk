from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.get_integrations_admin_configs_response_200 import (
    GetIntegrationsAdminConfigsResponse200,
)
from ...models.problem_details import ProblemDetails
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    limit: str | Unset = UNSET,
    offset: str | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["limit"] = limit

    params["offset"] = offset

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/integrations/admin/configs",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> GetIntegrationsAdminConfigsResponse200 | ProblemDetails | None:
    if response.status_code == 200:
        response_200 = GetIntegrationsAdminConfigsResponse200.from_dict(response.json())

        return response_200

    if response.status_code == 401:
        response_401 = ProblemDetails.from_dict(response.json())

        return response_401

    if response.status_code == 403:
        response_403 = ProblemDetails.from_dict(response.json())

        return response_403

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[GetIntegrationsAdminConfigsResponse200 | ProblemDetails]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    limit: str | Unset = UNSET,
    offset: str | Unset = UNSET,
) -> Response[GetIntegrationsAdminConfigsResponse200 | ProblemDetails]:
    """List provider global configs (admin; secrets masked)

     Paged by limit/offset (limit defaults to 50, capped at 100; offset defaults to 0). Returns a
    pagination envelope: `items` is the page; `total` is the unfiltered provider-config count;
    `limit`/`offset` echo the applied paging.

    Args:
        limit (str | Unset):
        offset (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetIntegrationsAdminConfigsResponse200 | ProblemDetails]
    """

    kwargs = _get_kwargs(
        limit=limit,
        offset=offset,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    limit: str | Unset = UNSET,
    offset: str | Unset = UNSET,
) -> GetIntegrationsAdminConfigsResponse200 | ProblemDetails | None:
    """List provider global configs (admin; secrets masked)

     Paged by limit/offset (limit defaults to 50, capped at 100; offset defaults to 0). Returns a
    pagination envelope: `items` is the page; `total` is the unfiltered provider-config count;
    `limit`/`offset` echo the applied paging.

    Args:
        limit (str | Unset):
        offset (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetIntegrationsAdminConfigsResponse200 | ProblemDetails
    """

    return sync_detailed(
        client=client,
        limit=limit,
        offset=offset,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    limit: str | Unset = UNSET,
    offset: str | Unset = UNSET,
) -> Response[GetIntegrationsAdminConfigsResponse200 | ProblemDetails]:
    """List provider global configs (admin; secrets masked)

     Paged by limit/offset (limit defaults to 50, capped at 100; offset defaults to 0). Returns a
    pagination envelope: `items` is the page; `total` is the unfiltered provider-config count;
    `limit`/`offset` echo the applied paging.

    Args:
        limit (str | Unset):
        offset (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetIntegrationsAdminConfigsResponse200 | ProblemDetails]
    """

    kwargs = _get_kwargs(
        limit=limit,
        offset=offset,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    limit: str | Unset = UNSET,
    offset: str | Unset = UNSET,
) -> GetIntegrationsAdminConfigsResponse200 | ProblemDetails | None:
    """List provider global configs (admin; secrets masked)

     Paged by limit/offset (limit defaults to 50, capped at 100; offset defaults to 0). Returns a
    pagination envelope: `items` is the page; `total` is the unfiltered provider-config count;
    `limit`/`offset` echo the applied paging.

    Args:
        limit (str | Unset):
        offset (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetIntegrationsAdminConfigsResponse200 | ProblemDetails
    """

    return (
        await asyncio_detailed(
            client=client,
            limit=limit,
            offset=offset,
        )
    ).parsed
