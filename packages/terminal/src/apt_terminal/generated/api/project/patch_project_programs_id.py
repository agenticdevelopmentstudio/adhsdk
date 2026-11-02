from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.patch_project_programs_id_body import PatchProjectProgramsIdBody
from ...models.project_program import ProjectProgram
from ...types import UNSET, Response, Unset


def _get_kwargs(
    id: str,
    *,
    body: PatchProjectProgramsIdBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "patch",
        "url": "/project/programs/{id}".format(
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
) -> Error | ProjectProgram | None:
    if response.status_code == 200:
        response_200 = ProjectProgram.from_dict(response.json())

        return response_200

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

    if response.status_code == 409:
        response_409 = Error.from_dict(response.json())

        return response_409

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | ProjectProgram]:
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
    body: PatchProjectProgramsIdBody | Unset = UNSET,
) -> Response[Error | ProjectProgram]:
    """Rename a program, recolour it, or move either of its dates

     Requires the workspace’s projects U verb.

    Args:
        id (str):
        body (PatchProjectProgramsIdBody | Unset): Every key is optional and a patch that changes
            nothing returns the program unchanged. Either date may be sent as null to CLEAR it; the
            pair is checked as it WILL BE.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | ProjectProgram]
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
    body: PatchProjectProgramsIdBody | Unset = UNSET,
) -> Error | ProjectProgram | None:
    """Rename a program, recolour it, or move either of its dates

     Requires the workspace’s projects U verb.

    Args:
        id (str):
        body (PatchProjectProgramsIdBody | Unset): Every key is optional and a patch that changes
            nothing returns the program unchanged. Either date may be sent as null to CLEAR it; the
            pair is checked as it WILL BE.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | ProjectProgram
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
    body: PatchProjectProgramsIdBody | Unset = UNSET,
) -> Response[Error | ProjectProgram]:
    """Rename a program, recolour it, or move either of its dates

     Requires the workspace’s projects U verb.

    Args:
        id (str):
        body (PatchProjectProgramsIdBody | Unset): Every key is optional and a patch that changes
            nothing returns the program unchanged. Either date may be sent as null to CLEAR it; the
            pair is checked as it WILL BE.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | ProjectProgram]
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
    body: PatchProjectProgramsIdBody | Unset = UNSET,
) -> Error | ProjectProgram | None:
    """Rename a program, recolour it, or move either of its dates

     Requires the workspace’s projects U verb.

    Args:
        id (str):
        body (PatchProjectProgramsIdBody | Unset): Every key is optional and a patch that changes
            nothing returns the program unchanged. Either date may be sent as null to CLEAR it; the
            pair is checked as it WILL BE.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | ProjectProgram
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            body=body,
        )
    ).parsed
