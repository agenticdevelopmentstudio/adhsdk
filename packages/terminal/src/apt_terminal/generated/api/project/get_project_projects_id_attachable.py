from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.get_project_projects_id_attachable_kind import GetProjectProjectsIdAttachableKind
from ...models.get_project_projects_id_attachable_response_200 import (
    GetProjectProjectsIdAttachableResponse200,
)
from ...types import UNSET, Response, Unset


def _get_kwargs(
    id: str,
    *,
    kind: GetProjectProjectsIdAttachableKind | Unset = UNSET,
    q: str | Unset = UNSET,
    limit: int | Unset = 20,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    json_kind: str | Unset = UNSET
    if not isinstance(kind, Unset):
        json_kind = kind.value

    params["kind"] = json_kind

    params["q"] = q

    params["limit"] = limit

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/project/projects/{id}/attachable".format(
            id=quote(str(id), safe=""),
        ),
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | GetProjectProjectsIdAttachableResponse200 | None:
    if response.status_code == 200:
        response_200 = GetProjectProjectsIdAttachableResponse200.from_dict(response.json())

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
) -> Response[Error | GetProjectProjectsIdAttachableResponse200]:
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
    kind: GetProjectProjectsIdAttachableKind | Unset = UNSET,
    q: str | Unset = UNSET,
    limit: int | Unset = 20,
) -> Response[Error | GetProjectProjectsIdAttachableResponse200]:
    """Targets this project could attach — the candidate list an attach picker reads

     Everything the project OWNER can reach, of every registered target kind (or one, via `kind`), most
    recently touched first. Returned through the same owner scope the link write checks against, so
    every row here is one POST /artifacts will accept. Requires the project 'C' verb — the same gate as
    the attach itself, so this is not a read-only route for enumerating a workspace.

    Args:
        id (str):
        kind (GetProjectProjectsIdAttachableKind | Unset):
        q (str | Unset):
        limit (int | Unset):  Default: 20.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GetProjectProjectsIdAttachableResponse200]
    """

    kwargs = _get_kwargs(
        id=id,
        kind=kind,
        q=q,
        limit=limit,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    *,
    client: AuthenticatedClient,
    kind: GetProjectProjectsIdAttachableKind | Unset = UNSET,
    q: str | Unset = UNSET,
    limit: int | Unset = 20,
) -> Error | GetProjectProjectsIdAttachableResponse200 | None:
    """Targets this project could attach — the candidate list an attach picker reads

     Everything the project OWNER can reach, of every registered target kind (or one, via `kind`), most
    recently touched first. Returned through the same owner scope the link write checks against, so
    every row here is one POST /artifacts will accept. Requires the project 'C' verb — the same gate as
    the attach itself, so this is not a read-only route for enumerating a workspace.

    Args:
        id (str):
        kind (GetProjectProjectsIdAttachableKind | Unset):
        q (str | Unset):
        limit (int | Unset):  Default: 20.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GetProjectProjectsIdAttachableResponse200
    """

    return sync_detailed(
        id=id,
        client=client,
        kind=kind,
        q=q,
        limit=limit,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
    kind: GetProjectProjectsIdAttachableKind | Unset = UNSET,
    q: str | Unset = UNSET,
    limit: int | Unset = 20,
) -> Response[Error | GetProjectProjectsIdAttachableResponse200]:
    """Targets this project could attach — the candidate list an attach picker reads

     Everything the project OWNER can reach, of every registered target kind (or one, via `kind`), most
    recently touched first. Returned through the same owner scope the link write checks against, so
    every row here is one POST /artifacts will accept. Requires the project 'C' verb — the same gate as
    the attach itself, so this is not a read-only route for enumerating a workspace.

    Args:
        id (str):
        kind (GetProjectProjectsIdAttachableKind | Unset):
        q (str | Unset):
        limit (int | Unset):  Default: 20.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GetProjectProjectsIdAttachableResponse200]
    """

    kwargs = _get_kwargs(
        id=id,
        kind=kind,
        q=q,
        limit=limit,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    *,
    client: AuthenticatedClient,
    kind: GetProjectProjectsIdAttachableKind | Unset = UNSET,
    q: str | Unset = UNSET,
    limit: int | Unset = 20,
) -> Error | GetProjectProjectsIdAttachableResponse200 | None:
    """Targets this project could attach — the candidate list an attach picker reads

     Everything the project OWNER can reach, of every registered target kind (or one, via `kind`), most
    recently touched first. Returned through the same owner scope the link write checks against, so
    every row here is one POST /artifacts will accept. Requires the project 'C' verb — the same gate as
    the attach itself, so this is not a read-only route for enumerating a workspace.

    Args:
        id (str):
        kind (GetProjectProjectsIdAttachableKind | Unset):
        q (str | Unset):
        limit (int | Unset):  Default: 20.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GetProjectProjectsIdAttachableResponse200
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            kind=kind,
            q=q,
            limit=limit,
        )
    ).parsed
