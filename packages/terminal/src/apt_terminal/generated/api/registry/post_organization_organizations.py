from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.post_organization_organizations_body import PostOrganizationOrganizationsBody
from ...models.registry_provisioned_organization import RegistryProvisionedOrganization
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    body: PostOrganizationOrganizationsBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    params: dict[str, Any] = {}

    params["workspace"] = workspace

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/organization/organizations",
        "params": params,
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | RegistryProvisionedOrganization | None:
    if response.status_code == 201:
        response_201 = RegistryProvisionedOrganization.from_dict(response.json())

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

    if response.status_code == 409:
        response_409 = Error.from_dict(response.json())

        return response_409

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | RegistryProvisionedOrganization]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    body: PostOrganizationOrganizationsBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> Response[Error | RegistryProvisionedOrganization]:
    """Create + provision an organization and its ownership chain

     Creates the organization owned by `workspace` (default: the caller personal workspace). Creating
    into an ORGANIZATION workspace requires admin of that org or of one above it in its ownership chain
    (or the site-admin grant) — 403 otherwise: the new org lands on that workspace's rail and is
    governed through its chain.

    Args:
        workspace (str | Unset):
        body (PostOrganizationOrganizationsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | RegistryProvisionedOrganization]
    """

    kwargs = _get_kwargs(
        body=body,
        workspace=workspace,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    body: PostOrganizationOrganizationsBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> Error | RegistryProvisionedOrganization | None:
    """Create + provision an organization and its ownership chain

     Creates the organization owned by `workspace` (default: the caller personal workspace). Creating
    into an ORGANIZATION workspace requires admin of that org or of one above it in its ownership chain
    (or the site-admin grant) — 403 otherwise: the new org lands on that workspace's rail and is
    governed through its chain.

    Args:
        workspace (str | Unset):
        body (PostOrganizationOrganizationsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | RegistryProvisionedOrganization
    """

    return sync_detailed(
        client=client,
        body=body,
        workspace=workspace,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    body: PostOrganizationOrganizationsBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> Response[Error | RegistryProvisionedOrganization]:
    """Create + provision an organization and its ownership chain

     Creates the organization owned by `workspace` (default: the caller personal workspace). Creating
    into an ORGANIZATION workspace requires admin of that org or of one above it in its ownership chain
    (or the site-admin grant) — 403 otherwise: the new org lands on that workspace's rail and is
    governed through its chain.

    Args:
        workspace (str | Unset):
        body (PostOrganizationOrganizationsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | RegistryProvisionedOrganization]
    """

    kwargs = _get_kwargs(
        body=body,
        workspace=workspace,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    body: PostOrganizationOrganizationsBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> Error | RegistryProvisionedOrganization | None:
    """Create + provision an organization and its ownership chain

     Creates the organization owned by `workspace` (default: the caller personal workspace). Creating
    into an ORGANIZATION workspace requires admin of that org or of one above it in its ownership chain
    (or the site-admin grant) — 403 otherwise: the new org lands on that workspace's rail and is
    governed through its chain.

    Args:
        workspace (str | Unset):
        body (PostOrganizationOrganizationsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | RegistryProvisionedOrganization
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
            workspace=workspace,
        )
    ).parsed
