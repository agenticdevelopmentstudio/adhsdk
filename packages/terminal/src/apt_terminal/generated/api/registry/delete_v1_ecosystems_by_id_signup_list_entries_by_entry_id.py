from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.deleted import Deleted
from ...models.stripe_error import StripeError
from ...types import Response


def _get_kwargs(
    id: str,
    entry_id: str,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "delete",
        "url": "/v1/ecosystems/{id}/signup_list_entries/{entry_id}".format(
            id=quote(str(id), safe=""),
            entry_id=quote(str(entry_id), safe=""),
        ),
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Deleted | StripeError | None:
    if response.status_code == 200:
        response_200 = Deleted.from_dict(response.json())

        return response_200

    if response.status_code == 401:
        response_401 = StripeError.from_dict(response.json())

        return response_401

    if response.status_code == 403:
        response_403 = StripeError.from_dict(response.json())

        return response_403

    if response.status_code == 404:
        response_404 = StripeError.from_dict(response.json())

        return response_404

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Deleted | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    id: str,
    entry_id: str,
    *,
    client: AuthenticatedClient,
) -> Response[Deleted | StripeError]:
    """Remove a sign-up list entry

     While the ecosystem limits sign-in to a list of emails, the email is removed from that list too. A
    role already granted stays granted. While the product's admin site is live and `consented_access` is
    on, a manager may remove only an entry granting the `admin` role; anything else is 403
    `managed_at_admin_site`.

    Replaces DELETE /ecosystem/signup-list/{id}/entries/{entryId}.

    Args:
        id (str):
        entry_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Deleted | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
        entry_id=entry_id,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    entry_id: str,
    *,
    client: AuthenticatedClient,
) -> Deleted | StripeError | None:
    """Remove a sign-up list entry

     While the ecosystem limits sign-in to a list of emails, the email is removed from that list too. A
    role already granted stays granted. While the product's admin site is live and `consented_access` is
    on, a manager may remove only an entry granting the `admin` role; anything else is 403
    `managed_at_admin_site`.

    Replaces DELETE /ecosystem/signup-list/{id}/entries/{entryId}.

    Args:
        id (str):
        entry_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Deleted | StripeError
    """

    return sync_detailed(
        id=id,
        entry_id=entry_id,
        client=client,
    ).parsed


async def asyncio_detailed(
    id: str,
    entry_id: str,
    *,
    client: AuthenticatedClient,
) -> Response[Deleted | StripeError]:
    """Remove a sign-up list entry

     While the ecosystem limits sign-in to a list of emails, the email is removed from that list too. A
    role already granted stays granted. While the product's admin site is live and `consented_access` is
    on, a manager may remove only an entry granting the `admin` role; anything else is 403
    `managed_at_admin_site`.

    Replaces DELETE /ecosystem/signup-list/{id}/entries/{entryId}.

    Args:
        id (str):
        entry_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Deleted | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
        entry_id=entry_id,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    entry_id: str,
    *,
    client: AuthenticatedClient,
) -> Deleted | StripeError | None:
    """Remove a sign-up list entry

     While the ecosystem limits sign-in to a list of emails, the email is removed from that list too. A
    role already granted stays granted. While the product's admin site is live and `consented_access` is
    on, a manager may remove only an entry granting the `admin` role; anything else is 403
    `managed_at_admin_site`.

    Replaces DELETE /ecosystem/signup-list/{id}/entries/{entryId}.

    Args:
        id (str):
        entry_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Deleted | StripeError
    """

    return (
        await asyncio_detailed(
            id=id,
            entry_id=entry_id,
            client=client,
        )
    ).parsed
