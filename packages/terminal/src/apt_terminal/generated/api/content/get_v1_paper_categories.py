from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.get_v1_paper_categories_response_200 import GetV1PaperCategoriesResponse200
from ...models.stripe_error import StripeError
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    expand: list[str] | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    json_expand: list[str] | Unset = UNSET
    if not isinstance(expand, Unset):
        json_expand = expand

    params["expand[]"] = json_expand

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/v1/paper_categories",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> GetV1PaperCategoriesResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = GetV1PaperCategoriesResponse200.from_dict(response.json())

        return response_200

    if response.status_code == 401:
        response_401 = StripeError.from_dict(response.json())

        return response_401

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[GetV1PaperCategoriesResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1PaperCategoriesResponse200 | StripeError]:
    """List the caller's existing categories (names + the category HIERARCHY)

     The account's full set of categories (content.categories), scoped to the workspace owner and
    ecosystem. `items` is the distinct, alphabetical NAME list — the autocomplete/browse source for the
    research classification UI. `nodes` is the same set with its structure kept (id + parentIds), which
    is what a hierarchical browser folds. The hierarchy is a DAG, not a tree: a category may sit under
    any number of parents, or none.

    Replaces GET /content/markdown/categories, GET /public/papers/categories.

    Args:
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1PaperCategoriesResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        expand=expand,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    expand: list[str] | Unset = UNSET,
) -> GetV1PaperCategoriesResponse200 | StripeError | None:
    """List the caller's existing categories (names + the category HIERARCHY)

     The account's full set of categories (content.categories), scoped to the workspace owner and
    ecosystem. `items` is the distinct, alphabetical NAME list — the autocomplete/browse source for the
    research classification UI. `nodes` is the same set with its structure kept (id + parentIds), which
    is what a hierarchical browser folds. The hierarchy is a DAG, not a tree: a category may sit under
    any number of parents, or none.

    Replaces GET /content/markdown/categories, GET /public/papers/categories.

    Args:
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1PaperCategoriesResponse200 | StripeError
    """

    return sync_detailed(
        client=client,
        expand=expand,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1PaperCategoriesResponse200 | StripeError]:
    """List the caller's existing categories (names + the category HIERARCHY)

     The account's full set of categories (content.categories), scoped to the workspace owner and
    ecosystem. `items` is the distinct, alphabetical NAME list — the autocomplete/browse source for the
    research classification UI. `nodes` is the same set with its structure kept (id + parentIds), which
    is what a hierarchical browser folds. The hierarchy is a DAG, not a tree: a category may sit under
    any number of parents, or none.

    Replaces GET /content/markdown/categories, GET /public/papers/categories.

    Args:
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1PaperCategoriesResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        expand=expand,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    expand: list[str] | Unset = UNSET,
) -> GetV1PaperCategoriesResponse200 | StripeError | None:
    """List the caller's existing categories (names + the category HIERARCHY)

     The account's full set of categories (content.categories), scoped to the workspace owner and
    ecosystem. `items` is the distinct, alphabetical NAME list — the autocomplete/browse source for the
    research classification UI. `nodes` is the same set with its structure kept (id + parentIds), which
    is what a hierarchical browser folds. The hierarchy is a DAG, not a tree: a category may sit under
    any number of parents, or none.

    Replaces GET /content/markdown/categories, GET /public/papers/categories.

    Args:
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1PaperCategoriesResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            client=client,
            expand=expand,
        )
    ).parsed
