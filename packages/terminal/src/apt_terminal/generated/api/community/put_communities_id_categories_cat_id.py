from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.community_category import CommunityCategory
from ...models.error import Error
from ...models.put_communities_id_categories_cat_id_body import PutCommunitiesIdCategoriesCatIdBody
from ...types import UNSET, Response, Unset


def _get_kwargs(
    id: str,
    cat_id: str,
    *,
    body: PutCommunitiesIdCategoriesCatIdBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "put",
        "url": "/communities/{id}/categories/{cat_id}".format(
            id=quote(str(id), safe=""),
            cat_id=quote(str(cat_id), safe=""),
        ),
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> CommunityCategory | Error | None:
    if response.status_code == 200:
        response_200 = CommunityCategory.from_dict(response.json())

        return response_200

    if response.status_code == 400:
        response_400 = Error.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = Error.from_dict(response.json())

        return response_401

    if response.status_code == 403:
        response_403 = Error.from_dict(response.json())

        return response_403

    if response.status_code == 404:
        response_404 = Error.from_dict(response.json())

        return response_404

    if response.status_code == 409:
        response_409 = Error.from_dict(response.json())

        return response_409

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[CommunityCategory | Error]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    id: str,
    cat_id: str,
    *,
    client: AuthenticatedClient,
    body: PutCommunitiesIdCategoriesCatIdBody | Unset = UNSET,
) -> Response[CommunityCategory | Error]:
    """Edit a category (community admin only)

    Args:
        id (str):
        cat_id (str):
        body (PutCommunitiesIdCategoriesCatIdBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[CommunityCategory | Error]
    """

    kwargs = _get_kwargs(
        id=id,
        cat_id=cat_id,
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    cat_id: str,
    *,
    client: AuthenticatedClient,
    body: PutCommunitiesIdCategoriesCatIdBody | Unset = UNSET,
) -> CommunityCategory | Error | None:
    """Edit a category (community admin only)

    Args:
        id (str):
        cat_id (str):
        body (PutCommunitiesIdCategoriesCatIdBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        CommunityCategory | Error
    """

    return sync_detailed(
        id=id,
        cat_id=cat_id,
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    id: str,
    cat_id: str,
    *,
    client: AuthenticatedClient,
    body: PutCommunitiesIdCategoriesCatIdBody | Unset = UNSET,
) -> Response[CommunityCategory | Error]:
    """Edit a category (community admin only)

    Args:
        id (str):
        cat_id (str):
        body (PutCommunitiesIdCategoriesCatIdBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[CommunityCategory | Error]
    """

    kwargs = _get_kwargs(
        id=id,
        cat_id=cat_id,
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    cat_id: str,
    *,
    client: AuthenticatedClient,
    body: PutCommunitiesIdCategoriesCatIdBody | Unset = UNSET,
) -> CommunityCategory | Error | None:
    """Edit a category (community admin only)

    Args:
        id (str):
        cat_id (str):
        body (PutCommunitiesIdCategoriesCatIdBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        CommunityCategory | Error
    """

    return (
        await asyncio_detailed(
            id=id,
            cat_id=cat_id,
            client=client,
            body=body,
        )
    ).parsed
