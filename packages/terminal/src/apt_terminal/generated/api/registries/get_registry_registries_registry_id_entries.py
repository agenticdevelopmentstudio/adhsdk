from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.get_registry_registries_registry_id_entries_response_200 import (
    GetRegistryRegistriesRegistryIdEntriesResponse200,
)
from ...models.get_registry_registries_registry_id_entries_status import (
    GetRegistryRegistriesRegistryIdEntriesStatus,
)
from ...types import UNSET, Response, Unset


def _get_kwargs(
    registry_id: str,
    *,
    status: GetRegistryRegistriesRegistryIdEntriesStatus | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    json_status: str | Unset = UNSET
    if not isinstance(status, Unset):
        json_status = status.value

    params["status"] = json_status

    params["workspace"] = workspace

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/registry/registries/{registry_id}/entries".format(
            registry_id=quote(str(registry_id), safe=""),
        ),
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | GetRegistryRegistriesRegistryIdEntriesResponse200 | None:
    if response.status_code == 200:
        response_200 = GetRegistryRegistriesRegistryIdEntriesResponse200.from_dict(response.json())

        return response_200

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
) -> Response[Error | GetRegistryRegistriesRegistryIdEntriesResponse200]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    registry_id: str,
    *,
    client: AuthenticatedClient,
    status: GetRegistryRegistriesRegistryIdEntriesStatus | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> Response[Error | GetRegistryRegistriesRegistryIdEntriesResponse200]:
    """Every entry in a registry, for whoever administers it — the review queue behind the `reviewed`
    submission policy. Approving is a PATCH of {status:"published"} on an entry by the registry owner;
    rejecting is the same PATCH with "draft"

     Requires the `registries` sub-item R verb on this registry, because it returns other principals'
    unpublished entries: a registrant reads their own row through /entries/mine, and anonymous visitors
    see only published ones through the public routes. Newest first by createdAt — unlike the
    alphabetical registry list, since this list's job is "what came in while I was away". Soft-deleted
    entries are never returned.

    Args:
        registry_id (str):
        status (GetRegistryRegistriesRegistryIdEntriesStatus | Unset):
        workspace (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GetRegistryRegistriesRegistryIdEntriesResponse200]
    """

    kwargs = _get_kwargs(
        registry_id=registry_id,
        status=status,
        workspace=workspace,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    registry_id: str,
    *,
    client: AuthenticatedClient,
    status: GetRegistryRegistriesRegistryIdEntriesStatus | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> Error | GetRegistryRegistriesRegistryIdEntriesResponse200 | None:
    """Every entry in a registry, for whoever administers it — the review queue behind the `reviewed`
    submission policy. Approving is a PATCH of {status:"published"} on an entry by the registry owner;
    rejecting is the same PATCH with "draft"

     Requires the `registries` sub-item R verb on this registry, because it returns other principals'
    unpublished entries: a registrant reads their own row through /entries/mine, and anonymous visitors
    see only published ones through the public routes. Newest first by createdAt — unlike the
    alphabetical registry list, since this list's job is "what came in while I was away". Soft-deleted
    entries are never returned.

    Args:
        registry_id (str):
        status (GetRegistryRegistriesRegistryIdEntriesStatus | Unset):
        workspace (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GetRegistryRegistriesRegistryIdEntriesResponse200
    """

    return sync_detailed(
        registry_id=registry_id,
        client=client,
        status=status,
        workspace=workspace,
    ).parsed


async def asyncio_detailed(
    registry_id: str,
    *,
    client: AuthenticatedClient,
    status: GetRegistryRegistriesRegistryIdEntriesStatus | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> Response[Error | GetRegistryRegistriesRegistryIdEntriesResponse200]:
    """Every entry in a registry, for whoever administers it — the review queue behind the `reviewed`
    submission policy. Approving is a PATCH of {status:"published"} on an entry by the registry owner;
    rejecting is the same PATCH with "draft"

     Requires the `registries` sub-item R verb on this registry, because it returns other principals'
    unpublished entries: a registrant reads their own row through /entries/mine, and anonymous visitors
    see only published ones through the public routes. Newest first by createdAt — unlike the
    alphabetical registry list, since this list's job is "what came in while I was away". Soft-deleted
    entries are never returned.

    Args:
        registry_id (str):
        status (GetRegistryRegistriesRegistryIdEntriesStatus | Unset):
        workspace (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GetRegistryRegistriesRegistryIdEntriesResponse200]
    """

    kwargs = _get_kwargs(
        registry_id=registry_id,
        status=status,
        workspace=workspace,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    registry_id: str,
    *,
    client: AuthenticatedClient,
    status: GetRegistryRegistriesRegistryIdEntriesStatus | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> Error | GetRegistryRegistriesRegistryIdEntriesResponse200 | None:
    """Every entry in a registry, for whoever administers it — the review queue behind the `reviewed`
    submission policy. Approving is a PATCH of {status:"published"} on an entry by the registry owner;
    rejecting is the same PATCH with "draft"

     Requires the `registries` sub-item R verb on this registry, because it returns other principals'
    unpublished entries: a registrant reads their own row through /entries/mine, and anonymous visitors
    see only published ones through the public routes. Newest first by createdAt — unlike the
    alphabetical registry list, since this list's job is "what came in while I was away". Soft-deleted
    entries are never returned.

    Args:
        registry_id (str):
        status (GetRegistryRegistriesRegistryIdEntriesStatus | Unset):
        workspace (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GetRegistryRegistriesRegistryIdEntriesResponse200
    """

    return (
        await asyncio_detailed(
            registry_id=registry_id,
            client=client,
            status=status,
            workspace=workspace,
        )
    ).parsed
