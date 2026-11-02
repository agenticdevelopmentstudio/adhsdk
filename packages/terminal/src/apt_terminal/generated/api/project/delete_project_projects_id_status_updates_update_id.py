from http import HTTPStatus
from typing import Any, cast
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...types import Response


def _get_kwargs(
    id: str,
    update_id: str,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "delete",
        "url": "/project/projects/{id}/status-updates/{update_id}".format(
            id=quote(str(id), safe=""),
            update_id=quote(str(update_id), safe=""),
        ),
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Any | Error | None:
    if response.status_code == 204:
        response_204 = cast(Any, None)
        return response_204

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
) -> Response[Any | Error]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    id: str,
    update_id: str,
    *,
    client: AuthenticatedClient,
) -> Response[Any | Error]:
    """Retract a status update (+ a status_update.deleted activity)

     The author may always retract their own report; anyone holding the project’s projects sub-item D
    verb may remove someone else’s — a removal is not a forgery. Retracting the NEWEST report moves the
    project’s health back to whatever the previous live update said, or to null. That is the honest
    outcome of withdrawing a claim, and the reason health is derived rather than stored: a column would
    still be asserting this row’s health with nothing left to explain it.

    Args:
        id (str):
        update_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Any | Error]
    """

    kwargs = _get_kwargs(
        id=id,
        update_id=update_id,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    update_id: str,
    *,
    client: AuthenticatedClient,
) -> Any | Error | None:
    """Retract a status update (+ a status_update.deleted activity)

     The author may always retract their own report; anyone holding the project’s projects sub-item D
    verb may remove someone else’s — a removal is not a forgery. Retracting the NEWEST report moves the
    project’s health back to whatever the previous live update said, or to null. That is the honest
    outcome of withdrawing a claim, and the reason health is derived rather than stored: a column would
    still be asserting this row’s health with nothing left to explain it.

    Args:
        id (str):
        update_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Any | Error
    """

    return sync_detailed(
        id=id,
        update_id=update_id,
        client=client,
    ).parsed


async def asyncio_detailed(
    id: str,
    update_id: str,
    *,
    client: AuthenticatedClient,
) -> Response[Any | Error]:
    """Retract a status update (+ a status_update.deleted activity)

     The author may always retract their own report; anyone holding the project’s projects sub-item D
    verb may remove someone else’s — a removal is not a forgery. Retracting the NEWEST report moves the
    project’s health back to whatever the previous live update said, or to null. That is the honest
    outcome of withdrawing a claim, and the reason health is derived rather than stored: a column would
    still be asserting this row’s health with nothing left to explain it.

    Args:
        id (str):
        update_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Any | Error]
    """

    kwargs = _get_kwargs(
        id=id,
        update_id=update_id,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    update_id: str,
    *,
    client: AuthenticatedClient,
) -> Any | Error | None:
    """Retract a status update (+ a status_update.deleted activity)

     The author may always retract their own report; anyone holding the project’s projects sub-item D
    verb may remove someone else’s — a removal is not a forgery. Retracting the NEWEST report moves the
    project’s health back to whatever the previous live update said, or to null. That is the honest
    outcome of withdrawing a claim, and the reason health is derived rather than stored: a column would
    still be asserting this row’s health with nothing left to explain it.

    Args:
        id (str):
        update_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Any | Error
    """

    return (
        await asyncio_detailed(
            id=id,
            update_id=update_id,
            client=client,
        )
    ).parsed
