from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.post_v1_personas_by_id_visitor_tokens_response_201 import (
    PostV1PersonasByIdVisitorTokensResponse201,
)
from ...models.stripe_error import StripeError
from ...types import Response


def _get_kwargs(
    id: str,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/personas/{id}/visitor_tokens".format(
            id=quote(str(id), safe=""),
        ),
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostV1PersonasByIdVisitorTokensResponse201 | StripeError | None:
    if response.status_code == 201:
        response_201 = PostV1PersonasByIdVisitorTokensResponse201.from_dict(response.json())

        return response_201

    if response.status_code == 403:
        response_403 = StripeError.from_dict(response.json())

        return response_403

    if response.status_code == 404:
        response_404 = StripeError.from_dict(response.json())

        return response_404

    if response.status_code == 409:
        response_409 = StripeError.from_dict(response.json())

        return response_409

    if response.status_code == 429:
        response_429 = StripeError.from_dict(response.json())

        return response_429

    if response.status_code == 503:
        response_503 = StripeError.from_dict(response.json())

        return response_503

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[PostV1PersonasByIdVisitorTokensResponse201 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    id: str,
    *,
    client: AuthenticatedClient | Client,
) -> Response[PostV1PersonasByIdVisitorTokensResponse201 | StripeError]:
    """Mint an anonymous visitor token for a public persona

     Unauthenticated, and the only way to obtain a visitor token. The token is returned once and never
    again — nothing server-side can reproduce it.

    Slugs are unique per owner, not globally, so a slug shared by two *public* personas is a 409 rather
    than an arbitrary pick. A persona that is not public, does not exist, or whose owner cannot be
    resolved is uniformly a 404.

    Refused with 403 when the owning ecosystem has not enabled visitor chat, 503 when visitor chat is
    switched off globally, and 429 past the per-IP hourly mint limit.

    Replaces POST /public/personas/{slug}/visitor-tokens.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1PersonasByIdVisitorTokensResponse201 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    *,
    client: AuthenticatedClient | Client,
) -> PostV1PersonasByIdVisitorTokensResponse201 | StripeError | None:
    """Mint an anonymous visitor token for a public persona

     Unauthenticated, and the only way to obtain a visitor token. The token is returned once and never
    again — nothing server-side can reproduce it.

    Slugs are unique per owner, not globally, so a slug shared by two *public* personas is a 409 rather
    than an arbitrary pick. A persona that is not public, does not exist, or whose owner cannot be
    resolved is uniformly a 404.

    Refused with 403 when the owning ecosystem has not enabled visitor chat, 503 when visitor chat is
    switched off globally, and 429 past the per-IP hourly mint limit.

    Replaces POST /public/personas/{slug}/visitor-tokens.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1PersonasByIdVisitorTokensResponse201 | StripeError
    """

    return sync_detailed(
        id=id,
        client=client,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient | Client,
) -> Response[PostV1PersonasByIdVisitorTokensResponse201 | StripeError]:
    """Mint an anonymous visitor token for a public persona

     Unauthenticated, and the only way to obtain a visitor token. The token is returned once and never
    again — nothing server-side can reproduce it.

    Slugs are unique per owner, not globally, so a slug shared by two *public* personas is a 409 rather
    than an arbitrary pick. A persona that is not public, does not exist, or whose owner cannot be
    resolved is uniformly a 404.

    Refused with 403 when the owning ecosystem has not enabled visitor chat, 503 when visitor chat is
    switched off globally, and 429 past the per-IP hourly mint limit.

    Replaces POST /public/personas/{slug}/visitor-tokens.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1PersonasByIdVisitorTokensResponse201 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    *,
    client: AuthenticatedClient | Client,
) -> PostV1PersonasByIdVisitorTokensResponse201 | StripeError | None:
    """Mint an anonymous visitor token for a public persona

     Unauthenticated, and the only way to obtain a visitor token. The token is returned once and never
    again — nothing server-side can reproduce it.

    Slugs are unique per owner, not globally, so a slug shared by two *public* personas is a 409 rather
    than an arbitrary pick. A persona that is not public, does not exist, or whose owner cannot be
    resolved is uniformly a 404.

    Refused with 403 when the owning ecosystem has not enabled visitor chat, 503 when visitor chat is
    switched off globally, and 429 past the per-IP hourly mint limit.

    Replaces POST /public/personas/{slug}/visitor-tokens.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1PersonasByIdVisitorTokensResponse201 | StripeError
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
        )
    ).parsed
