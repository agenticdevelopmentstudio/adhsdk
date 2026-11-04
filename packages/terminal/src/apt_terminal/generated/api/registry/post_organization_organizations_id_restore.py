from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.post_organization_organizations_id_restore_response_200 import (
    PostOrganizationOrganizationsIdRestoreResponse200,
)
from ...types import Response


def _get_kwargs(
    id: str,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/organization/organizations/{id}/restore".format(
            id=quote(str(id), safe=""),
        ),
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | PostOrganizationOrganizationsIdRestoreResponse200 | None:
    if response.status_code == 200:
        response_200 = PostOrganizationOrganizationsIdRestoreResponse200.from_dict(response.json())

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

    if response.status_code == 409:
        response_409 = Error.from_dict(response.json())

        return response_409

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | PostOrganizationOrganizationsIdRestoreResponse200]:
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
) -> Response[Error | PostOrganizationOrganizationsIdRestoreResponse200]:
    """Restore an archived organization to its own rdid (org creator, org-team admin, or site-admin)

     Restores the organization under its own slug, and its workspace under the owner's workspace as it is
    now; an address that moves with it keeps its old form as an alias. A 409 leaves the organization
    archived: its handle was taken while it was archived, by an organization or as a user slug; `code:
    owner_org_archived` while the organization that owns it is archived (restore that one first); `code:
    owner_has_no_workspace` when its owner has no workspace to restore its own into; or the restored
    addresses would be inconsistent (`violations`).

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PostOrganizationOrganizationsIdRestoreResponse200]
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
) -> Error | PostOrganizationOrganizationsIdRestoreResponse200 | None:
    """Restore an archived organization to its own rdid (org creator, org-team admin, or site-admin)

     Restores the organization under its own slug, and its workspace under the owner's workspace as it is
    now; an address that moves with it keeps its old form as an alias. A 409 leaves the organization
    archived: its handle was taken while it was archived, by an organization or as a user slug; `code:
    owner_org_archived` while the organization that owns it is archived (restore that one first); `code:
    owner_has_no_workspace` when its owner has no workspace to restore its own into; or the restored
    addresses would be inconsistent (`violations`).

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PostOrganizationOrganizationsIdRestoreResponse200
    """

    return sync_detailed(
        id=id,
        client=client,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
) -> Response[Error | PostOrganizationOrganizationsIdRestoreResponse200]:
    """Restore an archived organization to its own rdid (org creator, org-team admin, or site-admin)

     Restores the organization under its own slug, and its workspace under the owner's workspace as it is
    now; an address that moves with it keeps its old form as an alias. A 409 leaves the organization
    archived: its handle was taken while it was archived, by an organization or as a user slug; `code:
    owner_org_archived` while the organization that owns it is archived (restore that one first); `code:
    owner_has_no_workspace` when its owner has no workspace to restore its own into; or the restored
    addresses would be inconsistent (`violations`).

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PostOrganizationOrganizationsIdRestoreResponse200]
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
) -> Error | PostOrganizationOrganizationsIdRestoreResponse200 | None:
    """Restore an archived organization to its own rdid (org creator, org-team admin, or site-admin)

     Restores the organization under its own slug, and its workspace under the owner's workspace as it is
    now; an address that moves with it keeps its old form as an alias. A 409 leaves the organization
    archived: its handle was taken while it was archived, by an organization or as a user slug; `code:
    owner_org_archived` while the organization that owns it is archived (restore that one first); `code:
    owner_has_no_workspace` when its owner has no workspace to restore its own into; or the restored
    addresses would be inconsistent (`violations`).

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PostOrganizationOrganizationsIdRestoreResponse200
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
        )
    ).parsed
