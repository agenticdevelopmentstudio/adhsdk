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
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "delete",
        "url": "/v1/organizations/{id}".format(
            id=quote(str(id), safe=""),
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

    if response.status_code == 409:
        response_409 = StripeError.from_dict(response.json())

        return response_409

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
    *,
    client: AuthenticatedClient,
) -> Response[Deleted | StripeError]:
    """Archive an organization — hides it and releases its rdid (org creator, org-team admin, or site-
    admin)

     Archives the organization, its workspace and everything addressed under its slug. 404 when it does
    not exist or is already archived. 409 with a `code` when it may not be archived: `operators_org` for
    the operators organization, the root every workspace hangs under; `org_has_child_orgs` while it owns
    a live organization, which must be archived or deleted first. Nothing is archived on a 409.

    Replaces DELETE /organization/organizations/{id}.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Deleted | StripeError]
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
) -> Deleted | StripeError | None:
    """Archive an organization — hides it and releases its rdid (org creator, org-team admin, or site-
    admin)

     Archives the organization, its workspace and everything addressed under its slug. 404 when it does
    not exist or is already archived. 409 with a `code` when it may not be archived: `operators_org` for
    the operators organization, the root every workspace hangs under; `org_has_child_orgs` while it owns
    a live organization, which must be archived or deleted first. Nothing is archived on a 409.

    Replaces DELETE /organization/organizations/{id}.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Deleted | StripeError
    """

    return sync_detailed(
        id=id,
        client=client,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
) -> Response[Deleted | StripeError]:
    """Archive an organization — hides it and releases its rdid (org creator, org-team admin, or site-
    admin)

     Archives the organization, its workspace and everything addressed under its slug. 404 when it does
    not exist or is already archived. 409 with a `code` when it may not be archived: `operators_org` for
    the operators organization, the root every workspace hangs under; `org_has_child_orgs` while it owns
    a live organization, which must be archived or deleted first. Nothing is archived on a 409.

    Replaces DELETE /organization/organizations/{id}.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Deleted | StripeError]
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
) -> Deleted | StripeError | None:
    """Archive an organization — hides it and releases its rdid (org creator, org-team admin, or site-
    admin)

     Archives the organization, its workspace and everything addressed under its slug. 404 when it does
    not exist or is already archived. 409 with a `code` when it may not be archived: `operators_org` for
    the operators organization, the root every workspace hangs under; `org_has_child_orgs` while it owns
    a live organization, which must be archived or deleted first. Nothing is archived on a 409.

    Replaces DELETE /organization/organizations/{id}.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Deleted | StripeError
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
        )
    ).parsed
