from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.public_paper import PublicPaper
from ...types import Response


def _get_kwargs(
    slug: str,
    route: str,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/public/users/{slug}/papers/{route}".format(
            slug=quote(str(slug), safe=""),
            route=quote(str(route), safe=""),
        ),
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | PublicPaper | None:
    if response.status_code == 200:
        response_200 = PublicPaper.from_dict(response.json())

        return response_200

    if response.status_code == 404:
        response_404 = Error.from_dict(response.json())

        return response_404

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | PublicPaper]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    slug: str,
    route: str,
    *,
    client: AuthenticatedClient | Client,
) -> Response[Error | PublicPaper]:
    """Get a published paper by (author slug, route)

    Args:
        slug (str):
        route (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PublicPaper]
    """

    kwargs = _get_kwargs(
        slug=slug,
        route=route,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    slug: str,
    route: str,
    *,
    client: AuthenticatedClient | Client,
) -> Error | PublicPaper | None:
    """Get a published paper by (author slug, route)

    Args:
        slug (str):
        route (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PublicPaper
    """

    return sync_detailed(
        slug=slug,
        route=route,
        client=client,
    ).parsed


async def asyncio_detailed(
    slug: str,
    route: str,
    *,
    client: AuthenticatedClient | Client,
) -> Response[Error | PublicPaper]:
    """Get a published paper by (author slug, route)

    Args:
        slug (str):
        route (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PublicPaper]
    """

    kwargs = _get_kwargs(
        slug=slug,
        route=route,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    slug: str,
    route: str,
    *,
    client: AuthenticatedClient | Client,
) -> Error | PublicPaper | None:
    """Get a published paper by (author slug, route)

    Args:
        slug (str):
        route (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PublicPaper
    """

    return (
        await asyncio_detailed(
            slug=slug,
            route=route,
            client=client,
        )
    ).parsed
