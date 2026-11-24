from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.get_v1_registry_entries_by_id_services_response_200 import (
    GetV1RegistryEntriesByIdServicesResponse200,
)
from ...models.stripe_error import StripeError
from ...types import UNSET, Response, Unset


def _get_kwargs(
    id: str,
    *,
    registry: str,
    limit: int | Unset = 10,
    starting_after: str | Unset = UNSET,
    ending_before: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["registry"] = registry

    params["limit"] = limit

    params["starting_after"] = starting_after

    params["ending_before"] = ending_before

    json_expand: list[str] | Unset = UNSET
    if not isinstance(expand, Unset):
        json_expand = expand

    params["expand[]"] = json_expand

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/v1/registry_entries/{id}/services".format(
            id=quote(str(id), safe=""),
        ),
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> GetV1RegistryEntriesByIdServicesResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = GetV1RegistryEntriesByIdServicesResponse200.from_dict(response.json())

        return response_200

    if response.status_code == 400:
        response_400 = StripeError.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = StripeError.from_dict(response.json())

        return response_401

    if response.status_code == 403:
        response_403 = StripeError.from_dict(response.json())

        return response_403

    if response.status_code == 404:
        response_404 = StripeError.from_dict(response.json())

        return response_404

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[GetV1RegistryEntriesByIdServicesResponse200 | StripeError]:
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
    registry: str,
    limit: int | Unset = 10,
    starting_after: str | Unset = UNSET,
    ending_before: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1RegistryEntriesByIdServicesResponse200 | StripeError]:
    """List an entry's services (non-deleted, by sortOrder)

     Replaces GET /registry/registries/{registryId}/entries/{entryId}/services.

    Args:
        id (str):
        registry (str):
        limit (int | Unset):  Default: 10.
        starting_after (str | Unset):
        ending_before (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1RegistryEntriesByIdServicesResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
        registry=registry,
        limit=limit,
        starting_after=starting_after,
        ending_before=ending_before,
        expand=expand,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    *,
    client: AuthenticatedClient,
    registry: str,
    limit: int | Unset = 10,
    starting_after: str | Unset = UNSET,
    ending_before: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> GetV1RegistryEntriesByIdServicesResponse200 | StripeError | None:
    """List an entry's services (non-deleted, by sortOrder)

     Replaces GET /registry/registries/{registryId}/entries/{entryId}/services.

    Args:
        id (str):
        registry (str):
        limit (int | Unset):  Default: 10.
        starting_after (str | Unset):
        ending_before (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1RegistryEntriesByIdServicesResponse200 | StripeError
    """

    return sync_detailed(
        id=id,
        client=client,
        registry=registry,
        limit=limit,
        starting_after=starting_after,
        ending_before=ending_before,
        expand=expand,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
    registry: str,
    limit: int | Unset = 10,
    starting_after: str | Unset = UNSET,
    ending_before: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1RegistryEntriesByIdServicesResponse200 | StripeError]:
    """List an entry's services (non-deleted, by sortOrder)

     Replaces GET /registry/registries/{registryId}/entries/{entryId}/services.

    Args:
        id (str):
        registry (str):
        limit (int | Unset):  Default: 10.
        starting_after (str | Unset):
        ending_before (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1RegistryEntriesByIdServicesResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
        registry=registry,
        limit=limit,
        starting_after=starting_after,
        ending_before=ending_before,
        expand=expand,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    *,
    client: AuthenticatedClient,
    registry: str,
    limit: int | Unset = 10,
    starting_after: str | Unset = UNSET,
    ending_before: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> GetV1RegistryEntriesByIdServicesResponse200 | StripeError | None:
    """List an entry's services (non-deleted, by sortOrder)

     Replaces GET /registry/registries/{registryId}/entries/{entryId}/services.

    Args:
        id (str):
        registry (str):
        limit (int | Unset):  Default: 10.
        starting_after (str | Unset):
        ending_before (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1RegistryEntriesByIdServicesResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            registry=registry,
            limit=limit,
            starting_after=starting_after,
            ending_before=ending_before,
            expand=expand,
        )
    ).parsed
