from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.post_v1_ecosystems_by_id_signup_list_entries_response_200 import (
    PostV1EcosystemsByIdSignupListEntriesResponse200,
)
from ...models.signup_list_entry_put import SignupListEntryPut
from ...models.stripe_error import StripeError
from ...types import Response


def _get_kwargs(
    id: str,
    *,
    body: SignupListEntryPut,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/ecosystems/{id}/signup_list_entries".format(
            id=quote(str(id), safe=""),
        ),
    }

    _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostV1EcosystemsByIdSignupListEntriesResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = PostV1EcosystemsByIdSignupListEntriesResponse200.from_dict(response.json())

        return response_200

    if response.status_code == 400:
        response_400 = StripeError.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = StripeError.from_dict(response.json())

        return response_401

    if response.status_code == 403:
        response_403 = StripeError.from_dict(response.json())

        return response_403

    if response.status_code == 404:
        response_404 = StripeError.from_dict(response.json())

        return response_404

    if response.status_code == 422:
        response_422 = StripeError.from_dict(response.json())

        return response_422

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[PostV1EcosystemsByIdSignupListEntriesResponse200 | StripeError]:
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
    body: SignupListEntryPut,
) -> Response[PostV1EcosystemsByIdSignupListEntriesResponse200 | StripeError]:
    """Add or change a sign-up list entry

     Upserts by email. While the ecosystem limits sign-in to a list of emails, the email is added to that
    list in the same transaction. While the product's admin site is live and `consented_access` is on, a
    manager may write only an entry granting the `admin` role, keeping its set; anything else is 403
    `managed_at_admin_site`.

    Replaces PUT /ecosystem/signup-list/{id}.

    Args:
        id (str):
        body (SignupListEntryPut):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1EcosystemsByIdSignupListEntriesResponse200 | StripeError]
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
    body: SignupListEntryPut,
) -> PostV1EcosystemsByIdSignupListEntriesResponse200 | StripeError | None:
    """Add or change a sign-up list entry

     Upserts by email. While the ecosystem limits sign-in to a list of emails, the email is added to that
    list in the same transaction. While the product's admin site is live and `consented_access` is on, a
    manager may write only an entry granting the `admin` role, keeping its set; anything else is 403
    `managed_at_admin_site`.

    Replaces PUT /ecosystem/signup-list/{id}.

    Args:
        id (str):
        body (SignupListEntryPut):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1EcosystemsByIdSignupListEntriesResponse200 | StripeError
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
    body: SignupListEntryPut,
) -> Response[PostV1EcosystemsByIdSignupListEntriesResponse200 | StripeError]:
    """Add or change a sign-up list entry

     Upserts by email. While the ecosystem limits sign-in to a list of emails, the email is added to that
    list in the same transaction. While the product's admin site is live and `consented_access` is on, a
    manager may write only an entry granting the `admin` role, keeping its set; anything else is 403
    `managed_at_admin_site`.

    Replaces PUT /ecosystem/signup-list/{id}.

    Args:
        id (str):
        body (SignupListEntryPut):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1EcosystemsByIdSignupListEntriesResponse200 | StripeError]
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
    body: SignupListEntryPut,
) -> PostV1EcosystemsByIdSignupListEntriesResponse200 | StripeError | None:
    """Add or change a sign-up list entry

     Upserts by email. While the ecosystem limits sign-in to a list of emails, the email is added to that
    list in the same transaction. While the product's admin site is live and `consented_access` is on, a
    manager may write only an entry granting the `admin` role, keeping its set; anything else is 403
    `managed_at_admin_site`.

    Replaces PUT /ecosystem/signup-list/{id}.

    Args:
        id (str):
        body (SignupListEntryPut):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1EcosystemsByIdSignupListEntriesResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            body=body,
        )
    ).parsed
