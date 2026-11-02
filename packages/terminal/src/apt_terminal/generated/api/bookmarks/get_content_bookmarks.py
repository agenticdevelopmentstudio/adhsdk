from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.get_content_bookmarks_response_200 import GetContentBookmarksResponse200
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
    target_kind: str | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["page"] = page

    params["pageSize"] = page_size

    params["targetKind"] = target_kind

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/content/bookmarks",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | GetContentBookmarksResponse200 | None:
    if response.status_code == 200:
        response_200 = GetContentBookmarksResponse200.from_dict(response.json())

        return response_200

    if response.status_code == 401:
        response_401 = Error.from_dict(response.json())

        return response_401

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | GetContentBookmarksResponse200]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
    target_kind: str | Unset = UNSET,
) -> Response[Error | GetContentBookmarksResponse200]:
    """List the caller's bookmarks (newest first, paginated)

    Args:
        page (str | Unset):
        page_size (str | Unset):
        target_kind (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GetContentBookmarksResponse200]
    """

    kwargs = _get_kwargs(
        page=page,
        page_size=page_size,
        target_kind=target_kind,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
    target_kind: str | Unset = UNSET,
) -> Error | GetContentBookmarksResponse200 | None:
    """List the caller's bookmarks (newest first, paginated)

    Args:
        page (str | Unset):
        page_size (str | Unset):
        target_kind (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GetContentBookmarksResponse200
    """

    return sync_detailed(
        client=client,
        page=page,
        page_size=page_size,
        target_kind=target_kind,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
    target_kind: str | Unset = UNSET,
) -> Response[Error | GetContentBookmarksResponse200]:
    """List the caller's bookmarks (newest first, paginated)

    Args:
        page (str | Unset):
        page_size (str | Unset):
        target_kind (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GetContentBookmarksResponse200]
    """

    kwargs = _get_kwargs(
        page=page,
        page_size=page_size,
        target_kind=target_kind,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
    target_kind: str | Unset = UNSET,
) -> Error | GetContentBookmarksResponse200 | None:
    """List the caller's bookmarks (newest first, paginated)

    Args:
        page (str | Unset):
        page_size (str | Unset):
        target_kind (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GetContentBookmarksResponse200
    """

    return (
        await asyncio_detailed(
            client=client,
            page=page,
            page_size=page_size,
            target_kind=target_kind,
        )
    ).parsed
