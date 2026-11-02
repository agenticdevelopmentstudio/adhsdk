from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.get_search_documents_response_200 import GetSearchDocumentsResponse200
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    q: str,
    limit: int | Unset = 20,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["q"] = q

    params["limit"] = limit

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/search/documents",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | GetSearchDocumentsResponse200 | None:
    if response.status_code == 200:
        response_200 = GetSearchDocumentsResponse200.from_dict(response.json())

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
) -> Response[Error | GetSearchDocumentsResponse200]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    q: str,
    limit: int | Unset = 20,
) -> Response[Error | GetSearchDocumentsResponse200]:
    """Full-text search the caller's document blocks

    Args:
        q (str):
        limit (int | Unset):  Default: 20.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GetSearchDocumentsResponse200]
    """

    kwargs = _get_kwargs(
        q=q,
        limit=limit,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    q: str,
    limit: int | Unset = 20,
) -> Error | GetSearchDocumentsResponse200 | None:
    """Full-text search the caller's document blocks

    Args:
        q (str):
        limit (int | Unset):  Default: 20.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GetSearchDocumentsResponse200
    """

    return sync_detailed(
        client=client,
        q=q,
        limit=limit,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    q: str,
    limit: int | Unset = 20,
) -> Response[Error | GetSearchDocumentsResponse200]:
    """Full-text search the caller's document blocks

    Args:
        q (str):
        limit (int | Unset):  Default: 20.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GetSearchDocumentsResponse200]
    """

    kwargs = _get_kwargs(
        q=q,
        limit=limit,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    q: str,
    limit: int | Unset = 20,
) -> Error | GetSearchDocumentsResponse200 | None:
    """Full-text search the caller's document blocks

    Args:
        q (str):
        limit (int | Unset):  Default: 20.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GetSearchDocumentsResponse200
    """

    return (
        await asyncio_detailed(
            client=client,
            q=q,
            limit=limit,
        )
    ).parsed
