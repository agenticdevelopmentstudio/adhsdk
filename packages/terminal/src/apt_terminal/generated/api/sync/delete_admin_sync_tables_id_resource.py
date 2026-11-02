from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.sync_enrollment_list import SyncEnrollmentList
from ...types import Response


def _get_kwargs(
    id: str,
    resource: str,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "delete",
        "url": "/admin/sync/tables/{id}/{resource}".format(
            id=quote(str(id), safe=""),
            resource=quote(str(resource), safe=""),
        ),
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | SyncEnrollmentList | None:
    if response.status_code == 200:
        response_200 = SyncEnrollmentList.from_dict(response.json())

        return response_200

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
) -> Response[Error | SyncEnrollmentList]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    id: str,
    resource: str,
    *,
    client: AuthenticatedClient,
) -> Response[Error | SyncEnrollmentList]:
    """Drop the override and fall back to the catalog default

     Idempotent, and deliberately unvalidated: clearing an override that was never set — or one naming a
    resource the catalog has since dropped — succeeds rather than 400ing, so a stale override can always
    be cleaned up.

    Args:
        id (str):
        resource (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | SyncEnrollmentList]
    """

    kwargs = _get_kwargs(
        id=id,
        resource=resource,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    resource: str,
    *,
    client: AuthenticatedClient,
) -> Error | SyncEnrollmentList | None:
    """Drop the override and fall back to the catalog default

     Idempotent, and deliberately unvalidated: clearing an override that was never set — or one naming a
    resource the catalog has since dropped — succeeds rather than 400ing, so a stale override can always
    be cleaned up.

    Args:
        id (str):
        resource (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | SyncEnrollmentList
    """

    return sync_detailed(
        id=id,
        resource=resource,
        client=client,
    ).parsed


async def asyncio_detailed(
    id: str,
    resource: str,
    *,
    client: AuthenticatedClient,
) -> Response[Error | SyncEnrollmentList]:
    """Drop the override and fall back to the catalog default

     Idempotent, and deliberately unvalidated: clearing an override that was never set — or one naming a
    resource the catalog has since dropped — succeeds rather than 400ing, so a stale override can always
    be cleaned up.

    Args:
        id (str):
        resource (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | SyncEnrollmentList]
    """

    kwargs = _get_kwargs(
        id=id,
        resource=resource,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    resource: str,
    *,
    client: AuthenticatedClient,
) -> Error | SyncEnrollmentList | None:
    """Drop the override and fall back to the catalog default

     Idempotent, and deliberately unvalidated: clearing an override that was never set — or one naming a
    resource the catalog has since dropped — succeeds rather than 400ing, so a stale override can always
    be cleaned up.

    Args:
        id (str):
        resource (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | SyncEnrollmentList
    """

    return (
        await asyncio_detailed(
            id=id,
            resource=resource,
            client=client,
        )
    ).parsed
