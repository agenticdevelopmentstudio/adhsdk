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
    field_id: str,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "delete",
        "url": "/registry/registries/{id}/field-defs/{field_id}".format(
            id=quote(str(id), safe=""),
            field_id=quote(str(field_id), safe=""),
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
    field_id: str,
    *,
    client: AuthenticatedClient,
) -> Response[Any | Error]:
    """Soft-delete a field def (its values stay in entries.values, untouched)

     Cascades to the rules that name it: every live field def in this registry whose `showIf.field`
    equals the deleted field's key has its `showIf` cleared, in the same transaction. A rule naming a
    field that no longer exists never fires, so without this the dependent fields would silently
    disappear from the form. Clients should NOT patch those rules themselves afterwards — the work is
    already done, and doing it per dependent reindexes the whole registry once per PATCH.

    Args:
        id (str):
        field_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Any | Error]
    """

    kwargs = _get_kwargs(
        id=id,
        field_id=field_id,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    field_id: str,
    *,
    client: AuthenticatedClient,
) -> Any | Error | None:
    """Soft-delete a field def (its values stay in entries.values, untouched)

     Cascades to the rules that name it: every live field def in this registry whose `showIf.field`
    equals the deleted field's key has its `showIf` cleared, in the same transaction. A rule naming a
    field that no longer exists never fires, so without this the dependent fields would silently
    disappear from the form. Clients should NOT patch those rules themselves afterwards — the work is
    already done, and doing it per dependent reindexes the whole registry once per PATCH.

    Args:
        id (str):
        field_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Any | Error
    """

    return sync_detailed(
        id=id,
        field_id=field_id,
        client=client,
    ).parsed


async def asyncio_detailed(
    id: str,
    field_id: str,
    *,
    client: AuthenticatedClient,
) -> Response[Any | Error]:
    """Soft-delete a field def (its values stay in entries.values, untouched)

     Cascades to the rules that name it: every live field def in this registry whose `showIf.field`
    equals the deleted field's key has its `showIf` cleared, in the same transaction. A rule naming a
    field that no longer exists never fires, so without this the dependent fields would silently
    disappear from the form. Clients should NOT patch those rules themselves afterwards — the work is
    already done, and doing it per dependent reindexes the whole registry once per PATCH.

    Args:
        id (str):
        field_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Any | Error]
    """

    kwargs = _get_kwargs(
        id=id,
        field_id=field_id,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    field_id: str,
    *,
    client: AuthenticatedClient,
) -> Any | Error | None:
    """Soft-delete a field def (its values stay in entries.values, untouched)

     Cascades to the rules that name it: every live field def in this registry whose `showIf.field`
    equals the deleted field's key has its `showIf` cleared, in the same transaction. A rule naming a
    field that no longer exists never fires, so without this the dependent fields would silently
    disappear from the form. Clients should NOT patch those rules themselves afterwards — the work is
    already done, and doing it per dependent reindexes the whole registry once per PATCH.

    Args:
        id (str):
        field_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Any | Error
    """

    return (
        await asyncio_detailed(
            id=id,
            field_id=field_id,
            client=client,
        )
    ).parsed
