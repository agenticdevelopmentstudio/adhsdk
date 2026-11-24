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
    resource: str,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "delete",
        "url": "/v1/sync/tables/{id}/resources/{resource}".format(
            id=quote(str(id), safe=""),
            resource=quote(str(resource), safe=""),
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
    resource: str,
    *,
    client: AuthenticatedClient,
) -> Response[Deleted | StripeError]:
    """Drop the override and fall back to the catalog default

     Idempotent, and deliberately unvalidated: clearing an override that was never set — or one naming a
    resource the catalog has since dropped — succeeds rather than 400ing, so a stale override can always
    be cleaned up.

    Replaces DELETE /admin/sync/tables/{id}/{resource}.

    Args:
        id (str):
        resource (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Deleted | StripeError]
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
) -> Deleted | StripeError | None:
    """Drop the override and fall back to the catalog default

     Idempotent, and deliberately unvalidated: clearing an override that was never set — or one naming a
    resource the catalog has since dropped — succeeds rather than 400ing, so a stale override can always
    be cleaned up.

    Replaces DELETE /admin/sync/tables/{id}/{resource}.

    Args:
        id (str):
        resource (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Deleted | StripeError
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
) -> Response[Deleted | StripeError]:
    """Drop the override and fall back to the catalog default

     Idempotent, and deliberately unvalidated: clearing an override that was never set — or one naming a
    resource the catalog has since dropped — succeeds rather than 400ing, so a stale override can always
    be cleaned up.

    Replaces DELETE /admin/sync/tables/{id}/{resource}.

    Args:
        id (str):
        resource (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Deleted | StripeError]
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
) -> Deleted | StripeError | None:
    """Drop the override and fall back to the catalog default

     Idempotent, and deliberately unvalidated: clearing an override that was never set — or one naming a
    resource the catalog has since dropped — succeeds rather than 400ing, so a stale override can always
    be cleaned up.

    Replaces DELETE /admin/sync/tables/{id}/{resource}.

    Args:
        id (str):
        resource (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Deleted | StripeError
    """

    return (
        await asyncio_detailed(
            id=id,
            resource=resource,
            client=client,
        )
    ).parsed
