from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.patch_registry_identifiers_rdid_body import PatchRegistryIdentifiersRdidBody
from ...models.registry_identifier import RegistryIdentifier
from ...types import UNSET, Response, Unset


def _get_kwargs(
    rdid: str,
    *,
    body: PatchRegistryIdentifiersRdidBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "patch",
        "url": "/registry/identifiers/{rdid}".format(
            rdid=quote(str(rdid), safe=""),
        ),
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | RegistryIdentifier | None:
    if response.status_code == 200:
        response_200 = RegistryIdentifier.from_dict(response.json())

        return response_200

    if response.status_code == 400:
        response_400 = Error.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = Error.from_dict(response.json())

        return response_401

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
) -> Response[Error | RegistryIdentifier]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    rdid: str,
    *,
    client: AuthenticatedClient,
    body: PatchRegistryIdentifiersRdidBody | Unset = UNSET,
) -> Response[Error | RegistryIdentifier]:
    """Rename an rdid (entity/uuid unchanged)

    Args:
        rdid (str):
        body (PatchRegistryIdentifiersRdidBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | RegistryIdentifier]
    """

    kwargs = _get_kwargs(
        rdid=rdid,
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    rdid: str,
    *,
    client: AuthenticatedClient,
    body: PatchRegistryIdentifiersRdidBody | Unset = UNSET,
) -> Error | RegistryIdentifier | None:
    """Rename an rdid (entity/uuid unchanged)

    Args:
        rdid (str):
        body (PatchRegistryIdentifiersRdidBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | RegistryIdentifier
    """

    return sync_detailed(
        rdid=rdid,
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    rdid: str,
    *,
    client: AuthenticatedClient,
    body: PatchRegistryIdentifiersRdidBody | Unset = UNSET,
) -> Response[Error | RegistryIdentifier]:
    """Rename an rdid (entity/uuid unchanged)

    Args:
        rdid (str):
        body (PatchRegistryIdentifiersRdidBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | RegistryIdentifier]
    """

    kwargs = _get_kwargs(
        rdid=rdid,
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    rdid: str,
    *,
    client: AuthenticatedClient,
    body: PatchRegistryIdentifiersRdidBody | Unset = UNSET,
) -> Error | RegistryIdentifier | None:
    """Rename an rdid (entity/uuid unchanged)

    Args:
        rdid (str):
        body (PatchRegistryIdentifiersRdidBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | RegistryIdentifier
    """

    return (
        await asyncio_detailed(
            rdid=rdid,
            client=client,
            body=body,
        )
    ).parsed
