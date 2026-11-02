from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.visitor_token import VisitorToken
from ...types import Response


def _get_kwargs(
    slug: str,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/public/personas/{slug}/visitor-tokens".format(
            slug=quote(str(slug), safe=""),
        ),
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | VisitorToken | None:
    if response.status_code == 201:
        response_201 = VisitorToken.from_dict(response.json())

        return response_201

    if response.status_code == 403:
        response_403 = Error.from_dict(response.json())

        return response_403

    if response.status_code == 404:
        response_404 = Error.from_dict(response.json())

        return response_404

    if response.status_code == 409:
        response_409 = Error.from_dict(response.json())

        return response_409

    if response.status_code == 429:
        response_429 = Error.from_dict(response.json())

        return response_429

    if response.status_code == 503:
        response_503 = Error.from_dict(response.json())

        return response_503

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | VisitorToken]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    slug: str,
    *,
    client: AuthenticatedClient | Client,
) -> Response[Error | VisitorToken]:
    """Mint an anonymous visitor token for a public persona

     Unauthenticated, and the only way to obtain a visitor token. The token is returned once and never
    again — nothing server-side can reproduce it.

    Slugs are unique per owner, not globally, so a slug shared by two *public* personas is a 409 rather
    than an arbitrary pick. A persona that is not public, does not exist, or whose owner cannot be
    resolved is uniformly a 404.

    Refused with 403 when the owning ecosystem has not enabled visitor chat, 503 when visitor chat is
    switched off globally, and 429 past the per-IP hourly mint limit.

    Args:
        slug (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | VisitorToken]
    """

    kwargs = _get_kwargs(
        slug=slug,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    slug: str,
    *,
    client: AuthenticatedClient | Client,
) -> Error | VisitorToken | None:
    """Mint an anonymous visitor token for a public persona

     Unauthenticated, and the only way to obtain a visitor token. The token is returned once and never
    again — nothing server-side can reproduce it.

    Slugs are unique per owner, not globally, so a slug shared by two *public* personas is a 409 rather
    than an arbitrary pick. A persona that is not public, does not exist, or whose owner cannot be
    resolved is uniformly a 404.

    Refused with 403 when the owning ecosystem has not enabled visitor chat, 503 when visitor chat is
    switched off globally, and 429 past the per-IP hourly mint limit.

    Args:
        slug (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | VisitorToken
    """

    return sync_detailed(
        slug=slug,
        client=client,
    ).parsed


async def asyncio_detailed(
    slug: str,
    *,
    client: AuthenticatedClient | Client,
) -> Response[Error | VisitorToken]:
    """Mint an anonymous visitor token for a public persona

     Unauthenticated, and the only way to obtain a visitor token. The token is returned once and never
    again — nothing server-side can reproduce it.

    Slugs are unique per owner, not globally, so a slug shared by two *public* personas is a 409 rather
    than an arbitrary pick. A persona that is not public, does not exist, or whose owner cannot be
    resolved is uniformly a 404.

    Refused with 403 when the owning ecosystem has not enabled visitor chat, 503 when visitor chat is
    switched off globally, and 429 past the per-IP hourly mint limit.

    Args:
        slug (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | VisitorToken]
    """

    kwargs = _get_kwargs(
        slug=slug,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    slug: str,
    *,
    client: AuthenticatedClient | Client,
) -> Error | VisitorToken | None:
    """Mint an anonymous visitor token for a public persona

     Unauthenticated, and the only way to obtain a visitor token. The token is returned once and never
    again — nothing server-side can reproduce it.

    Slugs are unique per owner, not globally, so a slug shared by two *public* personas is a 409 rather
    than an arbitrary pick. A persona that is not public, does not exist, or whose owner cannot be
    resolved is uniformly a 404.

    Refused with 403 when the owning ecosystem has not enabled visitor chat, 503 when visitor chat is
    switched off globally, and 429 past the per-IP hourly mint limit.

    Args:
        slug (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | VisitorToken
    """

    return (
        await asyncio_detailed(
            slug=slug,
            client=client,
        )
    ).parsed
