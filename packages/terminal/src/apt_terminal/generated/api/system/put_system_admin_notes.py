from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.admin_notes_reconcile_body import AdminNotesReconcileBody
from ...models.error import Error
from ...models.put_system_admin_notes_response_200 import PutSystemAdminNotesResponse200
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    body: AdminNotesReconcileBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "put",
        "url": "/system/admin-notes",
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | PutSystemAdminNotesResponse200 | None:
    if response.status_code == 200:
        response_200 = PutSystemAdminNotesResponse200.from_dict(response.json())

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

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | PutSystemAdminNotesResponse200]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    body: AdminNotesReconcileBody | Unset = UNSET,
) -> Response[Error | PutSystemAdminNotesResponse200]:
    """Reconcile a subject's admin notes

     Replaces the whole set for the subject rather than editing one note: a note with an `id` is updated,
    one without is created, and any existing note the body omits is DELETED. Sending an empty `notes`
    array clears them all. Appends one `notes_updated` entry to the subject's history.

    Args:
        body (AdminNotesReconcileBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PutSystemAdminNotesResponse200]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    body: AdminNotesReconcileBody | Unset = UNSET,
) -> Error | PutSystemAdminNotesResponse200 | None:
    """Reconcile a subject's admin notes

     Replaces the whole set for the subject rather than editing one note: a note with an `id` is updated,
    one without is created, and any existing note the body omits is DELETED. Sending an empty `notes`
    array clears them all. Appends one `notes_updated` entry to the subject's history.

    Args:
        body (AdminNotesReconcileBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PutSystemAdminNotesResponse200
    """

    return sync_detailed(
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    body: AdminNotesReconcileBody | Unset = UNSET,
) -> Response[Error | PutSystemAdminNotesResponse200]:
    """Reconcile a subject's admin notes

     Replaces the whole set for the subject rather than editing one note: a note with an `id` is updated,
    one without is created, and any existing note the body omits is DELETED. Sending an empty `notes`
    array clears them all. Appends one `notes_updated` entry to the subject's history.

    Args:
        body (AdminNotesReconcileBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PutSystemAdminNotesResponse200]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    body: AdminNotesReconcileBody | Unset = UNSET,
) -> Error | PutSystemAdminNotesResponse200 | None:
    """Reconcile a subject's admin notes

     Replaces the whole set for the subject rather than editing one note: a note with an `id` is updated,
    one without is created, and any existing note the body omits is DELETED. Sending an empty `notes`
    array clears them all. Appends one `notes_updated` entry to the subject's history.

    Args:
        body (AdminNotesReconcileBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PutSystemAdminNotesResponse200
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
        )
    ).parsed
