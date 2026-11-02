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
    kind: str,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "delete",
        "url": "/shipr/repos/{id}/platforms/{kind}".format(
            id=quote(str(id), safe=""),
            kind=quote(str(kind), safe=""),
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
    kind: str,
    *,
    client: AuthenticatedClient,
) -> Response[Any | Error]:
    """Detach the platform credential

     204 whether or not a row was there — a repository with no such credential has already reached the
    state the caller asked for. Soft, like everything else in this schema, so a run log that mentions
    the platform stays legible.

    Args:
        id (str):
        kind (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Any | Error]
    """

    kwargs = _get_kwargs(
        id=id,
        kind=kind,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    kind: str,
    *,
    client: AuthenticatedClient,
) -> Any | Error | None:
    """Detach the platform credential

     204 whether or not a row was there — a repository with no such credential has already reached the
    state the caller asked for. Soft, like everything else in this schema, so a run log that mentions
    the platform stays legible.

    Args:
        id (str):
        kind (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Any | Error
    """

    return sync_detailed(
        id=id,
        kind=kind,
        client=client,
    ).parsed


async def asyncio_detailed(
    id: str,
    kind: str,
    *,
    client: AuthenticatedClient,
) -> Response[Any | Error]:
    """Detach the platform credential

     204 whether or not a row was there — a repository with no such credential has already reached the
    state the caller asked for. Soft, like everything else in this schema, so a run log that mentions
    the platform stays legible.

    Args:
        id (str):
        kind (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Any | Error]
    """

    kwargs = _get_kwargs(
        id=id,
        kind=kind,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    kind: str,
    *,
    client: AuthenticatedClient,
) -> Any | Error | None:
    """Detach the platform credential

     204 whether or not a row was there — a repository with no such credential has already reached the
    state the caller asked for. Soft, like everything else in this schema, so a run log that mentions
    the platform stays legible.

    Args:
        id (str):
        kind (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Any | Error
    """

    return (
        await asyncio_detailed(
            id=id,
            kind=kind,
            client=client,
        )
    ).parsed
