from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.project_status_update import ProjectStatusUpdate
from ...types import Response


def _get_kwargs(
    id: str,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/project/projects/{id}/status-updates".format(
            id=quote(str(id), safe=""),
        ),
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | list[ProjectStatusUpdate] | None:
    if response.status_code == 200:
        response_200 = []
        _response_200 = response.json()
        for response_200_item_data in _response_200:
            response_200_item = ProjectStatusUpdate.from_dict(response_200_item_data)

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
) -> Response[Error | list[ProjectStatusUpdate]]:
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
) -> Response[Error | list[ProjectStatusUpdate]]:
    """A project's status reports, NEWEST FIRST (up to 100)

     The opposite order to a comment thread, and deliberately: a thread is read as a conversation from
    the start, whereas the only report anyone opens a project for is the current one. The tie-break on a
    same-instant pair is the same one the health derivation uses, so the row at the top of this list is
    always the row that decided `Project.health`.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | list[ProjectStatusUpdate]]
    """

    kwargs = _get_kwargs(
        id=id,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    *,
    client: AuthenticatedClient,
) -> Error | list[ProjectStatusUpdate] | None:
    """A project's status reports, NEWEST FIRST (up to 100)

     The opposite order to a comment thread, and deliberately: a thread is read as a conversation from
    the start, whereas the only report anyone opens a project for is the current one. The tie-break on a
    same-instant pair is the same one the health derivation uses, so the row at the top of this list is
    always the row that decided `Project.health`.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | list[ProjectStatusUpdate]
    """

    return sync_detailed(
        id=id,
        client=client,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
) -> Response[Error | list[ProjectStatusUpdate]]:
    """A project's status reports, NEWEST FIRST (up to 100)

     The opposite order to a comment thread, and deliberately: a thread is read as a conversation from
    the start, whereas the only report anyone opens a project for is the current one. The tie-break on a
    same-instant pair is the same one the health derivation uses, so the row at the top of this list is
    always the row that decided `Project.health`.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | list[ProjectStatusUpdate]]
    """

    kwargs = _get_kwargs(
        id=id,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    *,
    client: AuthenticatedClient,
) -> Error | list[ProjectStatusUpdate] | None:
    """A project's status reports, NEWEST FIRST (up to 100)

     The opposite order to a comment thread, and deliberately: a thread is read as a conversation from
    the start, whereas the only report anyone opens a project for is the current one. The tie-break on a
    same-instant pair is the same one the health derivation uses, so the row at the top of this list is
    always the row that decided `Project.health`.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | list[ProjectStatusUpdate]
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
        )
    ).parsed
