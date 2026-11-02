from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.get_project_projects_id_artifacts_direction import (
    GetProjectProjectsIdArtifactsDirection,
)
from ...models.get_project_projects_id_artifacts_response_200 import (
    GetProjectProjectsIdArtifactsResponse200,
)
from ...types import UNSET, Response, Unset


def _get_kwargs(
    id: str,
    *,
    direction: GetProjectProjectsIdArtifactsDirection | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    json_direction: str | Unset = UNSET
    if not isinstance(direction, Unset):
        json_direction = direction.value

    params["direction"] = json_direction

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/project/projects/{id}/artifacts".format(
            id=quote(str(id), safe=""),
        ),
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | GetProjectProjectsIdArtifactsResponse200 | None:
    if response.status_code == 200:
        response_200 = GetProjectProjectsIdArtifactsResponse200.from_dict(response.json())

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
) -> Response[Error | GetProjectProjectsIdArtifactsResponse200]:
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
    direction: GetProjectProjectsIdArtifactsDirection | Unset = UNSET,
) -> Response[Error | GetProjectProjectsIdArtifactsResponse200]:
    """List a project's artifacts (newest first), optionally filtered by direction

    Args:
        id (str):
        direction (GetProjectProjectsIdArtifactsDirection | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GetProjectProjectsIdArtifactsResponse200]
    """

    kwargs = _get_kwargs(
        id=id,
        direction=direction,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    *,
    client: AuthenticatedClient,
    direction: GetProjectProjectsIdArtifactsDirection | Unset = UNSET,
) -> Error | GetProjectProjectsIdArtifactsResponse200 | None:
    """List a project's artifacts (newest first), optionally filtered by direction

    Args:
        id (str):
        direction (GetProjectProjectsIdArtifactsDirection | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GetProjectProjectsIdArtifactsResponse200
    """

    return sync_detailed(
        id=id,
        client=client,
        direction=direction,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
    direction: GetProjectProjectsIdArtifactsDirection | Unset = UNSET,
) -> Response[Error | GetProjectProjectsIdArtifactsResponse200]:
    """List a project's artifacts (newest first), optionally filtered by direction

    Args:
        id (str):
        direction (GetProjectProjectsIdArtifactsDirection | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GetProjectProjectsIdArtifactsResponse200]
    """

    kwargs = _get_kwargs(
        id=id,
        direction=direction,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    *,
    client: AuthenticatedClient,
    direction: GetProjectProjectsIdArtifactsDirection | Unset = UNSET,
) -> Error | GetProjectProjectsIdArtifactsResponse200 | None:
    """List a project's artifacts (newest first), optionally filtered by direction

    Args:
        id (str):
        direction (GetProjectProjectsIdArtifactsDirection | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GetProjectProjectsIdArtifactsResponse200
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            direction=direction,
        )
    ).parsed
