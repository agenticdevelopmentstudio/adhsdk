from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.get_customer_memberships_response_200_item import (
    GetCustomerMembershipsResponse200Item,
)
from ...types import UNSET, Response


def _get_kwargs(
    *,
    user_ids: str,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["userIds"] = user_ids

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/customer/memberships",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | list[GetCustomerMembershipsResponse200Item] | None:
    if response.status_code == 200:
        response_200 = []
        _response_200 = response.json()
        for response_200_item_data in _response_200:
            response_200_item = GetCustomerMembershipsResponse200Item.from_dict(
                response_200_item_data
            )

            response_200.append(response_200_item)

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
) -> Response[Error | list[GetCustomerMembershipsResponse200Item]]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    user_ids: str,
) -> Response[Error | list[GetCustomerMembershipsResponse200Item]]:
    """Which ecosystems these people are customers of (admin)

     `customer.customers` is per-ecosystem, so one person is several rows and this answers a question
    about a SET of them, joined by EMAIL — the only column that identifies the same human in two
    tenancies. A customer with no email has exactly one membership here, correctly: nothing about them
    can be matched to a row elsewhere. Batched because the admin Users page needs the answer for every
    row it shows.

    Args:
        user_ids (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | list[GetCustomerMembershipsResponse200Item]]
    """

    kwargs = _get_kwargs(
        user_ids=user_ids,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    user_ids: str,
) -> Error | list[GetCustomerMembershipsResponse200Item] | None:
    """Which ecosystems these people are customers of (admin)

     `customer.customers` is per-ecosystem, so one person is several rows and this answers a question
    about a SET of them, joined by EMAIL — the only column that identifies the same human in two
    tenancies. A customer with no email has exactly one membership here, correctly: nothing about them
    can be matched to a row elsewhere. Batched because the admin Users page needs the answer for every
    row it shows.

    Args:
        user_ids (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | list[GetCustomerMembershipsResponse200Item]
    """

    return sync_detailed(
        client=client,
        user_ids=user_ids,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    user_ids: str,
) -> Response[Error | list[GetCustomerMembershipsResponse200Item]]:
    """Which ecosystems these people are customers of (admin)

     `customer.customers` is per-ecosystem, so one person is several rows and this answers a question
    about a SET of them, joined by EMAIL — the only column that identifies the same human in two
    tenancies. A customer with no email has exactly one membership here, correctly: nothing about them
    can be matched to a row elsewhere. Batched because the admin Users page needs the answer for every
    row it shows.

    Args:
        user_ids (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | list[GetCustomerMembershipsResponse200Item]]
    """

    kwargs = _get_kwargs(
        user_ids=user_ids,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    user_ids: str,
) -> Error | list[GetCustomerMembershipsResponse200Item] | None:
    """Which ecosystems these people are customers of (admin)

     `customer.customers` is per-ecosystem, so one person is several rows and this answers a question
    about a SET of them, joined by EMAIL — the only column that identifies the same human in two
    tenancies. A customer with no email has exactly one membership here, correctly: nothing about them
    can be matched to a row elsewhere. Batched because the admin Users page needs the answer for every
    row it shows.

    Args:
        user_ids (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | list[GetCustomerMembershipsResponse200Item]
    """

    return (
        await asyncio_detailed(
            client=client,
            user_ids=user_ids,
        )
    ).parsed
