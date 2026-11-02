from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.post_project_templates_id_projects_body import PostProjectTemplatesIdProjectsBody
from ...models.post_project_templates_id_projects_response_201 import (
    PostProjectTemplatesIdProjectsResponse201,
)
from ...types import UNSET, Response, Unset


def _get_kwargs(
    id: str,
    *,
    body: PostProjectTemplatesIdProjectsBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    params: dict[str, Any] = {}

    params["workspace"] = workspace

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/project/templates/{id}/projects".format(
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
) -> Error | PostProjectTemplatesIdProjectsResponse201 | None:
    if response.status_code == 201:
        response_201 = PostProjectTemplatesIdProjectsResponse201.from_dict(response.json())

        return response_201

    if response.status_code == 400:
        response_400 = Error.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = Error.from_dict(response.json())

        return response_401

    if response.status_code == 403:
        response_403 = Error.from_dict(response.json())

        return response_403

    if response.status_code == 404:
        response_404 = Error.from_dict(response.json())

        return response_404

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | PostProjectTemplatesIdProjectsResponse201]:
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
    body: PostProjectTemplatesIdProjectsBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> Response[Error | PostProjectTemplatesIdProjectsResponse201]:
    """Build a board (columns, estimate scale, plan) from a project template

     The columns and estimate scale go THROUGH the one project writer, so the board is never observable
    holding columns it was not meant to have, and its milestones are inserted in the same transaction. A
    `project.instantiated` activity row names the template. 400 if the template’s kind is `work_item`.

    Args:
        id (str):
        workspace (str | Unset):
        body (PostProjectTemplatesIdProjectsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PostProjectTemplatesIdProjectsResponse201]
    """

    kwargs = _get_kwargs(
        id=id,
        body=body,
        workspace=workspace,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    *,
    client: AuthenticatedClient,
    body: PostProjectTemplatesIdProjectsBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> Error | PostProjectTemplatesIdProjectsResponse201 | None:
    """Build a board (columns, estimate scale, plan) from a project template

     The columns and estimate scale go THROUGH the one project writer, so the board is never observable
    holding columns it was not meant to have, and its milestones are inserted in the same transaction. A
    `project.instantiated` activity row names the template. 400 if the template’s kind is `work_item`.

    Args:
        id (str):
        workspace (str | Unset):
        body (PostProjectTemplatesIdProjectsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PostProjectTemplatesIdProjectsResponse201
    """

    return sync_detailed(
        id=id,
        client=client,
        body=body,
        workspace=workspace,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
    body: PostProjectTemplatesIdProjectsBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> Response[Error | PostProjectTemplatesIdProjectsResponse201]:
    """Build a board (columns, estimate scale, plan) from a project template

     The columns and estimate scale go THROUGH the one project writer, so the board is never observable
    holding columns it was not meant to have, and its milestones are inserted in the same transaction. A
    `project.instantiated` activity row names the template. 400 if the template’s kind is `work_item`.

    Args:
        id (str):
        workspace (str | Unset):
        body (PostProjectTemplatesIdProjectsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PostProjectTemplatesIdProjectsResponse201]
    """

    kwargs = _get_kwargs(
        id=id,
        body=body,
        workspace=workspace,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    *,
    client: AuthenticatedClient,
    body: PostProjectTemplatesIdProjectsBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> Error | PostProjectTemplatesIdProjectsResponse201 | None:
    """Build a board (columns, estimate scale, plan) from a project template

     The columns and estimate scale go THROUGH the one project writer, so the board is never observable
    holding columns it was not meant to have, and its milestones are inserted in the same transaction. A
    `project.instantiated` activity row names the template. 400 if the template’s kind is `work_item`.

    Args:
        id (str):
        workspace (str | Unset):
        body (PostProjectTemplatesIdProjectsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PostProjectTemplatesIdProjectsResponse201
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            body=body,
            workspace=workspace,
        )
    ).parsed
