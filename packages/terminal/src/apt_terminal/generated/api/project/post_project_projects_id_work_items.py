from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.post_project_projects_id_work_items_body import PostProjectProjectsIdWorkItemsBody
from ...models.post_project_projects_id_work_items_include_untriaged import (
    PostProjectProjectsIdWorkItemsIncludeUntriaged,
)
from ...models.work_item import WorkItem
from ...types import UNSET, Response, Unset


def _get_kwargs(
    id: str,
    *,
    body: PostProjectProjectsIdWorkItemsBody | Unset = UNSET,
    include_untriaged: PostProjectProjectsIdWorkItemsIncludeUntriaged | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    params: dict[str, Any] = {}

    json_include_untriaged: str | Unset = UNSET
    if not isinstance(include_untriaged, Unset):
        json_include_untriaged = include_untriaged.value

    params["includeUntriaged"] = json_include_untriaged

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/project/projects/{id}/work-items".format(
            id=quote(str(id), safe=""),
        ),
        "params": params,
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | WorkItem | None:
    if response.status_code == 201:
        response_201 = WorkItem.from_dict(response.json())

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

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | WorkItem]:
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
    body: PostProjectProjectsIdWorkItemsBody | Unset = UNSET,
    include_untriaged: PostProjectProjectsIdWorkItemsIncludeUntriaged | Unset = UNSET,
) -> Response[Error | WorkItem]:
    """Create a work item (refs validated in-project; + a work_item.created activity)

    Args:
        id (str):
        include_untriaged (PostProjectProjectsIdWorkItemsIncludeUntriaged | Unset):
        body (PostProjectProjectsIdWorkItemsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | WorkItem]
    """

    kwargs = _get_kwargs(
        id=id,
        body=body,
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
    body: PostProjectProjectsIdWorkItemsBody | Unset = UNSET,
    include_untriaged: PostProjectProjectsIdWorkItemsIncludeUntriaged | Unset = UNSET,
) -> Error | WorkItem | None:
    """Create a work item (refs validated in-project; + a work_item.created activity)

    Args:
        id (str):
        include_untriaged (PostProjectProjectsIdWorkItemsIncludeUntriaged | Unset):
        body (PostProjectProjectsIdWorkItemsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | WorkItem
    """

    return sync_detailed(
        id=id,
        client=client,
        body=body,
        include_untriaged=include_untriaged,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
    body: PostProjectProjectsIdWorkItemsBody | Unset = UNSET,
    include_untriaged: PostProjectProjectsIdWorkItemsIncludeUntriaged | Unset = UNSET,
) -> Response[Error | WorkItem]:
    """Create a work item (refs validated in-project; + a work_item.created activity)

    Args:
        id (str):
        include_untriaged (PostProjectProjectsIdWorkItemsIncludeUntriaged | Unset):
        body (PostProjectProjectsIdWorkItemsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | WorkItem]
    """

    kwargs = _get_kwargs(
        id=id,
        body=body,
        include_untriaged=include_untriaged,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    *,
    client: AuthenticatedClient,
    body: PostProjectProjectsIdWorkItemsBody | Unset = UNSET,
    include_untriaged: PostProjectProjectsIdWorkItemsIncludeUntriaged | Unset = UNSET,
) -> Error | WorkItem | None:
    """Create a work item (refs validated in-project; + a work_item.created activity)

    Args:
        id (str):
        include_untriaged (PostProjectProjectsIdWorkItemsIncludeUntriaged | Unset):
        body (PostProjectProjectsIdWorkItemsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | WorkItem
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            body=body,
            include_untriaged=include_untriaged,
        )
    ).parsed
