from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.post_v1_communities_by_id_categories_by_category_id_body import (
    PostV1CommunitiesByIdCategoriesByCategoryIdBody,
)
from ...models.post_v1_communities_by_id_categories_by_category_id_response_200 import (
    PostV1CommunitiesByIdCategoriesByCategoryIdResponse200,
)
from ...models.stripe_error import StripeError
from ...types import Response


def _get_kwargs(
    id: str,
    category_id: str,
    *,
    body: PostV1CommunitiesByIdCategoriesByCategoryIdBody,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/communities/{id}/categories/{category_id}".format(
            id=quote(str(id), safe=""),
            category_id=quote(str(category_id), safe=""),
        ),
    }

    _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostV1CommunitiesByIdCategoriesByCategoryIdResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = PostV1CommunitiesByIdCategoriesByCategoryIdResponse200.from_dict(
            response.json()
        )

        return response_200

    if response.status_code == 400:
        response_400 = StripeError.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = StripeError.from_dict(response.json())

        return response_401

    if response.status_code == 403:
        response_403 = StripeError.from_dict(response.json())

        return response_403

    if response.status_code == 404:
        response_404 = StripeError.from_dict(response.json())

        return response_404

    if response.status_code == 409:
        response_409 = StripeError.from_dict(response.json())

        return response_409

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[PostV1CommunitiesByIdCategoriesByCategoryIdResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    id: str,
    category_id: str,
    *,
    client: AuthenticatedClient,
    body: PostV1CommunitiesByIdCategoriesByCategoryIdBody,
) -> Response[PostV1CommunitiesByIdCategoriesByCategoryIdResponse200 | StripeError]:
    """Edit a category (community admin only)

     Replaces PUT /communities/{id}/categories/{catId}.

    Args:
        id (str):
        category_id (str):
        body (PostV1CommunitiesByIdCategoriesByCategoryIdBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1CommunitiesByIdCategoriesByCategoryIdResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
        category_id=category_id,
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    category_id: str,
    *,
    client: AuthenticatedClient,
    body: PostV1CommunitiesByIdCategoriesByCategoryIdBody,
) -> PostV1CommunitiesByIdCategoriesByCategoryIdResponse200 | StripeError | None:
    """Edit a category (community admin only)

     Replaces PUT /communities/{id}/categories/{catId}.

    Args:
        id (str):
        category_id (str):
        body (PostV1CommunitiesByIdCategoriesByCategoryIdBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1CommunitiesByIdCategoriesByCategoryIdResponse200 | StripeError
    """

    return sync_detailed(
        id=id,
        category_id=category_id,
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    id: str,
    category_id: str,
    *,
    client: AuthenticatedClient,
    body: PostV1CommunitiesByIdCategoriesByCategoryIdBody,
) -> Response[PostV1CommunitiesByIdCategoriesByCategoryIdResponse200 | StripeError]:
    """Edit a category (community admin only)

     Replaces PUT /communities/{id}/categories/{catId}.

    Args:
        id (str):
        category_id (str):
        body (PostV1CommunitiesByIdCategoriesByCategoryIdBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1CommunitiesByIdCategoriesByCategoryIdResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
        category_id=category_id,
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    category_id: str,
    *,
    client: AuthenticatedClient,
    body: PostV1CommunitiesByIdCategoriesByCategoryIdBody,
) -> PostV1CommunitiesByIdCategoriesByCategoryIdResponse200 | StripeError | None:
    """Edit a category (community admin only)

     Replaces PUT /communities/{id}/categories/{catId}.

    Args:
        id (str):
        category_id (str):
        body (PostV1CommunitiesByIdCategoriesByCategoryIdBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1CommunitiesByIdCategoriesByCategoryIdResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            id=id,
            category_id=category_id,
            client=client,
            body=body,
        )
    ).parsed
