from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.markdown_category_tree import MarkdownCategoryTree
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    workspace: str | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["workspace"] = workspace

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/content/markdown/categories",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | MarkdownCategoryTree | None:
    if response.status_code == 200:
        response_200 = MarkdownCategoryTree.from_dict(response.json())

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
) -> Response[Error | MarkdownCategoryTree]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    workspace: str | Unset = UNSET,
) -> Response[Error | MarkdownCategoryTree]:
    """List the caller's existing categories (names + the category HIERARCHY)

     The account's full set of categories (content.categories), scoped to the workspace owner and
    ecosystem. `items` is the distinct, alphabetical NAME list — the autocomplete/browse source for the
    research classification UI. `nodes` is the same set with its structure kept (id + parentIds), which
    is what a hierarchical browser folds. The hierarchy is a DAG, not a tree: a category may sit under
    any number of parents, or none.

    Args:
        workspace (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | MarkdownCategoryTree]
    """

    kwargs = _get_kwargs(
        workspace=workspace,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    workspace: str | Unset = UNSET,
) -> Error | MarkdownCategoryTree | None:
    """List the caller's existing categories (names + the category HIERARCHY)

     The account's full set of categories (content.categories), scoped to the workspace owner and
    ecosystem. `items` is the distinct, alphabetical NAME list — the autocomplete/browse source for the
    research classification UI. `nodes` is the same set with its structure kept (id + parentIds), which
    is what a hierarchical browser folds. The hierarchy is a DAG, not a tree: a category may sit under
    any number of parents, or none.

    Args:
        workspace (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | MarkdownCategoryTree
    """

    return sync_detailed(
        client=client,
        workspace=workspace,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    workspace: str | Unset = UNSET,
) -> Response[Error | MarkdownCategoryTree]:
    """List the caller's existing categories (names + the category HIERARCHY)

     The account's full set of categories (content.categories), scoped to the workspace owner and
    ecosystem. `items` is the distinct, alphabetical NAME list — the autocomplete/browse source for the
    research classification UI. `nodes` is the same set with its structure kept (id + parentIds), which
    is what a hierarchical browser folds. The hierarchy is a DAG, not a tree: a category may sit under
    any number of parents, or none.

    Args:
        workspace (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | MarkdownCategoryTree]
    """

    kwargs = _get_kwargs(
        workspace=workspace,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    workspace: str | Unset = UNSET,
) -> Error | MarkdownCategoryTree | None:
    """List the caller's existing categories (names + the category HIERARCHY)

     The account's full set of categories (content.categories), scoped to the workspace owner and
    ecosystem. `items` is the distinct, alphabetical NAME list — the autocomplete/browse source for the
    research classification UI. `nodes` is the same set with its structure kept (id + parentIds), which
    is what a hierarchical browser folds. The hierarchy is a DAG, not a tree: a category may sit under
    any number of parents, or none.

    Args:
        workspace (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | MarkdownCategoryTree
    """

    return (
        await asyncio_detailed(
            client=client,
            workspace=workspace,
        )
    ).parsed
