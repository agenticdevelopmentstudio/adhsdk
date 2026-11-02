from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.billing_redrive_result import BillingRedriveResult
from ...models.error import Error
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    include_processed: str | Unset = UNSET,
    offset: str | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["includeProcessed"] = include_processed

    params["offset"] = offset

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/billing/events/redrive",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> BillingRedriveResult | Error | None:
    if response.status_code == 200:
        response_200 = BillingRedriveResult.from_dict(response.json())

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
) -> Response[BillingRedriveResult | Error]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    include_processed: str | Unset = UNSET,
    offset: str | Unset = UNSET,
) -> Response[BillingRedriveResult | Error]:
    """Re-apply stored Stripe events the receiver could not apply

     The receiver STORES every verified event before it tries to apply it, so an event that arrived
    before its offer existed — or that hit a transient failure — is still on disk. This re-applies a
    batch of 100 in `receivedAt` order and reports what happened to each. `nextOffset` is the cursor: it
    is non-null exactly when the batch came back full, and passing it as `offset` is what makes the
    second call a DIFFERENT batch. Without it the fixed limit was not pagination at all — a row the
    redrive examines but cannot advance stays in the first hundred forever, and everything behind it was
    unreachable through this API.

    Args:
        include_processed (str | Unset):
        offset (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[BillingRedriveResult | Error]
    """

    kwargs = _get_kwargs(
        include_processed=include_processed,
        offset=offset,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    include_processed: str | Unset = UNSET,
    offset: str | Unset = UNSET,
) -> BillingRedriveResult | Error | None:
    """Re-apply stored Stripe events the receiver could not apply

     The receiver STORES every verified event before it tries to apply it, so an event that arrived
    before its offer existed — or that hit a transient failure — is still on disk. This re-applies a
    batch of 100 in `receivedAt` order and reports what happened to each. `nextOffset` is the cursor: it
    is non-null exactly when the batch came back full, and passing it as `offset` is what makes the
    second call a DIFFERENT batch. Without it the fixed limit was not pagination at all — a row the
    redrive examines but cannot advance stays in the first hundred forever, and everything behind it was
    unreachable through this API.

    Args:
        include_processed (str | Unset):
        offset (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        BillingRedriveResult | Error
    """

    return sync_detailed(
        client=client,
        include_processed=include_processed,
        offset=offset,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    include_processed: str | Unset = UNSET,
    offset: str | Unset = UNSET,
) -> Response[BillingRedriveResult | Error]:
    """Re-apply stored Stripe events the receiver could not apply

     The receiver STORES every verified event before it tries to apply it, so an event that arrived
    before its offer existed — or that hit a transient failure — is still on disk. This re-applies a
    batch of 100 in `receivedAt` order and reports what happened to each. `nextOffset` is the cursor: it
    is non-null exactly when the batch came back full, and passing it as `offset` is what makes the
    second call a DIFFERENT batch. Without it the fixed limit was not pagination at all — a row the
    redrive examines but cannot advance stays in the first hundred forever, and everything behind it was
    unreachable through this API.

    Args:
        include_processed (str | Unset):
        offset (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[BillingRedriveResult | Error]
    """

    kwargs = _get_kwargs(
        include_processed=include_processed,
        offset=offset,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    include_processed: str | Unset = UNSET,
    offset: str | Unset = UNSET,
) -> BillingRedriveResult | Error | None:
    """Re-apply stored Stripe events the receiver could not apply

     The receiver STORES every verified event before it tries to apply it, so an event that arrived
    before its offer existed — or that hit a transient failure — is still on disk. This re-applies a
    batch of 100 in `receivedAt` order and reports what happened to each. `nextOffset` is the cursor: it
    is non-null exactly when the batch came back full, and passing it as `offset` is what makes the
    second call a DIFFERENT batch. Without it the fixed limit was not pagination at all — a row the
    redrive examines but cannot advance stays in the first hundred forever, and everything behind it was
    unreachable through this API.

    Args:
        include_processed (str | Unset):
        offset (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        BillingRedriveResult | Error
    """

    return (
        await asyncio_detailed(
            client=client,
            include_processed=include_processed,
            offset=offset,
        )
    ).parsed
