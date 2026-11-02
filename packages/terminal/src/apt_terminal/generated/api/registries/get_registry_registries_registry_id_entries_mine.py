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
        "method": "get",
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
    """The caller's own entry in this registry, or 404 if they have none — a pure read that never creates
    one

     The creating half is POST on this same path. Splitting them is what keeps a GET from writing: this
    route is reachable by anyone who can read the registry, so a get-or-create GET planted a draft entry
    for every signed-in passer-by, and those drafts are visible to the registry's owner through GET
    /entries. 404 here means "you have no entry yet", which is a normal state, not an error.

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
    """The caller's own entry in this registry, or 404 if they have none — a pure read that never creates
    one

     The creating half is POST on this same path. Splitting them is what keeps a GET from writing: this
    route is reachable by anyone who can read the registry, so a get-or-create GET planted a draft entry
    for every signed-in passer-by, and those drafts are visible to the registry's owner through GET
    /entries. 404 here means "you have no entry yet", which is a normal state, not an error.

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
    """The caller's own entry in this registry, or 404 if they have none — a pure read that never creates
    one

     The creating half is POST on this same path. Splitting them is what keeps a GET from writing: this
    route is reachable by anyone who can read the registry, so a get-or-create GET planted a draft entry
    for every signed-in passer-by, and those drafts are visible to the registry's owner through GET
    /entries. 404 here means "you have no entry yet", which is a normal state, not an error.

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
    """The caller's own entry in this registry, or 404 if they have none — a pure read that never creates
    one

     The creating half is POST on this same path. Splitting them is what keeps a GET from writing: this
    route is reachable by anyone who can read the registry, so a get-or-create GET planted a draft entry
    for every signed-in passer-by, and those drafts are visible to the registry's owner through GET
    /entries. 404 here means "you have no entry yet", which is a normal state, not an error.

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
