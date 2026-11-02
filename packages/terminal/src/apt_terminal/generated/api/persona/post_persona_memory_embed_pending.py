from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.persona_memory_embed_result import PersonaMemoryEmbedResult
from ...models.post_persona_memory_embed_pending_body import PostPersonaMemoryEmbedPendingBody
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    body: PostPersonaMemoryEmbedPendingBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/persona-memory/embed-pending",
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | PersonaMemoryEmbedResult | None:
    if response.status_code == 200:
        response_200 = PersonaMemoryEmbedResult.from_dict(response.json())

        return response_200

    if response.status_code == 400:
        response_400 = Error.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = Error.from_dict(response.json())

        return response_401

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | PersonaMemoryEmbedResult]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    body: PostPersonaMemoryEmbedPendingBody | Unset = UNSET,
) -> Response[Error | PersonaMemoryEmbedResult]:
    """Backfill embeddings for pending memories

    Args:
        body (PostPersonaMemoryEmbedPendingBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PersonaMemoryEmbedResult]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    body: PostPersonaMemoryEmbedPendingBody | Unset = UNSET,
) -> Error | PersonaMemoryEmbedResult | None:
    """Backfill embeddings for pending memories

    Args:
        body (PostPersonaMemoryEmbedPendingBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PersonaMemoryEmbedResult
    """

    return sync_detailed(
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    body: PostPersonaMemoryEmbedPendingBody | Unset = UNSET,
) -> Response[Error | PersonaMemoryEmbedResult]:
    """Backfill embeddings for pending memories

    Args:
        body (PostPersonaMemoryEmbedPendingBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PersonaMemoryEmbedResult]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    body: PostPersonaMemoryEmbedPendingBody | Unset = UNSET,
) -> Error | PersonaMemoryEmbedResult | None:
    """Backfill embeddings for pending memories

    Args:
        body (PostPersonaMemoryEmbedPendingBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PersonaMemoryEmbedResult
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
        )
    ).parsed
