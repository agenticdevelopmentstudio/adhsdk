from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.billing_event import BillingEvent
from ...models.error import Error
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    limit: str | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["limit"] = limit

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/billing/events",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | list[BillingEvent] | None:
    if response.status_code == 200:
        response_200 = []
        _response_200 = response.json()
        for response_200_item_data in _response_200:
            response_200_item = BillingEvent.from_dict(response_200_item_data)

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

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | list[BillingEvent]]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    limit: str | Unset = UNSET,
) -> Response[Error | list[BillingEvent]]:
    """The webhook ledger, newest first

     The receipt log the redrive below operates on: did the event arrive, and did it process. A row with
    `processedAt: null` beside an `error` is the surface this route exists for — without it a purchase
    that never landed is only visible in the database.

    The stored payload is NOT returned. It is Stripe’s event body verbatim, and an operator’s ledger is
    not a place to re-publish a third party’s customer data; what this returns is the six fields that
    answer the question.

    Args:
        limit (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | list[BillingEvent]]
    """

    kwargs = _get_kwargs(
        limit=limit,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    limit: str | Unset = UNSET,
) -> Error | list[BillingEvent] | None:
    """The webhook ledger, newest first

     The receipt log the redrive below operates on: did the event arrive, and did it process. A row with
    `processedAt: null` beside an `error` is the surface this route exists for — without it a purchase
    that never landed is only visible in the database.

    The stored payload is NOT returned. It is Stripe’s event body verbatim, and an operator’s ledger is
    not a place to re-publish a third party’s customer data; what this returns is the six fields that
    answer the question.

    Args:
        limit (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | list[BillingEvent]
    """

    return sync_detailed(
        client=client,
        limit=limit,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    limit: str | Unset = UNSET,
) -> Response[Error | list[BillingEvent]]:
    """The webhook ledger, newest first

     The receipt log the redrive below operates on: did the event arrive, and did it process. A row with
    `processedAt: null` beside an `error` is the surface this route exists for — without it a purchase
    that never landed is only visible in the database.

    The stored payload is NOT returned. It is Stripe’s event body verbatim, and an operator’s ledger is
    not a place to re-publish a third party’s customer data; what this returns is the six fields that
    answer the question.

    Args:
        limit (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | list[BillingEvent]]
    """

    kwargs = _get_kwargs(
        limit=limit,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    limit: str | Unset = UNSET,
) -> Error | list[BillingEvent] | None:
    """The webhook ledger, newest first

     The receipt log the redrive below operates on: did the event arrive, and did it process. A row with
    `processedAt: null` beside an `error` is the surface this route exists for — without it a purchase
    that never landed is only visible in the database.

    The stored payload is NOT returned. It is Stripe’s event body verbatim, and an operator’s ledger is
    not a place to re-publish a third party’s customer data; what this returns is the six fields that
    answer the question.

    Args:
        limit (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | list[BillingEvent]
    """

    return (
        await asyncio_detailed(
            client=client,
            limit=limit,
        )
    ).parsed
