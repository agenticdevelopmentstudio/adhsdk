from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.get_v1_papers_response_200 import GetV1PapersResponse200
from ...models.get_v1_papers_visibility import GetV1PapersVisibility
from ...models.stripe_error import StripeError
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    route: str | Unset = UNSET,
    excluding: str | Unset = UNSET,
    author: str | Unset = UNSET,
    q: str | Unset = UNSET,
    category: str | Unset = UNSET,
    tag: str | Unset = UNSET,
    source: str | Unset = UNSET,
    visibility: GetV1PapersVisibility | Unset = UNSET,
    noted: bool | Unset = UNSET,
    doc: bool | Unset = UNSET,
    limit: int | Unset = 10,
    starting_after: str | Unset = UNSET,
    ending_before: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["route"] = route

    params["excluding"] = excluding

    params["author"] = author

    params["q"] = q

    params["category"] = category

    params["tag"] = tag

    params["source"] = source

    json_visibility: str | Unset = UNSET
    if not isinstance(visibility, Unset):
        json_visibility = visibility.value

    params["visibility"] = json_visibility

    params["noted"] = noted

    params["doc"] = doc

    params["limit"] = limit

    params["starting_after"] = starting_after

    params["ending_before"] = ending_before

    json_expand: list[str] | Unset = UNSET
    if not isinstance(expand, Unset):
        json_expand = expand

    params["expand[]"] = json_expand

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/v1/papers",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> GetV1PapersResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = GetV1PapersResponse200.from_dict(response.json())

        return response_200

    if response.status_code == 400:
        response_400 = StripeError.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = StripeError.from_dict(response.json())

        return response_401

    if response.status_code == 404:
        response_404 = StripeError.from_dict(response.json())

        return response_404

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[GetV1PapersResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    route: str | Unset = UNSET,
    excluding: str | Unset = UNSET,
    author: str | Unset = UNSET,
    q: str | Unset = UNSET,
    category: str | Unset = UNSET,
    tag: str | Unset = UNSET,
    source: str | Unset = UNSET,
    visibility: GetV1PapersVisibility | Unset = UNSET,
    noted: bool | Unset = UNSET,
    doc: bool | Unset = UNSET,
    limit: int | Unset = 10,
    starting_after: str | Unset = UNSET,
    ending_before: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1PapersResponse200 | StripeError]:
    """List/search the caller's markdown documents (metadata only)

     Lists the caller’s documents, most-recently-updated first. Optional filters narrow the set: `q`
    (free-text, case-insensitive substring across title, body, category, and tags), `category` (exact
    match), and `tag` (set membership).

    Replaces GET /content/markdown, GET /public/papers, GET /content/markdown/{id}/route-
    available/{route}, GET /public/users/{slug}/papers, GET /public/users/{slug}/papers/{route}.

    Args:
        route (str | Unset):
        excluding (str | Unset):
        author (str | Unset):
        q (str | Unset):
        category (str | Unset):
        tag (str | Unset):
        source (str | Unset):
        visibility (GetV1PapersVisibility | Unset):
        noted (bool | Unset):
        doc (bool | Unset):
        limit (int | Unset):  Default: 10.
        starting_after (str | Unset):
        ending_before (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1PapersResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        route=route,
        excluding=excluding,
        author=author,
        q=q,
        category=category,
        tag=tag,
        source=source,
        visibility=visibility,
        noted=noted,
        doc=doc,
        limit=limit,
        starting_after=starting_after,
        ending_before=ending_before,
        expand=expand,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    route: str | Unset = UNSET,
    excluding: str | Unset = UNSET,
    author: str | Unset = UNSET,
    q: str | Unset = UNSET,
    category: str | Unset = UNSET,
    tag: str | Unset = UNSET,
    source: str | Unset = UNSET,
    visibility: GetV1PapersVisibility | Unset = UNSET,
    noted: bool | Unset = UNSET,
    doc: bool | Unset = UNSET,
    limit: int | Unset = 10,
    starting_after: str | Unset = UNSET,
    ending_before: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> GetV1PapersResponse200 | StripeError | None:
    """List/search the caller's markdown documents (metadata only)

     Lists the caller’s documents, most-recently-updated first. Optional filters narrow the set: `q`
    (free-text, case-insensitive substring across title, body, category, and tags), `category` (exact
    match), and `tag` (set membership).

    Replaces GET /content/markdown, GET /public/papers, GET /content/markdown/{id}/route-
    available/{route}, GET /public/users/{slug}/papers, GET /public/users/{slug}/papers/{route}.

    Args:
        route (str | Unset):
        excluding (str | Unset):
        author (str | Unset):
        q (str | Unset):
        category (str | Unset):
        tag (str | Unset):
        source (str | Unset):
        visibility (GetV1PapersVisibility | Unset):
        noted (bool | Unset):
        doc (bool | Unset):
        limit (int | Unset):  Default: 10.
        starting_after (str | Unset):
        ending_before (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1PapersResponse200 | StripeError
    """

    return sync_detailed(
        client=client,
        route=route,
        excluding=excluding,
        author=author,
        q=q,
        category=category,
        tag=tag,
        source=source,
        visibility=visibility,
        noted=noted,
        doc=doc,
        limit=limit,
        starting_after=starting_after,
        ending_before=ending_before,
        expand=expand,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    route: str | Unset = UNSET,
    excluding: str | Unset = UNSET,
    author: str | Unset = UNSET,
    q: str | Unset = UNSET,
    category: str | Unset = UNSET,
    tag: str | Unset = UNSET,
    source: str | Unset = UNSET,
    visibility: GetV1PapersVisibility | Unset = UNSET,
    noted: bool | Unset = UNSET,
    doc: bool | Unset = UNSET,
    limit: int | Unset = 10,
    starting_after: str | Unset = UNSET,
    ending_before: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1PapersResponse200 | StripeError]:
    """List/search the caller's markdown documents (metadata only)

     Lists the caller’s documents, most-recently-updated first. Optional filters narrow the set: `q`
    (free-text, case-insensitive substring across title, body, category, and tags), `category` (exact
    match), and `tag` (set membership).

    Replaces GET /content/markdown, GET /public/papers, GET /content/markdown/{id}/route-
    available/{route}, GET /public/users/{slug}/papers, GET /public/users/{slug}/papers/{route}.

    Args:
        route (str | Unset):
        excluding (str | Unset):
        author (str | Unset):
        q (str | Unset):
        category (str | Unset):
        tag (str | Unset):
        source (str | Unset):
        visibility (GetV1PapersVisibility | Unset):
        noted (bool | Unset):
        doc (bool | Unset):
        limit (int | Unset):  Default: 10.
        starting_after (str | Unset):
        ending_before (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1PapersResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        route=route,
        excluding=excluding,
        author=author,
        q=q,
        category=category,
        tag=tag,
        source=source,
        visibility=visibility,
        noted=noted,
        doc=doc,
        limit=limit,
        starting_after=starting_after,
        ending_before=ending_before,
        expand=expand,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    route: str | Unset = UNSET,
    excluding: str | Unset = UNSET,
    author: str | Unset = UNSET,
    q: str | Unset = UNSET,
    category: str | Unset = UNSET,
    tag: str | Unset = UNSET,
    source: str | Unset = UNSET,
    visibility: GetV1PapersVisibility | Unset = UNSET,
    noted: bool | Unset = UNSET,
    doc: bool | Unset = UNSET,
    limit: int | Unset = 10,
    starting_after: str | Unset = UNSET,
    ending_before: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> GetV1PapersResponse200 | StripeError | None:
    """List/search the caller's markdown documents (metadata only)

     Lists the caller’s documents, most-recently-updated first. Optional filters narrow the set: `q`
    (free-text, case-insensitive substring across title, body, category, and tags), `category` (exact
    match), and `tag` (set membership).

    Replaces GET /content/markdown, GET /public/papers, GET /content/markdown/{id}/route-
    available/{route}, GET /public/users/{slug}/papers, GET /public/users/{slug}/papers/{route}.

    Args:
        route (str | Unset):
        excluding (str | Unset):
        author (str | Unset):
        q (str | Unset):
        category (str | Unset):
        tag (str | Unset):
        source (str | Unset):
        visibility (GetV1PapersVisibility | Unset):
        noted (bool | Unset):
        doc (bool | Unset):
        limit (int | Unset):  Default: 10.
        starting_after (str | Unset):
        ending_before (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1PapersResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            client=client,
            route=route,
            excluding=excluding,
            author=author,
            q=q,
            category=category,
            tag=tag,
            source=source,
            visibility=visibility,
            noted=noted,
            doc=doc,
            limit=limit,
            starting_after=starting_after,
            ending_before=ending_before,
            expand=expand,
        )
    ).parsed
