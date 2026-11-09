from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.get_v1_registry_entries_owner import GetV1RegistryEntriesOwner
from ...models.get_v1_registry_entries_response_200 import GetV1RegistryEntriesResponse200
from ...models.stripe_error import StripeError
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    owner: GetV1RegistryEntriesOwner | Unset = UNSET,
    registry: str,
    expand: list[str] | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    json_owner: str | Unset = UNSET
    if not isinstance(owner, Unset):
        json_owner = owner.value

    params["owner"] = json_owner

    params["registry"] = registry

    json_expand: list[str] | Unset = UNSET
    if not isinstance(expand, Unset):
        json_expand = expand

    params["expand[]"] = json_expand

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/v1/registry_entries",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> GetV1RegistryEntriesResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = GetV1RegistryEntriesResponse200.from_dict(response.json())

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
) -> Response[GetV1RegistryEntriesResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    owner: GetV1RegistryEntriesOwner | Unset = UNSET,
    registry: str,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1RegistryEntriesResponse200 | StripeError]:
    """Browse a registry’s published, public entries (newest first)

     Replaces GET /public/registries/{registrySlug}/entries, GET
    /registry/registries/{registryId}/entries, GET /registry/registries/{registryId}/entries/mine.

    Args:
        owner (GetV1RegistryEntriesOwner | Unset):
        registry (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1RegistryEntriesResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        owner=owner,
        registry=registry,
        expand=expand,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    owner: GetV1RegistryEntriesOwner | Unset = UNSET,
    registry: str,
    expand: list[str] | Unset = UNSET,
) -> GetV1RegistryEntriesResponse200 | StripeError | None:
    """Browse a registry’s published, public entries (newest first)

     Replaces GET /public/registries/{registrySlug}/entries, GET
    /registry/registries/{registryId}/entries, GET /registry/registries/{registryId}/entries/mine.

    Args:
        owner (GetV1RegistryEntriesOwner | Unset):
        registry (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1RegistryEntriesResponse200 | StripeError
    """

    return sync_detailed(
        client=client,
        owner=owner,
        registry=registry,
        expand=expand,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    owner: GetV1RegistryEntriesOwner | Unset = UNSET,
    registry: str,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1RegistryEntriesResponse200 | StripeError]:
    """Browse a registry’s published, public entries (newest first)

     Replaces GET /public/registries/{registrySlug}/entries, GET
    /registry/registries/{registryId}/entries, GET /registry/registries/{registryId}/entries/mine.

    Args:
        owner (GetV1RegistryEntriesOwner | Unset):
        registry (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1RegistryEntriesResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        owner=owner,
        registry=registry,
        expand=expand,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    owner: GetV1RegistryEntriesOwner | Unset = UNSET,
    registry: str,
    expand: list[str] | Unset = UNSET,
) -> GetV1RegistryEntriesResponse200 | StripeError | None:
    """Browse a registry’s published, public entries (newest first)

     Replaces GET /public/registries/{registrySlug}/entries, GET
    /registry/registries/{registryId}/entries, GET /registry/registries/{registryId}/entries/mine.

    Args:
        owner (GetV1RegistryEntriesOwner | Unset):
        registry (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1RegistryEntriesResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            client=client,
            owner=owner,
            registry=registry,
            expand=expand,
        )
    ).parsed
