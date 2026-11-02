from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.public_persona import PublicPersona
from ...types import Response


def _get_kwargs(
    owner_slug: str,
    persona_slug: str,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/orgs/{owner_slug}/personas/{persona_slug}".format(
            owner_slug=quote(str(owner_slug), safe=""),
            persona_slug=quote(str(persona_slug), safe=""),
        ),
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | PublicPersona | None:
    if response.status_code == 200:
        response_200 = PublicPersona.from_dict(response.json())

        return response_200

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
) -> Response[Error | PublicPersona]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    owner_slug: str,
    persona_slug: str,
    *,
    client: AuthenticatedClient,
) -> Response[Error | PublicPersona]:
    """Get a persona scoped to its owning organization as a signed-in viewer ('public' + 'hub')

    Args:
        owner_slug (str):
        persona_slug (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PublicPersona]
    """

    kwargs = _get_kwargs(
        owner_slug=owner_slug,
        persona_slug=persona_slug,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    owner_slug: str,
    persona_slug: str,
    *,
    client: AuthenticatedClient,
) -> Error | PublicPersona | None:
    """Get a persona scoped to its owning organization as a signed-in viewer ('public' + 'hub')

    Args:
        owner_slug (str):
        persona_slug (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PublicPersona
    """

    return sync_detailed(
        owner_slug=owner_slug,
        persona_slug=persona_slug,
        client=client,
    ).parsed


async def asyncio_detailed(
    owner_slug: str,
    persona_slug: str,
    *,
    client: AuthenticatedClient,
) -> Response[Error | PublicPersona]:
    """Get a persona scoped to its owning organization as a signed-in viewer ('public' + 'hub')

    Args:
        owner_slug (str):
        persona_slug (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PublicPersona]
    """

    kwargs = _get_kwargs(
        owner_slug=owner_slug,
        persona_slug=persona_slug,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    owner_slug: str,
    persona_slug: str,
    *,
    client: AuthenticatedClient,
) -> Error | PublicPersona | None:
    """Get a persona scoped to its owning organization as a signed-in viewer ('public' + 'hub')

    Args:
        owner_slug (str):
        persona_slug (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PublicPersona
    """

    return (
        await asyncio_detailed(
            owner_slug=owner_slug,
            persona_slug=persona_slug,
            client=client,
        )
    ).parsed
