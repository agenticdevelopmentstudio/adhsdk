from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.post_v1_communities_by_id_members_body import PostV1CommunitiesByIdMembersBody
from ...models.post_v1_communities_by_id_members_response_201 import (
    PostV1CommunitiesByIdMembersResponse201,
)
from ...models.stripe_error import StripeError
from ...types import Response


def _get_kwargs(
    id: str,
    *,
    body: PostV1CommunitiesByIdMembersBody,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/communities/{id}/members".format(
            id=quote(str(id), safe=""),
        ),
    }

    _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostV1CommunitiesByIdMembersResponse201 | StripeError | None:
    if response.status_code == 201:
        response_201 = PostV1CommunitiesByIdMembersResponse201.from_dict(response.json())

        return response_201

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

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[PostV1CommunitiesByIdMembersResponse201 | StripeError]:
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
    body: PostV1CommunitiesByIdMembersBody,
) -> Response[PostV1CommunitiesByIdMembersResponse201 | StripeError]:
    """Grant a membership role (community admin only; idempotent upsert; the grantee must be a real
    customer → 404)

     Replaces POST /communities/{id}/members.

    Args:
        id (str):
        body (PostV1CommunitiesByIdMembersBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1CommunitiesByIdMembersResponse201 | StripeError]
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
    body: PostV1CommunitiesByIdMembersBody,
) -> PostV1CommunitiesByIdMembersResponse201 | StripeError | None:
    """Grant a membership role (community admin only; idempotent upsert; the grantee must be a real
    customer → 404)

     Replaces POST /communities/{id}/members.

    Args:
        id (str):
        body (PostV1CommunitiesByIdMembersBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1CommunitiesByIdMembersResponse201 | StripeError
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
    body: PostV1CommunitiesByIdMembersBody,
) -> Response[PostV1CommunitiesByIdMembersResponse201 | StripeError]:
    """Grant a membership role (community admin only; idempotent upsert; the grantee must be a real
    customer → 404)

     Replaces POST /communities/{id}/members.

    Args:
        id (str):
        body (PostV1CommunitiesByIdMembersBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1CommunitiesByIdMembersResponse201 | StripeError]
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
    body: PostV1CommunitiesByIdMembersBody,
) -> PostV1CommunitiesByIdMembersResponse201 | StripeError | None:
    """Grant a membership role (community admin only; idempotent upsert; the grantee must be a real
    customer → 404)

     Replaces POST /communities/{id}/members.

    Args:
        id (str):
        body (PostV1CommunitiesByIdMembersBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1CommunitiesByIdMembersResponse201 | StripeError
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            body=body,
        )
    ).parsed
