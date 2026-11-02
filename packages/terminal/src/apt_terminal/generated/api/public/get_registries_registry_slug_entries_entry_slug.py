from http import HTTPStatus
from typing import Any, cast
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.public_registry_entry_response import PublicRegistryEntryResponse
from ...types import Response


def _get_kwargs(
    registry_slug: str,
    entry_slug: str,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/registries/{registry_slug}/entries/{entry_slug}".format(
            registry_slug=quote(str(registry_slug), safe=""),
            entry_slug=quote(str(entry_slug), safe=""),
        ),
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Any | Error | PublicRegistryEntryResponse | None:
    if response.status_code == 200:
        response_200 = PublicRegistryEntryResponse.from_dict(response.json())

        return response_200

    if response.status_code == 301:
        response_301 = cast(Any, None)
        return response_301

    if response.status_code == 401:
        response_401 = Error.from_dict(response.json())

        return response_401

    if response.status_code == 404:
        response_404 = Error.from_dict(response.json())

        return response_404

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Any | Error | PublicRegistryEntryResponse]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    registry_slug: str,
    entry_slug: str,
    *,
    client: AuthenticatedClient,
) -> Response[Any | Error | PublicRegistryEntryResponse]:
    """Get one entry as a signed-in viewer (public + authenticated fields, 'hub' rows)

    Args:
        registry_slug (str):
        entry_slug (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Any | Error | PublicRegistryEntryResponse]
    """

    kwargs = _get_kwargs(
        registry_slug=registry_slug,
        entry_slug=entry_slug,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    registry_slug: str,
    entry_slug: str,
    *,
    client: AuthenticatedClient,
) -> Any | Error | PublicRegistryEntryResponse | None:
    """Get one entry as a signed-in viewer (public + authenticated fields, 'hub' rows)

    Args:
        registry_slug (str):
        entry_slug (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Any | Error | PublicRegistryEntryResponse
    """

    return sync_detailed(
        registry_slug=registry_slug,
        entry_slug=entry_slug,
        client=client,
    ).parsed


async def asyncio_detailed(
    registry_slug: str,
    entry_slug: str,
    *,
    client: AuthenticatedClient,
) -> Response[Any | Error | PublicRegistryEntryResponse]:
    """Get one entry as a signed-in viewer (public + authenticated fields, 'hub' rows)

    Args:
        registry_slug (str):
        entry_slug (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Any | Error | PublicRegistryEntryResponse]
    """

    kwargs = _get_kwargs(
        registry_slug=registry_slug,
        entry_slug=entry_slug,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    registry_slug: str,
    entry_slug: str,
    *,
    client: AuthenticatedClient,
) -> Any | Error | PublicRegistryEntryResponse | None:
    """Get one entry as a signed-in viewer (public + authenticated fields, 'hub' rows)

    Args:
        registry_slug (str):
        entry_slug (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Any | Error | PublicRegistryEntryResponse
    """

    return (
        await asyncio_detailed(
            registry_slug=registry_slug,
            entry_slug=entry_slug,
            client=client,
        )
    ).parsed
