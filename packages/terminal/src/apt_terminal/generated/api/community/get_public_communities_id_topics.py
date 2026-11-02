from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.get_public_communities_id_topics_response_200 import (
    GetPublicCommunitiesIdTopicsResponse200,
)
from ...models.get_public_communities_id_topics_sort import GetPublicCommunitiesIdTopicsSort
from ...types import UNSET, Response, Unset


def _get_kwargs(
    id: str,
    *,
    category: str | Unset = UNSET,
    sort: GetPublicCommunitiesIdTopicsSort | Unset = UNSET,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["category"] = category

    json_sort: str | Unset = UNSET
    if not isinstance(sort, Unset):
        json_sort = sort.value

    params["sort"] = json_sort

    params["page"] = page

    params["pageSize"] = page_size

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/public/communities/{id}/topics".format(
            id=quote(str(id), safe=""),
        ),
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | GetPublicCommunitiesIdTopicsResponse200 | None:
    if response.status_code == 200:
        response_200 = GetPublicCommunitiesIdTopicsResponse200.from_dict(response.json())

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
) -> Response[Error | GetPublicCommunitiesIdTopicsResponse200]:
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
    category: str | Unset = UNSET,
    sort: GetPublicCommunitiesIdTopicsSort | Unset = UNSET,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
) -> Response[Error | GetPublicCommunitiesIdTopicsResponse200]:
    """List a PUBLIC hub community’s public topics (author id omitted)

    Args:
        id (str):
        category (str | Unset):
        sort (GetPublicCommunitiesIdTopicsSort | Unset):
        page (str | Unset):
        page_size (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GetPublicCommunitiesIdTopicsResponse200]
    """

    kwargs = _get_kwargs(
        id=id,
        category=category,
        sort=sort,
        page=page,
        page_size=page_size,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    *,
    client: AuthenticatedClient | Client,
    category: str | Unset = UNSET,
    sort: GetPublicCommunitiesIdTopicsSort | Unset = UNSET,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
) -> Error | GetPublicCommunitiesIdTopicsResponse200 | None:
    """List a PUBLIC hub community’s public topics (author id omitted)

    Args:
        id (str):
        category (str | Unset):
        sort (GetPublicCommunitiesIdTopicsSort | Unset):
        page (str | Unset):
        page_size (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GetPublicCommunitiesIdTopicsResponse200
    """

    return sync_detailed(
        id=id,
        client=client,
        category=category,
        sort=sort,
        page=page,
        page_size=page_size,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient | Client,
    category: str | Unset = UNSET,
    sort: GetPublicCommunitiesIdTopicsSort | Unset = UNSET,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
) -> Response[Error | GetPublicCommunitiesIdTopicsResponse200]:
    """List a PUBLIC hub community’s public topics (author id omitted)

    Args:
        id (str):
        category (str | Unset):
        sort (GetPublicCommunitiesIdTopicsSort | Unset):
        page (str | Unset):
        page_size (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GetPublicCommunitiesIdTopicsResponse200]
    """

    kwargs = _get_kwargs(
        id=id,
        category=category,
        sort=sort,
        page=page,
        page_size=page_size,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    *,
    client: AuthenticatedClient | Client,
    category: str | Unset = UNSET,
    sort: GetPublicCommunitiesIdTopicsSort | Unset = UNSET,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
) -> Error | GetPublicCommunitiesIdTopicsResponse200 | None:
    """List a PUBLIC hub community’s public topics (author id omitted)

    Args:
        id (str):
        category (str | Unset):
        sort (GetPublicCommunitiesIdTopicsSort | Unset):
        page (str | Unset):
        page_size (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GetPublicCommunitiesIdTopicsResponse200
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            category=category,
            sort=sort,
            page=page,
            page_size=page_size,
        )
    ).parsed
