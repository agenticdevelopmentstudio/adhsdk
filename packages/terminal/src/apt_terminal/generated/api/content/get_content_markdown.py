from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.get_content_markdown_response_200 import GetContentMarkdownResponse200
from ...models.get_content_markdown_visibility import GetContentMarkdownVisibility
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    page: int | Unset = UNSET,
    page_size: int | Unset = 50,
    q: str | Unset = UNSET,
    category: str | Unset = UNSET,
    tag: str | Unset = UNSET,
    source: str | Unset = UNSET,
    visibility: GetContentMarkdownVisibility | Unset = UNSET,
    noted: bool | Unset = UNSET,
    doc: bool | Unset = UNSET,
    workspace: str | Unset = UNSET,
    ecosystem_id: str | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["page"] = page

    params["pageSize"] = page_size

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

    params["workspace"] = workspace

    params["ecosystemId"] = ecosystem_id

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/content/markdown",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | GetContentMarkdownResponse200 | None:
    if response.status_code == 200:
        response_200 = GetContentMarkdownResponse200.from_dict(response.json())

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
) -> Response[Error | GetContentMarkdownResponse200]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    page: int | Unset = UNSET,
    page_size: int | Unset = 50,
    q: str | Unset = UNSET,
    category: str | Unset = UNSET,
    tag: str | Unset = UNSET,
    source: str | Unset = UNSET,
    visibility: GetContentMarkdownVisibility | Unset = UNSET,
    noted: bool | Unset = UNSET,
    doc: bool | Unset = UNSET,
    workspace: str | Unset = UNSET,
    ecosystem_id: str | Unset = UNSET,
) -> Response[Error | GetContentMarkdownResponse200]:
    """List/search the caller's markdown documents (metadata only)

     Lists the caller’s documents, most-recently-updated first. Optional filters narrow the set: `q`
    (free-text, case-insensitive substring across title, body, category, and tags), `category` (exact
    match), and `tag` (set membership).

    Args:
        page (int | Unset):
        page_size (int | Unset):  Default: 50.
        q (str | Unset):
        category (str | Unset):
        tag (str | Unset):
        source (str | Unset):
        visibility (GetContentMarkdownVisibility | Unset):
        noted (bool | Unset):
        doc (bool | Unset):
        workspace (str | Unset):
        ecosystem_id (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GetContentMarkdownResponse200]
    """

    kwargs = _get_kwargs(
        page=page,
        page_size=page_size,
        q=q,
        category=category,
        tag=tag,
        source=source,
        visibility=visibility,
        noted=noted,
        doc=doc,
        workspace=workspace,
        ecosystem_id=ecosystem_id,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    page: int | Unset = UNSET,
    page_size: int | Unset = 50,
    q: str | Unset = UNSET,
    category: str | Unset = UNSET,
    tag: str | Unset = UNSET,
    source: str | Unset = UNSET,
    visibility: GetContentMarkdownVisibility | Unset = UNSET,
    noted: bool | Unset = UNSET,
    doc: bool | Unset = UNSET,
    workspace: str | Unset = UNSET,
    ecosystem_id: str | Unset = UNSET,
) -> Error | GetContentMarkdownResponse200 | None:
    """List/search the caller's markdown documents (metadata only)

     Lists the caller’s documents, most-recently-updated first. Optional filters narrow the set: `q`
    (free-text, case-insensitive substring across title, body, category, and tags), `category` (exact
    match), and `tag` (set membership).

    Args:
        page (int | Unset):
        page_size (int | Unset):  Default: 50.
        q (str | Unset):
        category (str | Unset):
        tag (str | Unset):
        source (str | Unset):
        visibility (GetContentMarkdownVisibility | Unset):
        noted (bool | Unset):
        doc (bool | Unset):
        workspace (str | Unset):
        ecosystem_id (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GetContentMarkdownResponse200
    """

    return sync_detailed(
        client=client,
        page=page,
        page_size=page_size,
        q=q,
        category=category,
        tag=tag,
        source=source,
        visibility=visibility,
        noted=noted,
        doc=doc,
        workspace=workspace,
        ecosystem_id=ecosystem_id,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    page: int | Unset = UNSET,
    page_size: int | Unset = 50,
    q: str | Unset = UNSET,
    category: str | Unset = UNSET,
    tag: str | Unset = UNSET,
    source: str | Unset = UNSET,
    visibility: GetContentMarkdownVisibility | Unset = UNSET,
    noted: bool | Unset = UNSET,
    doc: bool | Unset = UNSET,
    workspace: str | Unset = UNSET,
    ecosystem_id: str | Unset = UNSET,
) -> Response[Error | GetContentMarkdownResponse200]:
    """List/search the caller's markdown documents (metadata only)

     Lists the caller’s documents, most-recently-updated first. Optional filters narrow the set: `q`
    (free-text, case-insensitive substring across title, body, category, and tags), `category` (exact
    match), and `tag` (set membership).

    Args:
        page (int | Unset):
        page_size (int | Unset):  Default: 50.
        q (str | Unset):
        category (str | Unset):
        tag (str | Unset):
        source (str | Unset):
        visibility (GetContentMarkdownVisibility | Unset):
        noted (bool | Unset):
        doc (bool | Unset):
        workspace (str | Unset):
        ecosystem_id (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GetContentMarkdownResponse200]
    """

    kwargs = _get_kwargs(
        page=page,
        page_size=page_size,
        q=q,
        category=category,
        tag=tag,
        source=source,
        visibility=visibility,
        noted=noted,
        doc=doc,
        workspace=workspace,
        ecosystem_id=ecosystem_id,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    page: int | Unset = UNSET,
    page_size: int | Unset = 50,
    q: str | Unset = UNSET,
    category: str | Unset = UNSET,
    tag: str | Unset = UNSET,
    source: str | Unset = UNSET,
    visibility: GetContentMarkdownVisibility | Unset = UNSET,
    noted: bool | Unset = UNSET,
    doc: bool | Unset = UNSET,
    workspace: str | Unset = UNSET,
    ecosystem_id: str | Unset = UNSET,
) -> Error | GetContentMarkdownResponse200 | None:
    """List/search the caller's markdown documents (metadata only)

     Lists the caller’s documents, most-recently-updated first. Optional filters narrow the set: `q`
    (free-text, case-insensitive substring across title, body, category, and tags), `category` (exact
    match), and `tag` (set membership).

    Args:
        page (int | Unset):
        page_size (int | Unset):  Default: 50.
        q (str | Unset):
        category (str | Unset):
        tag (str | Unset):
        source (str | Unset):
        visibility (GetContentMarkdownVisibility | Unset):
        noted (bool | Unset):
        doc (bool | Unset):
        workspace (str | Unset):
        ecosystem_id (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GetContentMarkdownResponse200
    """

    return (
        await asyncio_detailed(
            client=client,
            page=page,
            page_size=page_size,
            q=q,
            category=category,
            tag=tag,
            source=source,
            visibility=visibility,
            noted=noted,
            doc=doc,
            workspace=workspace,
            ecosystem_id=ecosystem_id,
        )
    ).parsed
