from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.post_registry_registries_registry_id_entries_entry_id_services_body import (
    PostRegistryRegistriesRegistryIdEntriesEntryIdServicesBody,
)
from ...models.registry_entry_service import RegistryEntryService
from ...types import UNSET, Response, Unset


def _get_kwargs(
    registry_id: str,
    entry_id: str,
    *,
    body: PostRegistryRegistriesRegistryIdEntriesEntryIdServicesBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    params: dict[str, Any] = {}

    params["workspace"] = workspace

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/registry/registries/{registry_id}/entries/{entry_id}/services".format(
            registry_id=quote(str(registry_id), safe=""),
            entry_id=quote(str(entry_id), safe=""),
        ),
        "params": params,
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | RegistryEntryService | None:
    if response.status_code == 201:
        response_201 = RegistryEntryService.from_dict(response.json())

        return response_201

    if response.status_code == 400:
        response_400 = Error.from_dict(response.json())

        return response_400

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
) -> Response[Error | RegistryEntryService]:
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
    body: PostRegistryRegistriesRegistryIdEntriesEntryIdServicesBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> Response[Error | RegistryEntryService]:
    """Add a priced service to an entry

    Args:
        registry_id (str):
        entry_id (str):
        workspace (str | Unset):
        body (PostRegistryRegistriesRegistryIdEntriesEntryIdServicesBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | RegistryEntryService]
    """

    kwargs = _get_kwargs(
        registry_id=registry_id,
        entry_id=entry_id,
        body=body,
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
    body: PostRegistryRegistriesRegistryIdEntriesEntryIdServicesBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> Error | RegistryEntryService | None:
    """Add a priced service to an entry

    Args:
        registry_id (str):
        entry_id (str):
        workspace (str | Unset):
        body (PostRegistryRegistriesRegistryIdEntriesEntryIdServicesBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | RegistryEntryService
    """

    return sync_detailed(
        registry_id=registry_id,
        entry_id=entry_id,
        client=client,
        body=body,
        workspace=workspace,
    ).parsed


async def asyncio_detailed(
    registry_id: str,
    entry_id: str,
    *,
    client: AuthenticatedClient,
    body: PostRegistryRegistriesRegistryIdEntriesEntryIdServicesBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> Response[Error | RegistryEntryService]:
    """Add a priced service to an entry

    Args:
        registry_id (str):
        entry_id (str):
        workspace (str | Unset):
        body (PostRegistryRegistriesRegistryIdEntriesEntryIdServicesBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | RegistryEntryService]
    """

    kwargs = _get_kwargs(
        registry_id=registry_id,
        entry_id=entry_id,
        body=body,
        workspace=workspace,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    registry_id: str,
    entry_id: str,
    *,
    client: AuthenticatedClient,
    body: PostRegistryRegistriesRegistryIdEntriesEntryIdServicesBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> Error | RegistryEntryService | None:
    """Add a priced service to an entry

    Args:
        registry_id (str):
        entry_id (str):
        workspace (str | Unset):
        body (PostRegistryRegistriesRegistryIdEntriesEntryIdServicesBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | RegistryEntryService
    """

    return (
        await asyncio_detailed(
            registry_id=registry_id,
            entry_id=entry_id,
            client=client,
            body=body,
            workspace=workspace,
        )
    ).parsed
