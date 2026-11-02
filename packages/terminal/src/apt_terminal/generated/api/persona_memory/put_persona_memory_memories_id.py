from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.put_persona_memory_memories_id_body import PutPersonaMemoryMemoriesIdBody
from ...models.put_persona_memory_memories_id_response_200 import (
    PutPersonaMemoryMemoriesIdResponse200,
)
from ...types import UNSET, Response, Unset


def _get_kwargs(
    id: str,
    *,
    body: PutPersonaMemoryMemoriesIdBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "put",
        "url": "/persona-memory/memories/{id}".format(
            id=quote(str(id), safe=""),
        ),
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | PutPersonaMemoryMemoriesIdResponse200 | None:
    if response.status_code == 200:
        response_200 = PutPersonaMemoryMemoriesIdResponse200.from_dict(response.json())

        return response_200

    if response.status_code == 400:
        response_400 = Error.from_dict(response.json())

        return response_400

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
) -> Response[Error | PutPersonaMemoryMemoriesIdResponse200]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
    body: PutPersonaMemoryMemoriesIdBody | Unset = UNSET,
) -> Response[Error | PutPersonaMemoryMemoriesIdResponse200]:
    """Update memories

    Args:
        id (str):
        body (PutPersonaMemoryMemoriesIdBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PutPersonaMemoryMemoriesIdResponse200]
    """

    kwargs = _get_kwargs(
        id=id,
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    *,
    client: AuthenticatedClient,
    body: PutPersonaMemoryMemoriesIdBody | Unset = UNSET,
) -> Error | PutPersonaMemoryMemoriesIdResponse200 | None:
    """Update memories

    Args:
        id (str):
        body (PutPersonaMemoryMemoriesIdBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PutPersonaMemoryMemoriesIdResponse200
    """

    return sync_detailed(
        id=id,
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
    body: PutPersonaMemoryMemoriesIdBody | Unset = UNSET,
) -> Response[Error | PutPersonaMemoryMemoriesIdResponse200]:
    """Update memories

    Args:
        id (str):
        body (PutPersonaMemoryMemoriesIdBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PutPersonaMemoryMemoriesIdResponse200]
    """

    kwargs = _get_kwargs(
        id=id,
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    *,
    client: AuthenticatedClient,
    body: PutPersonaMemoryMemoriesIdBody | Unset = UNSET,
) -> Error | PutPersonaMemoryMemoriesIdResponse200 | None:
    """Update memories

    Args:
        id (str):
        body (PutPersonaMemoryMemoriesIdBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PutPersonaMemoryMemoriesIdResponse200
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            body=body,
        )
    ).parsed
