from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.public_registry_entry_list import PublicRegistryEntryList
from ...types import UNSET, Response, Unset


def _get_kwargs(
    registry_slug: str,
    *,
    q: str | Unset = UNSET,
    category: str | Unset = UNSET,
    delivery_mode: str | Unset = UNSET,
    pricing_model: str | Unset = UNSET,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["q"] = q

    params["category"] = category

    params["deliveryMode"] = delivery_mode

    params["pricingModel"] = pricing_model

    params["page"] = page

    params["pageSize"] = page_size

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/public/registries/{registry_slug}/search".format(
            registry_slug=quote(str(registry_slug), safe=""),
        ),
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PublicRegistryEntryList | None:
    if response.status_code == 200:
        response_200 = PublicRegistryEntryList.from_dict(response.json())

        return response_200

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[PublicRegistryEntryList]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    registry_slug: str,
    *,
    client: AuthenticatedClient | Client,
    q: str | Unset = UNSET,
    category: str | Unset = UNSET,
    delivery_mode: str | Unset = UNSET,
    pricing_model: str | Unset = UNSET,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
) -> Response[PublicRegistryEntryList]:
    """Full-text search a registry’s published, public entries

    Args:
        registry_slug (str):
        q (str | Unset):
        category (str | Unset):
        delivery_mode (str | Unset):
        pricing_model (str | Unset):
        page (str | Unset):
        page_size (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PublicRegistryEntryList]
    """

    kwargs = _get_kwargs(
        registry_slug=registry_slug,
        q=q,
        category=category,
        delivery_mode=delivery_mode,
        pricing_model=pricing_model,
        page=page,
        page_size=page_size,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    registry_slug: str,
    *,
    client: AuthenticatedClient | Client,
    q: str | Unset = UNSET,
    category: str | Unset = UNSET,
    delivery_mode: str | Unset = UNSET,
    pricing_model: str | Unset = UNSET,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
) -> PublicRegistryEntryList | None:
    """Full-text search a registry’s published, public entries

    Args:
        registry_slug (str):
        q (str | Unset):
        category (str | Unset):
        delivery_mode (str | Unset):
        pricing_model (str | Unset):
        page (str | Unset):
        page_size (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PublicRegistryEntryList
    """

    return sync_detailed(
        registry_slug=registry_slug,
        client=client,
        q=q,
        category=category,
        delivery_mode=delivery_mode,
        pricing_model=pricing_model,
        page=page,
        page_size=page_size,
    ).parsed


async def asyncio_detailed(
    registry_slug: str,
    *,
    client: AuthenticatedClient | Client,
    q: str | Unset = UNSET,
    category: str | Unset = UNSET,
    delivery_mode: str | Unset = UNSET,
    pricing_model: str | Unset = UNSET,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
) -> Response[PublicRegistryEntryList]:
    """Full-text search a registry’s published, public entries

    Args:
        registry_slug (str):
        q (str | Unset):
        category (str | Unset):
        delivery_mode (str | Unset):
        pricing_model (str | Unset):
        page (str | Unset):
        page_size (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PublicRegistryEntryList]
    """

    kwargs = _get_kwargs(
        registry_slug=registry_slug,
        q=q,
        category=category,
        delivery_mode=delivery_mode,
        pricing_model=pricing_model,
        page=page,
        page_size=page_size,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    registry_slug: str,
    *,
    client: AuthenticatedClient | Client,
    q: str | Unset = UNSET,
    category: str | Unset = UNSET,
    delivery_mode: str | Unset = UNSET,
    pricing_model: str | Unset = UNSET,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
) -> PublicRegistryEntryList | None:
    """Full-text search a registry’s published, public entries

    Args:
        registry_slug (str):
        q (str | Unset):
        category (str | Unset):
        delivery_mode (str | Unset):
        pricing_model (str | Unset):
        page (str | Unset):
        page_size (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PublicRegistryEntryList
    """

    return (
        await asyncio_detailed(
            registry_slug=registry_slug,
            client=client,
            q=q,
            category=category,
            delivery_mode=delivery_mode,
            pricing_model=pricing_model,
            page=page,
            page_size=page_size,
        )
    ).parsed
