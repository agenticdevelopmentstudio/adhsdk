from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.project import Project
from ...types import Response


def _get_kwargs(
    id: str,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/project/programs/{id}/projects".format(
            id=quote(str(id), safe=""),
        ),
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | list[Project] | None:
    if response.status_code == 200:
        response_200 = []
        _response_200 = response.json()
        for response_200_item_data in _response_200:
            response_200_item = Project.from_dict(response_200_item_data)

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
) -> Response[Error | list[Project]]:
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
) -> Response[Error | list[Project]]:
    """The boards under one program, each with its derived health

     The roll-up the program exists to make answerable — and it is a LIST, not a verdict: a program
    spanning a green board and a red one is not "amber", and inventing that word here would hide the one
    board somebody needs to look at. UNLIKE the delete sweep this READS content, so it IS filtered by
    the caller’s project reach: a board this caller cannot open does not appear just because they can
    see its program.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | list[Project]]
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
) -> Error | list[Project] | None:
    """The boards under one program, each with its derived health

     The roll-up the program exists to make answerable — and it is a LIST, not a verdict: a program
    spanning a green board and a red one is not "amber", and inventing that word here would hide the one
    board somebody needs to look at. UNLIKE the delete sweep this READS content, so it IS filtered by
    the caller’s project reach: a board this caller cannot open does not appear just because they can
    see its program.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | list[Project]
    """

    return sync_detailed(
        id=id,
        client=client,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
) -> Response[Error | list[Project]]:
    """The boards under one program, each with its derived health

     The roll-up the program exists to make answerable — and it is a LIST, not a verdict: a program
    spanning a green board and a red one is not "amber", and inventing that word here would hide the one
    board somebody needs to look at. UNLIKE the delete sweep this READS content, so it IS filtered by
    the caller’s project reach: a board this caller cannot open does not appear just because they can
    see its program.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | list[Project]]
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
) -> Error | list[Project] | None:
    """The boards under one program, each with its derived health

     The roll-up the program exists to make answerable — and it is a LIST, not a verdict: a program
    spanning a green board and a red one is not "amber", and inventing that word here would hide the one
    board somebody needs to look at. UNLIKE the delete sweep this READS content, so it IS filtered by
    the caller’s project reach: a board this caller cannot open does not appear just because they can
    see its program.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | list[Project]
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
        )
    ).parsed
