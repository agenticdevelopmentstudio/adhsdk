from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.get_v1_discussion_topics_search_response_200 import (
    GetV1DiscussionTopicsSearchResponse200,
)
from ...models.get_v1_discussion_topics_search_type import GetV1DiscussionTopicsSearchType
from ...models.stripe_error import StripeError
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    q: str,
    type_: GetV1DiscussionTopicsSearchType | Unset = UNSET,
    page: int | Unset = UNSET,
    page_size: int | Unset = 20,
    expand: list[str] | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["q"] = q

    json_type_: str | Unset = UNSET
    if not isinstance(type_, Unset):
        json_type_ = type_.value

    params["type"] = json_type_

    params["page"] = page

    params["page_size"] = page_size

    json_expand: list[str] | Unset = UNSET
    if not isinstance(expand, Unset):
        json_expand = expand

    params["expand[]"] = json_expand

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/v1/discussion/topics/search",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> GetV1DiscussionTopicsSearchResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = GetV1DiscussionTopicsSearchResponse200.from_dict(response.json())

        return response_200

    if response.status_code == 400:
        response_400 = StripeError.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = StripeError.from_dict(response.json())

        return response_401

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[GetV1DiscussionTopicsSearchResponse200 | StripeError]:
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
    type_: GetV1DiscussionTopicsSearchType | Unset = UNSET,
    page: int | Unset = UNSET,
    page_size: int | Unset = 20,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1DiscussionTopicsSearchResponse200 | StripeError]:
    """Search discussions — topics by title, posts by body (via content.markdown)

     Replaces GET /search/discussions.

    Args:
        q (str):
        type_ (GetV1DiscussionTopicsSearchType | Unset):
        page (int | Unset):
        page_size (int | Unset):  Default: 20.
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1DiscussionTopicsSearchResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        q=q,
        type_=type_,
        page=page,
        page_size=page_size,
        expand=expand,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    q: str,
    type_: GetV1DiscussionTopicsSearchType | Unset = UNSET,
    page: int | Unset = UNSET,
    page_size: int | Unset = 20,
    expand: list[str] | Unset = UNSET,
) -> GetV1DiscussionTopicsSearchResponse200 | StripeError | None:
    """Search discussions — topics by title, posts by body (via content.markdown)

     Replaces GET /search/discussions.

    Args:
        q (str):
        type_ (GetV1DiscussionTopicsSearchType | Unset):
        page (int | Unset):
        page_size (int | Unset):  Default: 20.
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1DiscussionTopicsSearchResponse200 | StripeError
    """

    return sync_detailed(
        client=client,
        q=q,
        type_=type_,
        page=page,
        page_size=page_size,
        expand=expand,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    q: str,
    type_: GetV1DiscussionTopicsSearchType | Unset = UNSET,
    page: int | Unset = UNSET,
    page_size: int | Unset = 20,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1DiscussionTopicsSearchResponse200 | StripeError]:
    """Search discussions — topics by title, posts by body (via content.markdown)

     Replaces GET /search/discussions.

    Args:
        q (str):
        type_ (GetV1DiscussionTopicsSearchType | Unset):
        page (int | Unset):
        page_size (int | Unset):  Default: 20.
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1DiscussionTopicsSearchResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        q=q,
        type_=type_,
        page=page,
        page_size=page_size,
        expand=expand,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    q: str,
    type_: GetV1DiscussionTopicsSearchType | Unset = UNSET,
    page: int | Unset = UNSET,
    page_size: int | Unset = 20,
    expand: list[str] | Unset = UNSET,
) -> GetV1DiscussionTopicsSearchResponse200 | StripeError | None:
    """Search discussions — topics by title, posts by body (via content.markdown)

     Replaces GET /search/discussions.

    Args:
        q (str):
        type_ (GetV1DiscussionTopicsSearchType | Unset):
        page (int | Unset):
        page_size (int | Unset):  Default: 20.
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1DiscussionTopicsSearchResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            client=client,
            q=q,
            type_=type_,
            page=page,
            page_size=page_size,
            expand=expand,
        )
    ).parsed
