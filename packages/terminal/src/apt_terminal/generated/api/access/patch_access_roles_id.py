from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.access_role_envelope import AccessRoleEnvelope
from ...models.error import Error
from ...models.patch_access_roles_id_body import PatchAccessRolesIdBody
from ...types import UNSET, Response, Unset


def _get_kwargs(
    id: str,
    *,
    body: PatchAccessRolesIdBody | Unset = UNSET,
    workspace: str,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    params: dict[str, Any] = {}

    params["workspace"] = workspace

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "patch",
        "url": "/access/roles/{id}".format(
            id=quote(str(id), safe=""),
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
) -> AccessRoleEnvelope | Error | None:
    if response.status_code == 200:
        response_200 = AccessRoleEnvelope.from_dict(response.json())

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

    if response.status_code == 409:
        response_409 = Error.from_dict(response.json())

        return response_409

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[AccessRoleEnvelope | Error]:
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
    body: PatchAccessRolesIdBody | Unset = UNSET,
    workspace: str,
) -> Response[AccessRoleEnvelope | Error]:
    """Edit a role (name/description/default/grants; the system admin role is immutable)

    Args:
        id (str):
        workspace (str):
        body (PatchAccessRolesIdBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[AccessRoleEnvelope | Error]
    """

    kwargs = _get_kwargs(
        id=id,
        body=body,
        workspace=workspace,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    *,
    client: AuthenticatedClient,
    body: PatchAccessRolesIdBody | Unset = UNSET,
    workspace: str,
) -> AccessRoleEnvelope | Error | None:
    """Edit a role (name/description/default/grants; the system admin role is immutable)

    Args:
        id (str):
        workspace (str):
        body (PatchAccessRolesIdBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        AccessRoleEnvelope | Error
    """

    return sync_detailed(
        id=id,
        client=client,
        body=body,
        workspace=workspace,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
    body: PatchAccessRolesIdBody | Unset = UNSET,
    workspace: str,
) -> Response[AccessRoleEnvelope | Error]:
    """Edit a role (name/description/default/grants; the system admin role is immutable)

    Args:
        id (str):
        workspace (str):
        body (PatchAccessRolesIdBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[AccessRoleEnvelope | Error]
    """

    kwargs = _get_kwargs(
        id=id,
        body=body,
        workspace=workspace,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    *,
    client: AuthenticatedClient,
    body: PatchAccessRolesIdBody | Unset = UNSET,
    workspace: str,
) -> AccessRoleEnvelope | Error | None:
    """Edit a role (name/description/default/grants; the system admin role is immutable)

    Args:
        id (str):
        workspace (str):
        body (PatchAccessRolesIdBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        AccessRoleEnvelope | Error
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            body=body,
            workspace=workspace,
        )
    ).parsed
