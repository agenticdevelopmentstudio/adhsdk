from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.get_v1_registry_entries_search_response_200 import (
    GetV1RegistryEntriesSearchResponse200,
)
from ...models.stripe_error import StripeError
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    registry: str,
    expand: list[str] | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["registry"] = registry

    json_expand: list[str] | Unset = UNSET
    if not isinstance(expand, Unset):
        json_expand = expand

    params["expand[]"] = json_expand

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/v1/registry_entries/search",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> GetV1RegistryEntriesSearchResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = GetV1RegistryEntriesSearchResponse200.from_dict(response.json())

        return response_200

    if response.status_code == 400:
        response_400 = StripeError.from_dict(response.json())

        return response_400

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[GetV1RegistryEntriesSearchResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient | Client,
    registry: str,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1RegistryEntriesSearchResponse200 | StripeError]:
    """Full-text search a registry’s published, public entries

     Replaces GET /public/registries/{registrySlug}/search.

    Args:
        registry (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1RegistryEntriesSearchResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        registry=registry,
        expand=expand,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient | Client,
    registry: str,
    expand: list[str] | Unset = UNSET,
) -> GetV1RegistryEntriesSearchResponse200 | StripeError | None:
    """Full-text search a registry’s published, public entries

     Replaces GET /public/registries/{registrySlug}/search.

    Args:
        registry (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1RegistryEntriesSearchResponse200 | StripeError
    """

    return sync_detailed(
        client=client,
        registry=registry,
        expand=expand,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient | Client,
    registry: str,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1RegistryEntriesSearchResponse200 | StripeError]:
    """Full-text search a registry’s published, public entries

     Replaces GET /public/registries/{registrySlug}/search.

    Args:
        registry (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1RegistryEntriesSearchResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        registry=registry,
        expand=expand,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient | Client,
    registry: str,
    expand: list[str] | Unset = UNSET,
) -> GetV1RegistryEntriesSearchResponse200 | StripeError | None:
    """Full-text search a registry’s published, public entries

     Replaces GET /public/registries/{registrySlug}/search.

    Args:
        registry (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1RegistryEntriesSearchResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            client=client,
            registry=registry,
            expand=expand,
        )
    ).parsed
