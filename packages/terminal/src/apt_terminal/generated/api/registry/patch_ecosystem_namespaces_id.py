from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.patch_ecosystem_namespaces_id_body import PatchEcosystemNamespacesIdBody
from ...models.registry_namespace_update import RegistryNamespaceUpdate
from ...types import UNSET, Response, Unset


def _get_kwargs(
    id: str,
    *,
    body: PatchEcosystemNamespacesIdBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "patch",
        "url": "/ecosystem/namespaces/{id}".format(
            id=quote(str(id), safe=""),
        ),
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | RegistryNamespaceUpdate | None:
    if response.status_code == 200:
        response_200 = RegistryNamespaceUpdate.from_dict(response.json())

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
) -> Response[Error | RegistryNamespaceUpdate]:
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
    body: PatchEcosystemNamespacesIdBody | Unset = UNSET,
) -> Response[Error | RegistryNamespaceUpdate]:
    """Update a namespace handle/label (site-admin)

    Args:
        id (str):
        body (PatchEcosystemNamespacesIdBody | Unset): At least one of name or slug is required.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | RegistryNamespaceUpdate]
    """

    kwargs = _get_kwargs(
        id=id,
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    *,
    client: AuthenticatedClient,
    body: PatchEcosystemNamespacesIdBody | Unset = UNSET,
) -> Error | RegistryNamespaceUpdate | None:
    """Update a namespace handle/label (site-admin)

    Args:
        id (str):
        body (PatchEcosystemNamespacesIdBody | Unset): At least one of name or slug is required.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | RegistryNamespaceUpdate
    """

    return sync_detailed(
        id=id,
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
    body: PatchEcosystemNamespacesIdBody | Unset = UNSET,
) -> Response[Error | RegistryNamespaceUpdate]:
    """Update a namespace handle/label (site-admin)

    Args:
        id (str):
        body (PatchEcosystemNamespacesIdBody | Unset): At least one of name or slug is required.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | RegistryNamespaceUpdate]
    """

    kwargs = _get_kwargs(
        id=id,
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    *,
    client: AuthenticatedClient,
    body: PatchEcosystemNamespacesIdBody | Unset = UNSET,
) -> Error | RegistryNamespaceUpdate | None:
    """Update a namespace handle/label (site-admin)

    Args:
        id (str):
        body (PatchEcosystemNamespacesIdBody | Unset): At least one of name or slug is required.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | RegistryNamespaceUpdate
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            body=body,
        )
    ).parsed
