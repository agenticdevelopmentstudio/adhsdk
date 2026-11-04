from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.delete_ecosystem_features_id_key_response_200 import (
    DeleteEcosystemFeaturesIdKeyResponse200,
)
from ...models.delete_ecosystem_features_id_key_response_409 import (
    DeleteEcosystemFeaturesIdKeyResponse409,
)
from ...models.error import Error
from ...types import Response


def _get_kwargs(
    id: str,
    key: str,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "delete",
        "url": "/ecosystem/features/{id}/{key}".format(
            id=quote(str(id), safe=""),
            key=quote(str(key), safe=""),
        ),
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> (
    DeleteEcosystemFeaturesIdKeyResponse200 | DeleteEcosystemFeaturesIdKeyResponse409 | Error | None
):
    if response.status_code == 200:
        response_200 = DeleteEcosystemFeaturesIdKeyResponse200.from_dict(response.json())

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
        response_409 = DeleteEcosystemFeaturesIdKeyResponse409.from_dict(response.json())

        return response_409

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[
    DeleteEcosystemFeaturesIdKeyResponse200 | DeleteEcosystemFeaturesIdKeyResponse409 | Error
]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    id: str,
    key: str,
    *,
    client: AuthenticatedClient,
) -> Response[
    DeleteEcosystemFeaturesIdKeyResponse200 | DeleteEcosystemFeaturesIdKeyResponse409 | Error
]:
    """Take a feature off the ecosystem

     Marks the feature removed and DESTROYS NOTHING — the buckets, roles and rows it provisioned are left
    exactly as they are. Taking a feature off the rail is a display decision; deleting the owner’s data
    is not, and the two do not share a verb. What comes with the feature (`includedWith`) is taken off
    with it; a feature that comes with another cannot be taken off on its own (400).

    Args:
        id (str):
        key (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[DeleteEcosystemFeaturesIdKeyResponse200 | DeleteEcosystemFeaturesIdKeyResponse409 | Error]
    """

    kwargs = _get_kwargs(
        id=id,
        key=key,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    key: str,
    *,
    client: AuthenticatedClient,
) -> (
    DeleteEcosystemFeaturesIdKeyResponse200 | DeleteEcosystemFeaturesIdKeyResponse409 | Error | None
):
    """Take a feature off the ecosystem

     Marks the feature removed and DESTROYS NOTHING — the buckets, roles and rows it provisioned are left
    exactly as they are. Taking a feature off the rail is a display decision; deleting the owner’s data
    is not, and the two do not share a verb. What comes with the feature (`includedWith`) is taken off
    with it; a feature that comes with another cannot be taken off on its own (400).

    Args:
        id (str):
        key (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        DeleteEcosystemFeaturesIdKeyResponse200 | DeleteEcosystemFeaturesIdKeyResponse409 | Error
    """

    return sync_detailed(
        id=id,
        key=key,
        client=client,
    ).parsed


async def asyncio_detailed(
    id: str,
    key: str,
    *,
    client: AuthenticatedClient,
) -> Response[
    DeleteEcosystemFeaturesIdKeyResponse200 | DeleteEcosystemFeaturesIdKeyResponse409 | Error
]:
    """Take a feature off the ecosystem

     Marks the feature removed and DESTROYS NOTHING — the buckets, roles and rows it provisioned are left
    exactly as they are. Taking a feature off the rail is a display decision; deleting the owner’s data
    is not, and the two do not share a verb. What comes with the feature (`includedWith`) is taken off
    with it; a feature that comes with another cannot be taken off on its own (400).

    Args:
        id (str):
        key (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[DeleteEcosystemFeaturesIdKeyResponse200 | DeleteEcosystemFeaturesIdKeyResponse409 | Error]
    """

    kwargs = _get_kwargs(
        id=id,
        key=key,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    key: str,
    *,
    client: AuthenticatedClient,
) -> (
    DeleteEcosystemFeaturesIdKeyResponse200 | DeleteEcosystemFeaturesIdKeyResponse409 | Error | None
):
    """Take a feature off the ecosystem

     Marks the feature removed and DESTROYS NOTHING — the buckets, roles and rows it provisioned are left
    exactly as they are. Taking a feature off the rail is a display decision; deleting the owner’s data
    is not, and the two do not share a verb. What comes with the feature (`includedWith`) is taken off
    with it; a feature that comes with another cannot be taken off on its own (400).

    Args:
        id (str):
        key (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        DeleteEcosystemFeaturesIdKeyResponse200 | DeleteEcosystemFeaturesIdKeyResponse409 | Error
    """

    return (
        await asyncio_detailed(
            id=id,
            key=key,
            client=client,
        )
    ).parsed
