from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.get_project_search_work_items_response_200 import (
    GetProjectSearchWorkItemsResponse200,
)
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    q: str,
    workspace: str | Unset = UNSET,
    limit: int | Unset = 20,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["q"] = q

    params["workspace"] = workspace

    params["limit"] = limit

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/project/search/work-items",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | GetProjectSearchWorkItemsResponse200 | None:
    if response.status_code == 200:
        response_200 = GetProjectSearchWorkItemsResponse200.from_dict(response.json())

        return response_200

    if response.status_code == 400:
        response_400 = Error.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = Error.from_dict(response.json())

        return response_401

    if response.status_code == 404:
        response_404 = Error.from_dict(response.json())

        return response_404

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | GetProjectSearchWorkItemsResponse200]:
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
    workspace: str | Unset = UNSET,
    limit: int | Unset = 20,
) -> Response[Error | GetProjectSearchWorkItemsResponse200]:
    """Search the caller's work items across every board they reach

     The cross-board read: given a phrase, the cards that match it anywhere in the caller’s reach,
    ranked. A query shaped like a rendered KEY (`ADH-42`) additionally matches that card by key and
    sorts it FIRST, because someone who typed a key named a row rather than described one. Reach is the
    same one the projects list uses (owned / owning-organization / participating), and it is what BOUNDS
    the query — a caller with no reach gets nothing, by construction rather than by filter. For text
    inside ONE board, filter the board’s own list client-side; this route exists for the question that
    list cannot be asked.

    Args:
        q (str):
        workspace (str | Unset):
        limit (int | Unset):  Default: 20.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GetProjectSearchWorkItemsResponse200]
    """

    kwargs = _get_kwargs(
        q=q,
        workspace=workspace,
        limit=limit,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    q: str,
    workspace: str | Unset = UNSET,
    limit: int | Unset = 20,
) -> Error | GetProjectSearchWorkItemsResponse200 | None:
    """Search the caller's work items across every board they reach

     The cross-board read: given a phrase, the cards that match it anywhere in the caller’s reach,
    ranked. A query shaped like a rendered KEY (`ADH-42`) additionally matches that card by key and
    sorts it FIRST, because someone who typed a key named a row rather than described one. Reach is the
    same one the projects list uses (owned / owning-organization / participating), and it is what BOUNDS
    the query — a caller with no reach gets nothing, by construction rather than by filter. For text
    inside ONE board, filter the board’s own list client-side; this route exists for the question that
    list cannot be asked.

    Args:
        q (str):
        workspace (str | Unset):
        limit (int | Unset):  Default: 20.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GetProjectSearchWorkItemsResponse200
    """

    return sync_detailed(
        client=client,
        q=q,
        workspace=workspace,
        limit=limit,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    q: str,
    workspace: str | Unset = UNSET,
    limit: int | Unset = 20,
) -> Response[Error | GetProjectSearchWorkItemsResponse200]:
    """Search the caller's work items across every board they reach

     The cross-board read: given a phrase, the cards that match it anywhere in the caller’s reach,
    ranked. A query shaped like a rendered KEY (`ADH-42`) additionally matches that card by key and
    sorts it FIRST, because someone who typed a key named a row rather than described one. Reach is the
    same one the projects list uses (owned / owning-organization / participating), and it is what BOUNDS
    the query — a caller with no reach gets nothing, by construction rather than by filter. For text
    inside ONE board, filter the board’s own list client-side; this route exists for the question that
    list cannot be asked.

    Args:
        q (str):
        workspace (str | Unset):
        limit (int | Unset):  Default: 20.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GetProjectSearchWorkItemsResponse200]
    """

    kwargs = _get_kwargs(
        q=q,
        workspace=workspace,
        limit=limit,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    q: str,
    workspace: str | Unset = UNSET,
    limit: int | Unset = 20,
) -> Error | GetProjectSearchWorkItemsResponse200 | None:
    """Search the caller's work items across every board they reach

     The cross-board read: given a phrase, the cards that match it anywhere in the caller’s reach,
    ranked. A query shaped like a rendered KEY (`ADH-42`) additionally matches that card by key and
    sorts it FIRST, because someone who typed a key named a row rather than described one. Reach is the
    same one the projects list uses (owned / owning-organization / participating), and it is what BOUNDS
    the query — a caller with no reach gets nothing, by construction rather than by filter. For text
    inside ONE board, filter the board’s own list client-side; this route exists for the question that
    list cannot be asked.

    Args:
        q (str):
        workspace (str | Unset):
        limit (int | Unset):  Default: 20.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GetProjectSearchWorkItemsResponse200
    """

    return (
        await asyncio_detailed(
            client=client,
            q=q,
            workspace=workspace,
            limit=limit,
        )
    ).parsed
