from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.registry_identifier import RegistryIdentifier
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    q: str | Unset = UNSET,
    entity_ids: str | Unset = UNSET,
    entity_type: str | Unset = UNSET,
    limit: str | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["q"] = q

    params["entityIds"] = entity_ids

    params["entityType"] = entity_type

    params["limit"] = limit

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/registry/identifiers",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | list[RegistryIdentifier] | None:
    if response.status_code == 200:
        response_200 = []
        _response_200 = response.json()
        for response_200_item_data in _response_200:
            response_200_item = RegistryIdentifier.from_dict(response_200_item_data)

            response_200.append(response_200_item)

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

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | list[RegistryIdentifier]]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    q: str | Unset = UNSET,
    entity_ids: str | Unset = UNSET,
    entity_type: str | Unset = UNSET,
    limit: str | Unset = UNSET,
) -> Response[Error | list[RegistryIdentifier]]:
    """Search rdids by prefix, or resolve a batch of entity ids (admin only)

     Send `q` for a left-anchored prefix search, or `entityIds` for a batch reverse lookup — never both.
    Only canonical rows are returned; aliases are never offered. Unknown ids in a batch are omitted
    rather than failing the request.

    Args:
        q (str | Unset):
        entity_ids (str | Unset):
        entity_type (str | Unset):
        limit (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | list[RegistryIdentifier]]
    """

    kwargs = _get_kwargs(
        q=q,
        entity_ids=entity_ids,
        entity_type=entity_type,
        limit=limit,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    q: str | Unset = UNSET,
    entity_ids: str | Unset = UNSET,
    entity_type: str | Unset = UNSET,
    limit: str | Unset = UNSET,
) -> Error | list[RegistryIdentifier] | None:
    """Search rdids by prefix, or resolve a batch of entity ids (admin only)

     Send `q` for a left-anchored prefix search, or `entityIds` for a batch reverse lookup — never both.
    Only canonical rows are returned; aliases are never offered. Unknown ids in a batch are omitted
    rather than failing the request.

    Args:
        q (str | Unset):
        entity_ids (str | Unset):
        entity_type (str | Unset):
        limit (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | list[RegistryIdentifier]
    """

    return sync_detailed(
        client=client,
        q=q,
        entity_ids=entity_ids,
        entity_type=entity_type,
        limit=limit,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    q: str | Unset = UNSET,
    entity_ids: str | Unset = UNSET,
    entity_type: str | Unset = UNSET,
    limit: str | Unset = UNSET,
) -> Response[Error | list[RegistryIdentifier]]:
    """Search rdids by prefix, or resolve a batch of entity ids (admin only)

     Send `q` for a left-anchored prefix search, or `entityIds` for a batch reverse lookup — never both.
    Only canonical rows are returned; aliases are never offered. Unknown ids in a batch are omitted
    rather than failing the request.

    Args:
        q (str | Unset):
        entity_ids (str | Unset):
        entity_type (str | Unset):
        limit (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | list[RegistryIdentifier]]
    """

    kwargs = _get_kwargs(
        q=q,
        entity_ids=entity_ids,
        entity_type=entity_type,
        limit=limit,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    q: str | Unset = UNSET,
    entity_ids: str | Unset = UNSET,
    entity_type: str | Unset = UNSET,
    limit: str | Unset = UNSET,
) -> Error | list[RegistryIdentifier] | None:
    """Search rdids by prefix, or resolve a batch of entity ids (admin only)

     Send `q` for a left-anchored prefix search, or `entityIds` for a batch reverse lookup — never both.
    Only canonical rows are returned; aliases are never offered. Unknown ids in a batch are omitted
    rather than failing the request.

    Args:
        q (str | Unset):
        entity_ids (str | Unset):
        entity_type (str | Unset):
        limit (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | list[RegistryIdentifier]
    """

    return (
        await asyncio_detailed(
            client=client,
            q=q,
            entity_ids=entity_ids,
            entity_type=entity_type,
            limit=limit,
        )
    ).parsed
