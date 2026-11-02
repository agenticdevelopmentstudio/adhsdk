from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.patch_project_projects_id_saved_views_view_id_body import (
    PatchProjectProjectsIdSavedViewsViewIdBody,
)
from ...models.project_saved_view import ProjectSavedView
from ...types import UNSET, Response, Unset


def _get_kwargs(
    id: str,
    view_id: str,
    *,
    body: PatchProjectProjectsIdSavedViewsViewIdBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "patch",
        "url": "/project/projects/{id}/saved-views/{view_id}".format(
            id=quote(str(id), safe=""),
            view_id=quote(str(view_id), safe=""),
        ),
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | ProjectSavedView | None:
    if response.status_code == 200:
        response_200 = ProjectSavedView.from_dict(response.json())

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

    if response.status_code == 409:
        response_409 = Error.from_dict(response.json())

        return response_409

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | ProjectSavedView]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    id: str,
    view_id: str,
    *,
    client: AuthenticatedClient,
    body: PatchProjectProjectsIdSavedViewsViewIdBody | Unset = UNSET,
) -> Response[Error | ProjectSavedView]:
    """Rename a saved view / re-point it at the current filter (+ a saved_view.updated activity)

    Args:
        id (str):
        view_id (str):
        body (PatchProjectProjectsIdSavedViewsViewIdBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | ProjectSavedView]
    """

    kwargs = _get_kwargs(
        id=id,
        view_id=view_id,
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    view_id: str,
    *,
    client: AuthenticatedClient,
    body: PatchProjectProjectsIdSavedViewsViewIdBody | Unset = UNSET,
) -> Error | ProjectSavedView | None:
    """Rename a saved view / re-point it at the current filter (+ a saved_view.updated activity)

    Args:
        id (str):
        view_id (str):
        body (PatchProjectProjectsIdSavedViewsViewIdBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | ProjectSavedView
    """

    return sync_detailed(
        id=id,
        view_id=view_id,
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    id: str,
    view_id: str,
    *,
    client: AuthenticatedClient,
    body: PatchProjectProjectsIdSavedViewsViewIdBody | Unset = UNSET,
) -> Response[Error | ProjectSavedView]:
    """Rename a saved view / re-point it at the current filter (+ a saved_view.updated activity)

    Args:
        id (str):
        view_id (str):
        body (PatchProjectProjectsIdSavedViewsViewIdBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | ProjectSavedView]
    """

    kwargs = _get_kwargs(
        id=id,
        view_id=view_id,
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    view_id: str,
    *,
    client: AuthenticatedClient,
    body: PatchProjectProjectsIdSavedViewsViewIdBody | Unset = UNSET,
) -> Error | ProjectSavedView | None:
    """Rename a saved view / re-point it at the current filter (+ a saved_view.updated activity)

    Args:
        id (str):
        view_id (str):
        body (PatchProjectProjectsIdSavedViewsViewIdBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | ProjectSavedView
    """

    return (
        await asyncio_detailed(
            id=id,
            view_id=view_id,
            client=client,
            body=body,
        )
    ).parsed
