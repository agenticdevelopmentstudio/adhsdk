from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.get_project_projects_id_work_items_include_untriaged import (
    GetProjectProjectsIdWorkItemsIncludeUntriaged,
)
from ...models.work_item import WorkItem
from ...types import UNSET, Response, Unset


def _get_kwargs(
    id: str,
    *,
    include_untriaged: GetProjectProjectsIdWorkItemsIncludeUntriaged | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    json_include_untriaged: str | Unset = UNSET
    if not isinstance(include_untriaged, Unset):
        json_include_untriaged = include_untriaged.value

    params["includeUntriaged"] = json_include_untriaged

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/project/projects/{id}/work-items".format(
            id=quote(str(id), safe=""),
        ),
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | list[WorkItem] | None:
    if response.status_code == 200:
        response_200 = []
        _response_200 = response.json()
        for response_200_item_data in _response_200:
            response_200_item = WorkItem.from_dict(response_200_item_data)

            response_200.append(response_200_item)

        return response_200

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
) -> Response[Error | list[WorkItem]]:
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
    include_untriaged: GetProjectProjectsIdWorkItemsIncludeUntriaged | Unset = UNSET,
) -> Response[Error | list[WorkItem]]:
    """List a project's ACCEPTED work items (non-deleted, in board order)

     Cards awaiting triage are omitted unless `includeUntriaged=true`. On a board that has never used an
    intake queue this is every card, because a card created without `triage: true` is accepted at
    creation.

    Args:
        id (str):
        include_untriaged (GetProjectProjectsIdWorkItemsIncludeUntriaged | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | list[WorkItem]]
    """

    kwargs = _get_kwargs(
        id=id,
        include_untriaged=include_untriaged,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    *,
    client: AuthenticatedClient,
    include_untriaged: GetProjectProjectsIdWorkItemsIncludeUntriaged | Unset = UNSET,
) -> Error | list[WorkItem] | None:
    """List a project's ACCEPTED work items (non-deleted, in board order)

     Cards awaiting triage are omitted unless `includeUntriaged=true`. On a board that has never used an
    intake queue this is every card, because a card created without `triage: true` is accepted at
    creation.

    Args:
        id (str):
        include_untriaged (GetProjectProjectsIdWorkItemsIncludeUntriaged | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | list[WorkItem]
    """

    return sync_detailed(
        id=id,
        client=client,
        include_untriaged=include_untriaged,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
    include_untriaged: GetProjectProjectsIdWorkItemsIncludeUntriaged | Unset = UNSET,
) -> Response[Error | list[WorkItem]]:
    """List a project's ACCEPTED work items (non-deleted, in board order)

     Cards awaiting triage are omitted unless `includeUntriaged=true`. On a board that has never used an
    intake queue this is every card, because a card created without `triage: true` is accepted at
    creation.

    Args:
        id (str):
        include_untriaged (GetProjectProjectsIdWorkItemsIncludeUntriaged | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | list[WorkItem]]
    """

    kwargs = _get_kwargs(
        id=id,
        include_untriaged=include_untriaged,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    *,
    client: AuthenticatedClient,
    include_untriaged: GetProjectProjectsIdWorkItemsIncludeUntriaged | Unset = UNSET,
) -> Error | list[WorkItem] | None:
    """List a project's ACCEPTED work items (non-deleted, in board order)

     Cards awaiting triage are omitted unless `includeUntriaged=true`. On a board that has never used an
    intake queue this is every card, because a card created without `triage: true` is accepted at
    creation.

    Args:
        id (str):
        include_untriaged (GetProjectProjectsIdWorkItemsIncludeUntriaged | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | list[WorkItem]
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            include_untriaged=include_untriaged,
        )
    ).parsed
