from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.sync_enrollment_list import SyncEnrollmentList
from ...models.sync_enrollment_update import SyncEnrollmentUpdate
from ...types import UNSET, Response, Unset


def _get_kwargs(
    id: str,
    resource: str,
    *,
    body: SyncEnrollmentUpdate | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "put",
        "url": "/admin/sync/tables/{id}/{resource}".format(
            id=quote(str(id), safe=""),
            resource=quote(str(resource), safe=""),
        ),
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | SyncEnrollmentList | None:
    if response.status_code == 200:
        response_200 = SyncEnrollmentList.from_dict(response.json())

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
    body: SyncEnrollmentUpdate | Unset = UNSET,
) -> Response[Error | SyncEnrollmentList]:
    """Override whether one resource syncs for an ecosystem

     A resource that is not in the catalog is a 400 — overrides cannot invent resources.

    Args:
        id (str):
        resource (str):
        body (SyncEnrollmentUpdate | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | SyncEnrollmentList]
    """

    kwargs = _get_kwargs(
        id=id,
        resource=resource,
        body=body,
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
    body: SyncEnrollmentUpdate | Unset = UNSET,
) -> Error | SyncEnrollmentList | None:
    """Override whether one resource syncs for an ecosystem

     A resource that is not in the catalog is a 400 — overrides cannot invent resources.

    Args:
        id (str):
        resource (str):
        body (SyncEnrollmentUpdate | Unset):

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
        body=body,
    ).parsed


async def asyncio_detailed(
    id: str,
    resource: str,
    *,
    client: AuthenticatedClient,
    body: SyncEnrollmentUpdate | Unset = UNSET,
) -> Response[Error | SyncEnrollmentList]:
    """Override whether one resource syncs for an ecosystem

     A resource that is not in the catalog is a 400 — overrides cannot invent resources.

    Args:
        id (str):
        resource (str):
        body (SyncEnrollmentUpdate | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | SyncEnrollmentList]
    """

    kwargs = _get_kwargs(
        id=id,
        resource=resource,
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    resource: str,
    *,
    client: AuthenticatedClient,
    body: SyncEnrollmentUpdate | Unset = UNSET,
) -> Error | SyncEnrollmentList | None:
    """Override whether one resource syncs for an ecosystem

     A resource that is not in the catalog is a 400 — overrides cannot invent resources.

    Args:
        id (str):
        resource (str):
        body (SyncEnrollmentUpdate | Unset):

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
            body=body,
        )
    ).parsed
