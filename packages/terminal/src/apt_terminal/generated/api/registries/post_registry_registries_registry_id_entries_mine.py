from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.registry_entry import RegistryEntry
from ...types import UNSET, Response, Unset


def _get_kwargs(
    registry_id: str,
    *,
    workspace: str | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["workspace"] = workspace

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/registry/registries/{registry_id}/entries/mine".format(
            registry_id=quote(str(registry_id), safe=""),
        ),
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | RegistryEntry | None:
    if response.status_code == 200:
        response_200 = RegistryEntry.from_dict(response.json())

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
) -> Response[Error | RegistryEntry]:
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
    workspace: str | Unset = UNSET,
) -> Response[Error | RegistryEntry]:
    """The caller's own entry in this registry, created as a draft if they have none. Idempotent — a
    concurrent first call returns the same row either way, never a 409

     Takes no body: everything about the new row is derived from the caller and the registry (`draft`
    status, the registry's default visibility, an empty `values`). Returns 200 with the existing row
    when one is already there, so a client may call it unconditionally when opening the editor.
    Idempotency is enforced by `uq_entries_registry_owner`, not by the read that precedes the insert.

    Args:
        registry_id (str):
        workspace (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | RegistryEntry]
    """

    kwargs = _get_kwargs(
        registry_id=registry_id,
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
    workspace: str | Unset = UNSET,
) -> Error | RegistryEntry | None:
    """The caller's own entry in this registry, created as a draft if they have none. Idempotent — a
    concurrent first call returns the same row either way, never a 409

     Takes no body: everything about the new row is derived from the caller and the registry (`draft`
    status, the registry's default visibility, an empty `values`). Returns 200 with the existing row
    when one is already there, so a client may call it unconditionally when opening the editor.
    Idempotency is enforced by `uq_entries_registry_owner`, not by the read that precedes the insert.

    Args:
        registry_id (str):
        workspace (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | RegistryEntry
    """

    return sync_detailed(
        registry_id=registry_id,
        client=client,
        workspace=workspace,
    ).parsed


async def asyncio_detailed(
    registry_id: str,
    *,
    client: AuthenticatedClient,
    workspace: str | Unset = UNSET,
) -> Response[Error | RegistryEntry]:
    """The caller's own entry in this registry, created as a draft if they have none. Idempotent — a
    concurrent first call returns the same row either way, never a 409

     Takes no body: everything about the new row is derived from the caller and the registry (`draft`
    status, the registry's default visibility, an empty `values`). Returns 200 with the existing row
    when one is already there, so a client may call it unconditionally when opening the editor.
    Idempotency is enforced by `uq_entries_registry_owner`, not by the read that precedes the insert.

    Args:
        registry_id (str):
        workspace (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | RegistryEntry]
    """

    kwargs = _get_kwargs(
        registry_id=registry_id,
        workspace=workspace,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    registry_id: str,
    *,
    client: AuthenticatedClient,
    workspace: str | Unset = UNSET,
) -> Error | RegistryEntry | None:
    """The caller's own entry in this registry, created as a draft if they have none. Idempotent — a
    concurrent first call returns the same row either way, never a 409

     Takes no body: everything about the new row is derived from the caller and the registry (`draft`
    status, the registry's default visibility, an empty `values`). Returns 200 with the existing row
    when one is already there, so a client may call it unconditionally when opening the editor.
    Idempotency is enforced by `uq_entries_registry_owner`, not by the read that precedes the insert.

    Args:
        registry_id (str):
        workspace (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | RegistryEntry
    """

    return (
        await asyncio_detailed(
            registry_id=registry_id,
            client=client,
            workspace=workspace,
        )
    ).parsed
