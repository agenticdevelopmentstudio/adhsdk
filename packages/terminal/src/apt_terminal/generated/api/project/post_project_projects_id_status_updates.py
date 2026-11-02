from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.post_project_projects_id_status_updates_body import (
    PostProjectProjectsIdStatusUpdatesBody,
)
from ...models.project_status_update import ProjectStatusUpdate
from ...types import UNSET, Response, Unset


def _get_kwargs(
    id: str,
    *,
    body: PostProjectProjectsIdStatusUpdatesBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/project/projects/{id}/status-updates".format(
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
) -> Error | ProjectStatusUpdate | None:
    if response.status_code == 201:
        response_201 = ProjectStatusUpdate.from_dict(response.json())

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
) -> Response[Error | ProjectStatusUpdate]:
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
    body: PostProjectProjectsIdStatusUpdatesBody | Unset = UNSET,
) -> Response[Error | ProjectStatusUpdate]:
    """Post a status update — this MOVES the project's health

     Requires the project’s projects sub-item C verb. The new report becomes the newest, so
    `Project.health` reads from it on the very next project fetch. The author is the acting principal (a
    persona’s report is the persona’s) and is never re-written afterwards.

    Args:
        id (str):
        body (PostProjectProjectsIdStatusUpdatesBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | ProjectStatusUpdate]
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
    body: PostProjectProjectsIdStatusUpdatesBody | Unset = UNSET,
) -> Error | ProjectStatusUpdate | None:
    """Post a status update — this MOVES the project's health

     Requires the project’s projects sub-item C verb. The new report becomes the newest, so
    `Project.health` reads from it on the very next project fetch. The author is the acting principal (a
    persona’s report is the persona’s) and is never re-written afterwards.

    Args:
        id (str):
        body (PostProjectProjectsIdStatusUpdatesBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | ProjectStatusUpdate
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
    body: PostProjectProjectsIdStatusUpdatesBody | Unset = UNSET,
) -> Response[Error | ProjectStatusUpdate]:
    """Post a status update — this MOVES the project's health

     Requires the project’s projects sub-item C verb. The new report becomes the newest, so
    `Project.health` reads from it on the very next project fetch. The author is the acting principal (a
    persona’s report is the persona’s) and is never re-written afterwards.

    Args:
        id (str):
        body (PostProjectProjectsIdStatusUpdatesBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | ProjectStatusUpdate]
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
    body: PostProjectProjectsIdStatusUpdatesBody | Unset = UNSET,
) -> Error | ProjectStatusUpdate | None:
    """Post a status update — this MOVES the project's health

     Requires the project’s projects sub-item C verb. The new report becomes the newest, so
    `Project.health` reads from it on the very next project fetch. The author is the acting principal (a
    persona’s report is the persona’s) and is never re-written afterwards.

    Args:
        id (str):
        body (PostProjectProjectsIdStatusUpdatesBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | ProjectStatusUpdate
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            body=body,
        )
    ).parsed
