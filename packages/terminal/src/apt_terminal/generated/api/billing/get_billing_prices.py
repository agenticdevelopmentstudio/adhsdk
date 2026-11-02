from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.billing_price_option import BillingPriceOption
from ...models.error import Error
from ...types import Response


def _get_kwargs() -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/billing/prices",
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | list[BillingPriceOption] | None:
    if response.status_code == 200:
        response_200 = []
        _response_200 = response.json()
        for response_200_item_data in _response_200:
            response_200_item = BillingPriceOption.from_dict(response_200_item_data)

            response_200.append(response_200_item)

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

    if response.status_code == 409:
        response_409 = Error.from_dict(response.json())

        return response_409

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | list[BillingPriceOption]]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
) -> Response[Error | list[BillingPriceOption]]:
    """Active prices on the ecosystem’s connected Stripe account

     The list the offer editor picks a `stripe_price_id` from. Active prices only, with their product
    expanded, walked to a hard cap of 1000 — high enough that no plausible catalog of things an operator
    SELLS reaches it, low enough that one HTTP request cannot turn into an unbounded series of round-
    trips against a third party. Nothing is cached or stored: adh configures the OFFER, Stripe owns the
    money.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | list[BillingPriceOption]]
    """

    kwargs = _get_kwargs()

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
) -> Error | list[BillingPriceOption] | None:
    """Active prices on the ecosystem’s connected Stripe account

     The list the offer editor picks a `stripe_price_id` from. Active prices only, with their product
    expanded, walked to a hard cap of 1000 — high enough that no plausible catalog of things an operator
    SELLS reaches it, low enough that one HTTP request cannot turn into an unbounded series of round-
    trips against a third party. Nothing is cached or stored: adh configures the OFFER, Stripe owns the
    money.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | list[BillingPriceOption]
    """

    return sync_detailed(
        client=client,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
) -> Response[Error | list[BillingPriceOption]]:
    """Active prices on the ecosystem’s connected Stripe account

     The list the offer editor picks a `stripe_price_id` from. Active prices only, with their product
    expanded, walked to a hard cap of 1000 — high enough that no plausible catalog of things an operator
    SELLS reaches it, low enough that one HTTP request cannot turn into an unbounded series of round-
    trips against a third party. Nothing is cached or stored: adh configures the OFFER, Stripe owns the
    money.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | list[BillingPriceOption]]
    """

    kwargs = _get_kwargs()

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
) -> Error | list[BillingPriceOption] | None:
    """Active prices on the ecosystem’s connected Stripe account

     The list the offer editor picks a `stripe_price_id` from. Active prices only, with their product
    expanded, walked to a hard cap of 1000 — high enough that no plausible catalog of things an operator
    SELLS reaches it, low enough that one HTTP request cannot turn into an unbounded series of round-
    trips against a third party. Nothing is cached or stored: adh configures the OFFER, Stripe owns the
    money.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | list[BillingPriceOption]
    """

    return (
        await asyncio_detailed(
            client=client,
        )
    ).parsed
