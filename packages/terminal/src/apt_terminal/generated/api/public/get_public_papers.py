from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.get_public_papers_response_200 import GetPublicPapersResponse200
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    page: int | Unset = UNSET,
    page_size: int | Unset = 50,
    q: str | Unset = UNSET,
    tag: str | Unset = UNSET,
    category: str | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["page"] = page

    params["pageSize"] = page_size

    params["q"] = q

    params["tag"] = tag

    params["category"] = category

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/public/papers",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> GetPublicPapersResponse200 | None:
    if response.status_code == 200:
        response_200 = GetPublicPapersResponse200.from_dict(response.json())

        return response_200

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[GetPublicPapersResponse200]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient | Client,
    page: int | Unset = UNSET,
    page_size: int | Unset = 50,
    q: str | Unset = UNSET,
    tag: str | Unset = UNSET,
    category: str | Unset = UNSET,
) -> Response[GetPublicPapersResponse200]:
    """Search published papers across ALL authors (metadata + snippet)

     Cross-author search over PUBLISHED, non-deleted markdown. `q` is a case-insensitive substring
    matched across title, body, category name, and tag labels; `tag` and `category` are exact-match
    filters. Each hit carries author attribution, the public route, classification, and a ~200-char
    match-context snippet — never the full body.

    Args:
        page (int | Unset):
        page_size (int | Unset):  Default: 50.
        q (str | Unset):
        tag (str | Unset):
        category (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetPublicPapersResponse200]
    """

    kwargs = _get_kwargs(
        page=page,
        page_size=page_size,
        q=q,
        tag=tag,
        category=category,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient | Client,
    page: int | Unset = UNSET,
    page_size: int | Unset = 50,
    q: str | Unset = UNSET,
    tag: str | Unset = UNSET,
    category: str | Unset = UNSET,
) -> GetPublicPapersResponse200 | None:
    """Search published papers across ALL authors (metadata + snippet)

     Cross-author search over PUBLISHED, non-deleted markdown. `q` is a case-insensitive substring
    matched across title, body, category name, and tag labels; `tag` and `category` are exact-match
    filters. Each hit carries author attribution, the public route, classification, and a ~200-char
    match-context snippet — never the full body.

    Args:
        page (int | Unset):
        page_size (int | Unset):  Default: 50.
        q (str | Unset):
        tag (str | Unset):
        category (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetPublicPapersResponse200
    """

    return sync_detailed(
        client=client,
        page=page,
        page_size=page_size,
        q=q,
        tag=tag,
        category=category,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient | Client,
    page: int | Unset = UNSET,
    page_size: int | Unset = 50,
    q: str | Unset = UNSET,
    tag: str | Unset = UNSET,
    category: str | Unset = UNSET,
) -> Response[GetPublicPapersResponse200]:
    """Search published papers across ALL authors (metadata + snippet)

     Cross-author search over PUBLISHED, non-deleted markdown. `q` is a case-insensitive substring
    matched across title, body, category name, and tag labels; `tag` and `category` are exact-match
    filters. Each hit carries author attribution, the public route, classification, and a ~200-char
    match-context snippet — never the full body.

    Args:
        page (int | Unset):
        page_size (int | Unset):  Default: 50.
        q (str | Unset):
        tag (str | Unset):
        category (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetPublicPapersResponse200]
    """

    kwargs = _get_kwargs(
        page=page,
        page_size=page_size,
        q=q,
        tag=tag,
        category=category,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient | Client,
    page: int | Unset = UNSET,
    page_size: int | Unset = 50,
    q: str | Unset = UNSET,
    tag: str | Unset = UNSET,
    category: str | Unset = UNSET,
) -> GetPublicPapersResponse200 | None:
    """Search published papers across ALL authors (metadata + snippet)

     Cross-author search over PUBLISHED, non-deleted markdown. `q` is a case-insensitive substring
    matched across title, body, category name, and tag labels; `tag` and `category` are exact-match
    filters. Each hit carries author attribution, the public route, classification, and a ~200-char
    match-context snippet — never the full body.

    Args:
        page (int | Unset):
        page_size (int | Unset):  Default: 50.
        q (str | Unset):
        tag (str | Unset):
        category (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetPublicPapersResponse200
    """

    return (
        await asyncio_detailed(
            client=client,
            page=page,
            page_size=page_size,
            q=q,
            tag=tag,
            category=category,
        )
    ).parsed
