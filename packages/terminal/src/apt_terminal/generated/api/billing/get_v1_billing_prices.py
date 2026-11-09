from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.get_v1_billing_prices_response_200 import GetV1BillingPricesResponse200
from ...models.stripe_error import StripeError
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    limit: int | Unset = 10,
    starting_after: str | Unset = UNSET,
    ending_before: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["limit"] = limit

    params["starting_after"] = starting_after

    params["ending_before"] = ending_before

    json_expand: list[str] | Unset = UNSET
    if not isinstance(expand, Unset):
        json_expand = expand

    params["expand[]"] = json_expand

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/v1/billing/prices",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> GetV1BillingPricesResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = GetV1BillingPricesResponse200.from_dict(response.json())

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
) -> Response[GetV1BillingPricesResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    limit: int | Unset = 10,
    starting_after: str | Unset = UNSET,
    ending_before: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1BillingPricesResponse200 | StripeError]:
    """Active prices on the ecosystem’s connected Stripe account

     The list the offer editor picks a `stripe_price_id` from. Active prices only, with their product
    expanded, walked to a hard cap of 1000 — high enough that no plausible catalog of things an operator
    SELLS reaches it, low enough that one HTTP request cannot turn into an unbounded series of round-
    trips against a third party. Nothing is cached or stored: adh configures the OFFER, Stripe owns the
    money.

    Replaces GET /billing/prices.

    Args:
        limit (int | Unset):  Default: 10.
        starting_after (str | Unset):
        ending_before (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1BillingPricesResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        limit=limit,
        starting_after=starting_after,
        ending_before=ending_before,
        expand=expand,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    limit: int | Unset = 10,
    starting_after: str | Unset = UNSET,
    ending_before: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> GetV1BillingPricesResponse200 | StripeError | None:
    """Active prices on the ecosystem’s connected Stripe account

     The list the offer editor picks a `stripe_price_id` from. Active prices only, with their product
    expanded, walked to a hard cap of 1000 — high enough that no plausible catalog of things an operator
    SELLS reaches it, low enough that one HTTP request cannot turn into an unbounded series of round-
    trips against a third party. Nothing is cached or stored: adh configures the OFFER, Stripe owns the
    money.

    Replaces GET /billing/prices.

    Args:
        limit (int | Unset):  Default: 10.
        starting_after (str | Unset):
        ending_before (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1BillingPricesResponse200 | StripeError
    """

    return sync_detailed(
        client=client,
        limit=limit,
        starting_after=starting_after,
        ending_before=ending_before,
        expand=expand,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    limit: int | Unset = 10,
    starting_after: str | Unset = UNSET,
    ending_before: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1BillingPricesResponse200 | StripeError]:
    """Active prices on the ecosystem’s connected Stripe account

     The list the offer editor picks a `stripe_price_id` from. Active prices only, with their product
    expanded, walked to a hard cap of 1000 — high enough that no plausible catalog of things an operator
    SELLS reaches it, low enough that one HTTP request cannot turn into an unbounded series of round-
    trips against a third party. Nothing is cached or stored: adh configures the OFFER, Stripe owns the
    money.

    Replaces GET /billing/prices.

    Args:
        limit (int | Unset):  Default: 10.
        starting_after (str | Unset):
        ending_before (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1BillingPricesResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        limit=limit,
        starting_after=starting_after,
        ending_before=ending_before,
        expand=expand,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    limit: int | Unset = 10,
    starting_after: str | Unset = UNSET,
    ending_before: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> GetV1BillingPricesResponse200 | StripeError | None:
    """Active prices on the ecosystem’s connected Stripe account

     The list the offer editor picks a `stripe_price_id` from. Active prices only, with their product
    expanded, walked to a hard cap of 1000 — high enough that no plausible catalog of things an operator
    SELLS reaches it, low enough that one HTTP request cannot turn into an unbounded series of round-
    trips against a third party. Nothing is cached or stored: adh configures the OFFER, Stripe owns the
    money.

    Replaces GET /billing/prices.

    Args:
        limit (int | Unset):  Default: 10.
        starting_after (str | Unset):
        ending_before (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1BillingPricesResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            client=client,
            limit=limit,
            starting_after=starting_after,
            ending_before=ending_before,
            expand=expand,
        )
    ).parsed
