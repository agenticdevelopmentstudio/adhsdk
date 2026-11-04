from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.markdown_category_node import MarkdownCategoryNode
from ...models.post_content_markdown_categories_body import PostContentMarkdownCategoriesBody
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    body: PostContentMarkdownCategoriesBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
    ecosystem_id: str | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    params: dict[str, Any] = {}

    params["workspace"] = workspace

    params["ecosystemId"] = ecosystem_id

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/content/markdown/categories",
        "params": params,
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | MarkdownCategoryNode | None:
    if response.status_code == 200:
        response_200 = MarkdownCategoryNode.from_dict(response.json())

        return response_200

    if response.status_code == 201:
        response_201 = MarkdownCategoryNode.from_dict(response.json())

        return response_201

    if response.status_code == 400:
        response_400 = Error.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = Error.from_dict(response.json())

        return response_401

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
) -> Response[Error | MarkdownCategoryNode]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    body: PostContentMarkdownCategoriesBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
    ecosystem_id: str | Unset = UNSET,
) -> Response[Error | MarkdownCategoryNode]:
    """Create a category, optionally nested under one or more others

     Mints a category for the workspace owner. Omit `parentIds` (or send an empty array) for an unfiled
    category. A category NAME is unique per owner across the whole hierarchy — every other op addresses
    a category by name — so re-posting an existing name is idempotent ONLY when every parent it asks for
    is already one of that category's parents; asking for a new one is a 409. This never RE-FILES a
    category: adding a parent to an existing one is an edge write on /content/category-edges. Any id in
    `parentIds` that isn't one of this owner's live categories is a 404.

    Args:
        workspace (str | Unset):
        ecosystem_id (str | Unset):
        body (PostContentMarkdownCategoriesBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | MarkdownCategoryNode]
    """

    kwargs = _get_kwargs(
        body=body,
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
    body: PostContentMarkdownCategoriesBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
    ecosystem_id: str | Unset = UNSET,
) -> Error | MarkdownCategoryNode | None:
    """Create a category, optionally nested under one or more others

     Mints a category for the workspace owner. Omit `parentIds` (or send an empty array) for an unfiled
    category. A category NAME is unique per owner across the whole hierarchy — every other op addresses
    a category by name — so re-posting an existing name is idempotent ONLY when every parent it asks for
    is already one of that category's parents; asking for a new one is a 409. This never RE-FILES a
    category: adding a parent to an existing one is an edge write on /content/category-edges. Any id in
    `parentIds` that isn't one of this owner's live categories is a 404.

    Args:
        workspace (str | Unset):
        ecosystem_id (str | Unset):
        body (PostContentMarkdownCategoriesBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | MarkdownCategoryNode
    """

    return sync_detailed(
        client=client,
        body=body,
        workspace=workspace,
        ecosystem_id=ecosystem_id,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    body: PostContentMarkdownCategoriesBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
    ecosystem_id: str | Unset = UNSET,
) -> Response[Error | MarkdownCategoryNode]:
    """Create a category, optionally nested under one or more others

     Mints a category for the workspace owner. Omit `parentIds` (or send an empty array) for an unfiled
    category. A category NAME is unique per owner across the whole hierarchy — every other op addresses
    a category by name — so re-posting an existing name is idempotent ONLY when every parent it asks for
    is already one of that category's parents; asking for a new one is a 409. This never RE-FILES a
    category: adding a parent to an existing one is an edge write on /content/category-edges. Any id in
    `parentIds` that isn't one of this owner's live categories is a 404.

    Args:
        workspace (str | Unset):
        ecosystem_id (str | Unset):
        body (PostContentMarkdownCategoriesBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | MarkdownCategoryNode]
    """

    kwargs = _get_kwargs(
        body=body,
        workspace=workspace,
        ecosystem_id=ecosystem_id,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    body: PostContentMarkdownCategoriesBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
    ecosystem_id: str | Unset = UNSET,
) -> Error | MarkdownCategoryNode | None:
    """Create a category, optionally nested under one or more others

     Mints a category for the workspace owner. Omit `parentIds` (or send an empty array) for an unfiled
    category. A category NAME is unique per owner across the whole hierarchy — every other op addresses
    a category by name — so re-posting an existing name is idempotent ONLY when every parent it asks for
    is already one of that category's parents; asking for a new one is a 409. This never RE-FILES a
    category: adding a parent to an existing one is an edge write on /content/category-edges. Any id in
    `parentIds` that isn't one of this owner's live categories is a 404.

    Args:
        workspace (str | Unset):
        ecosystem_id (str | Unset):
        body (PostContentMarkdownCategoriesBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | MarkdownCategoryNode
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
            workspace=workspace,
            ecosystem_id=ecosystem_id,
        )
    ).parsed
