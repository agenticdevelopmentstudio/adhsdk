from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.delete_customer_memberships_customer_id_response_200 import (
    DeleteCustomerMembershipsCustomerIdResponse200,
)
from ...models.error import Error
from ...types import Response


def _get_kwargs(
    customer_id: str,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "delete",
        "url": "/customer/memberships/{customer_id}".format(
            customer_id=quote(str(customer_id), safe=""),
        ),
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> DeleteCustomerMembershipsCustomerIdResponse200 | Error | None:
    if response.status_code == 200:
        response_200 = DeleteCustomerMembershipsCustomerIdResponse200.from_dict(response.json())

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
) -> Response[DeleteCustomerMembershipsCustomerIdResponse200 | Error]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    customer_id: str,
    *,
    client: AuthenticatedClient,
) -> Response[DeleteCustomerMembershipsCustomerIdResponse200 | Error]:
    """Take this person out of ONE ecosystem (admin)

     Addressed by the customer row that carries the membership, not by the person. Refuses the hub row
    with 400: that row is the person's ACCOUNT — their capabilities, their credentials and their address
    — so removing it is "delete this user", a different operation with a different confirmation.

    Args:
        customer_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[DeleteCustomerMembershipsCustomerIdResponse200 | Error]
    """

    kwargs = _get_kwargs(
        customer_id=customer_id,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    customer_id: str,
    *,
    client: AuthenticatedClient,
) -> DeleteCustomerMembershipsCustomerIdResponse200 | Error | None:
    """Take this person out of ONE ecosystem (admin)

     Addressed by the customer row that carries the membership, not by the person. Refuses the hub row
    with 400: that row is the person's ACCOUNT — their capabilities, their credentials and their address
    — so removing it is "delete this user", a different operation with a different confirmation.

    Args:
        customer_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        DeleteCustomerMembershipsCustomerIdResponse200 | Error
    """

    return sync_detailed(
        customer_id=customer_id,
        client=client,
    ).parsed


async def asyncio_detailed(
    customer_id: str,
    *,
    client: AuthenticatedClient,
) -> Response[DeleteCustomerMembershipsCustomerIdResponse200 | Error]:
    """Take this person out of ONE ecosystem (admin)

     Addressed by the customer row that carries the membership, not by the person. Refuses the hub row
    with 400: that row is the person's ACCOUNT — their capabilities, their credentials and their address
    — so removing it is "delete this user", a different operation with a different confirmation.

    Args:
        customer_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[DeleteCustomerMembershipsCustomerIdResponse200 | Error]
    """

    kwargs = _get_kwargs(
        customer_id=customer_id,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    customer_id: str,
    *,
    client: AuthenticatedClient,
) -> DeleteCustomerMembershipsCustomerIdResponse200 | Error | None:
    """Take this person out of ONE ecosystem (admin)

     Addressed by the customer row that carries the membership, not by the person. Refuses the hub row
    with 400: that row is the person's ACCOUNT — their capabilities, their credentials and their address
    — so removing it is "delete this user", a different operation with a different confirmation.

    Args:
        customer_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        DeleteCustomerMembershipsCustomerIdResponse200 | Error
    """

    return (
        await asyncio_detailed(
            customer_id=customer_id,
            client=client,
        )
    ).parsed
