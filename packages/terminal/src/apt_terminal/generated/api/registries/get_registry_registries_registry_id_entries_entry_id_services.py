from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.get_registry_registries_registry_id_entries_entry_id_services_response_200 import (
    GetRegistryRegistriesRegistryIdEntriesEntryIdServicesResponse200,
)
from ...types import UNSET, Response, Unset


def _get_kwargs(
    registry_id: str,
    entry_id: str,
    *,
    workspace: str | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["workspace"] = workspace

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/registry/registries/{registry_id}/entries/{entry_id}/services".format(
            registry_id=quote(str(registry_id), safe=""),
            entry_id=quote(str(entry_id), safe=""),
        ),
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | GetRegistryRegistriesRegistryIdEntriesEntryIdServicesResponse200 | None:
    if response.status_code == 200:
        response_200 = GetRegistryRegistriesRegistryIdEntriesEntryIdServicesResponse200.from_dict(
            response.json()
        )

        return response_200

    if response.status_code == 401:
        response_401 = Error.from_dict(response.json())

        return response_401

    if response.status_code == 403:
        response_403 = Error.from_dict(response.json())

        return response_403

    if response.status_code == 404:
        response_404 = Error.from_dict(response.json())

        return response_404

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | GetRegistryRegistriesRegistryIdEntriesEntryIdServicesResponse200]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    registry_id: str,
    entry_id: str,
    *,
    client: AuthenticatedClient,
    workspace: str | Unset = UNSET,
) -> Response[Error | GetRegistryRegistriesRegistryIdEntriesEntryIdServicesResponse200]:
    """List an entry's services (non-deleted, by sortOrder)

    Args:
        registry_id (str):
        entry_id (str):
        workspace (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GetRegistryRegistriesRegistryIdEntriesEntryIdServicesResponse200]
    """

    kwargs = _get_kwargs(
        registry_id=registry_id,
        entry_id=entry_id,
        workspace=workspace,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    registry_id: str,
    entry_id: str,
    *,
    client: AuthenticatedClient,
    workspace: str | Unset = UNSET,
) -> Error | GetRegistryRegistriesRegistryIdEntriesEntryIdServicesResponse200 | None:
    """List an entry's services (non-deleted, by sortOrder)

    Args:
        registry_id (str):
        entry_id (str):
        workspace (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GetRegistryRegistriesRegistryIdEntriesEntryIdServicesResponse200
    """

    return sync_detailed(
        registry_id=registry_id,
        entry_id=entry_id,
        client=client,
        workspace=workspace,
    ).parsed


async def asyncio_detailed(
    registry_id: str,
    entry_id: str,
    *,
    client: AuthenticatedClient,
    workspace: str | Unset = UNSET,
) -> Response[Error | GetRegistryRegistriesRegistryIdEntriesEntryIdServicesResponse200]:
    """List an entry's services (non-deleted, by sortOrder)

    Args:
        registry_id (str):
        entry_id (str):
        workspace (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GetRegistryRegistriesRegistryIdEntriesEntryIdServicesResponse200]
    """

    kwargs = _get_kwargs(
        registry_id=registry_id,
        entry_id=entry_id,
        workspace=workspace,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    registry_id: str,
    entry_id: str,
    *,
    client: AuthenticatedClient,
    workspace: str | Unset = UNSET,
) -> Error | GetRegistryRegistriesRegistryIdEntriesEntryIdServicesResponse200 | None:
    """List an entry's services (non-deleted, by sortOrder)

    Args:
        registry_id (str):
        entry_id (str):
        workspace (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GetRegistryRegistriesRegistryIdEntriesEntryIdServicesResponse200
    """

    return (
        await asyncio_detailed(
            registry_id=registry_id,
            entry_id=entry_id,
            client=client,
            workspace=workspace,
        )
    ).parsed
