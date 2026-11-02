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
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["page"] = page

    params["pageSize"] = page_size

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/public/registries/{registry_slug}/entries".format(
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
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
) -> Response[PublicRegistryEntryList]:
    """Browse a registry’s published, public entries (newest first)

    Args:
        registry_slug (str):
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
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
) -> PublicRegistryEntryList | None:
    """Browse a registry’s published, public entries (newest first)

    Args:
        registry_slug (str):
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
        page=page,
        page_size=page_size,
    ).parsed


async def asyncio_detailed(
    registry_slug: str,
    *,
    client: AuthenticatedClient | Client,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
) -> Response[PublicRegistryEntryList]:
    """Browse a registry’s published, public entries (newest first)

    Args:
        registry_slug (str):
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
        page=page,
        page_size=page_size,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    registry_slug: str,
    *,
    client: AuthenticatedClient | Client,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
) -> PublicRegistryEntryList | None:
    """Browse a registry’s published, public entries (newest first)

    Args:
        registry_slug (str):
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
            page=page,
            page_size=page_size,
        )
    ).parsed
