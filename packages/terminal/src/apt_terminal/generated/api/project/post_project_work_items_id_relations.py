from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.post_project_work_items_id_relations_body import PostProjectWorkItemsIdRelationsBody
from ...models.post_project_work_items_id_relations_response_201 import (
    PostProjectWorkItemsIdRelationsResponse201,
)
from ...types import UNSET, Response, Unset


def _get_kwargs(
    id: str,
    *,
    body: PostProjectWorkItemsIdRelationsBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/project/work-items/{id}/relations".format(
            id=quote(str(id), safe=""),
        ),
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | PostProjectWorkItemsIdRelationsResponse201 | None:
    if response.status_code == 201:
        response_201 = PostProjectWorkItemsIdRelationsResponse201.from_dict(response.json())

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
) -> Response[Error | PostProjectWorkItemsIdRelationsResponse201]:
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
    body: PostProjectWorkItemsIdRelationsBody | Unset = UNSET,
) -> Response[Error | PostProjectWorkItemsIdRelationsResponse201]:
    """Link this work item to another (+ a dependency.added activity)

    Args:
        id (str):
        body (PostProjectWorkItemsIdRelationsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PostProjectWorkItemsIdRelationsResponse201]
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
    body: PostProjectWorkItemsIdRelationsBody | Unset = UNSET,
) -> Error | PostProjectWorkItemsIdRelationsResponse201 | None:
    """Link this work item to another (+ a dependency.added activity)

    Args:
        id (str):
        body (PostProjectWorkItemsIdRelationsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PostProjectWorkItemsIdRelationsResponse201
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
    body: PostProjectWorkItemsIdRelationsBody | Unset = UNSET,
) -> Response[Error | PostProjectWorkItemsIdRelationsResponse201]:
    """Link this work item to another (+ a dependency.added activity)

    Args:
        id (str):
        body (PostProjectWorkItemsIdRelationsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PostProjectWorkItemsIdRelationsResponse201]
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
    body: PostProjectWorkItemsIdRelationsBody | Unset = UNSET,
) -> Error | PostProjectWorkItemsIdRelationsResponse201 | None:
    """Link this work item to another (+ a dependency.added activity)

    Args:
        id (str):
        body (PostProjectWorkItemsIdRelationsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PostProjectWorkItemsIdRelationsResponse201
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            body=body,
        )
    ).parsed
