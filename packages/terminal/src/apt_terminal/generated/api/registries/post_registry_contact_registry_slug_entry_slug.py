from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.post_registry_contact_registry_slug_entry_slug_body import (
    PostRegistryContactRegistrySlugEntrySlugBody,
)
from ...models.registry_contact_result import RegistryContactResult
from ...types import UNSET, Response, Unset


def _get_kwargs(
    registry_slug: str,
    entry_slug: str,
    *,
    body: PostRegistryContactRegistrySlugEntrySlugBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/registry/contact/{registry_slug}/{entry_slug}".format(
            registry_slug=quote(str(registry_slug), safe=""),
            entry_slug=quote(str(entry_slug), safe=""),
        ),
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | RegistryContactResult | None:
    if response.status_code == 201:
        response_201 = RegistryContactResult.from_dict(response.json())

        return response_201

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
        response_409 = Error.from_dict(response.json())

        return response_409

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | RegistryContactResult]:
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
    body: PostRegistryContactRegistrySlugEntrySlugBody | Unset = UNSET,
) -> Response[Error | RegistryContactResult]:
    """Open a DM with a public entry's owner and send the opening message

     Resolves the entry server-side from its two slugs — the visitor never learns the owner id unless the
    owner answers. Only a published entry with contactMode "dm" on a public registry is contactable; an
    org- or persona-owned entry has no user to DM (409). Gated behind the per-ecosystem `messaging` opt-
    in (403 when off).

    Args:
        registry_slug (str):
        entry_slug (str):
        body (PostRegistryContactRegistrySlugEntrySlugBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | RegistryContactResult]
    """

    kwargs = _get_kwargs(
        registry_slug=registry_slug,
        entry_slug=entry_slug,
        body=body,
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
    body: PostRegistryContactRegistrySlugEntrySlugBody | Unset = UNSET,
) -> Error | RegistryContactResult | None:
    """Open a DM with a public entry's owner and send the opening message

     Resolves the entry server-side from its two slugs — the visitor never learns the owner id unless the
    owner answers. Only a published entry with contactMode "dm" on a public registry is contactable; an
    org- or persona-owned entry has no user to DM (409). Gated behind the per-ecosystem `messaging` opt-
    in (403 when off).

    Args:
        registry_slug (str):
        entry_slug (str):
        body (PostRegistryContactRegistrySlugEntrySlugBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | RegistryContactResult
    """

    return sync_detailed(
        registry_slug=registry_slug,
        entry_slug=entry_slug,
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    registry_slug: str,
    entry_slug: str,
    *,
    client: AuthenticatedClient,
    body: PostRegistryContactRegistrySlugEntrySlugBody | Unset = UNSET,
) -> Response[Error | RegistryContactResult]:
    """Open a DM with a public entry's owner and send the opening message

     Resolves the entry server-side from its two slugs — the visitor never learns the owner id unless the
    owner answers. Only a published entry with contactMode "dm" on a public registry is contactable; an
    org- or persona-owned entry has no user to DM (409). Gated behind the per-ecosystem `messaging` opt-
    in (403 when off).

    Args:
        registry_slug (str):
        entry_slug (str):
        body (PostRegistryContactRegistrySlugEntrySlugBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | RegistryContactResult]
    """

    kwargs = _get_kwargs(
        registry_slug=registry_slug,
        entry_slug=entry_slug,
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    registry_slug: str,
    entry_slug: str,
    *,
    client: AuthenticatedClient,
    body: PostRegistryContactRegistrySlugEntrySlugBody | Unset = UNSET,
) -> Error | RegistryContactResult | None:
    """Open a DM with a public entry's owner and send the opening message

     Resolves the entry server-side from its two slugs — the visitor never learns the owner id unless the
    owner answers. Only a published entry with contactMode "dm" on a public registry is contactable; an
    org- or persona-owned entry has no user to DM (409). Gated behind the per-ecosystem `messaging` opt-
    in (403 when off).

    Args:
        registry_slug (str):
        entry_slug (str):
        body (PostRegistryContactRegistrySlugEntrySlugBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | RegistryContactResult
    """

    return (
        await asyncio_detailed(
            registry_slug=registry_slug,
            entry_slug=entry_slug,
            client=client,
            body=body,
        )
    ).parsed
