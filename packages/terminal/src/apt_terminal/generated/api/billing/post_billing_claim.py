from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.billing_claim_request import BillingClaimRequest
from ...models.billing_claim_result import BillingClaimResult
from ...models.error import Error
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    body: BillingClaimRequest | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/billing/claim",
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> BillingClaimResult | Error | None:
    if response.status_code == 200:
        response_200 = BillingClaimResult.from_dict(response.json())

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
) -> Response[BillingClaimResult | Error]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    body: BillingClaimRequest | Unset = UNSET,
) -> Response[BillingClaimResult | Error]:
    """Redeem a claim token, binding a paid account to the caller

     Authenticated, and on the billing base rather than `/public`, because redeeming BINDS an adh
    identity to a paid account and there is nothing to bind without a session — a claim route mounted on
    `/public` would read the principal as undefined on every request and refuse every claim. The page
    that collects the token is the public half and lives in the frontend; it posts here once the visitor
    is signed in. A delegated (acting) principal is refused outright: delegation means "act on their
    behalf", and irreversibly claiming ownership of something they paid for is not that.

    IDEMPOTENT FOR THE CLAIMANT, single-use for everyone else. A repeat presentation by the identity
    that already claimed it returns the same body as the first call, so a prefetching mail client or a
    retried POST does not tell the payer their link is invalid; a DIFFERENT identity presenting the same
    token still gets the 404.

    Args:
        body (BillingClaimRequest | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[BillingClaimResult | Error]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    body: BillingClaimRequest | Unset = UNSET,
) -> BillingClaimResult | Error | None:
    """Redeem a claim token, binding a paid account to the caller

     Authenticated, and on the billing base rather than `/public`, because redeeming BINDS an adh
    identity to a paid account and there is nothing to bind without a session — a claim route mounted on
    `/public` would read the principal as undefined on every request and refuse every claim. The page
    that collects the token is the public half and lives in the frontend; it posts here once the visitor
    is signed in. A delegated (acting) principal is refused outright: delegation means "act on their
    behalf", and irreversibly claiming ownership of something they paid for is not that.

    IDEMPOTENT FOR THE CLAIMANT, single-use for everyone else. A repeat presentation by the identity
    that already claimed it returns the same body as the first call, so a prefetching mail client or a
    retried POST does not tell the payer their link is invalid; a DIFFERENT identity presenting the same
    token still gets the 404.

    Args:
        body (BillingClaimRequest | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        BillingClaimResult | Error
    """

    return sync_detailed(
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    body: BillingClaimRequest | Unset = UNSET,
) -> Response[BillingClaimResult | Error]:
    """Redeem a claim token, binding a paid account to the caller

     Authenticated, and on the billing base rather than `/public`, because redeeming BINDS an adh
    identity to a paid account and there is nothing to bind without a session — a claim route mounted on
    `/public` would read the principal as undefined on every request and refuse every claim. The page
    that collects the token is the public half and lives in the frontend; it posts here once the visitor
    is signed in. A delegated (acting) principal is refused outright: delegation means "act on their
    behalf", and irreversibly claiming ownership of something they paid for is not that.

    IDEMPOTENT FOR THE CLAIMANT, single-use for everyone else. A repeat presentation by the identity
    that already claimed it returns the same body as the first call, so a prefetching mail client or a
    retried POST does not tell the payer their link is invalid; a DIFFERENT identity presenting the same
    token still gets the 404.

    Args:
        body (BillingClaimRequest | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[BillingClaimResult | Error]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    body: BillingClaimRequest | Unset = UNSET,
) -> BillingClaimResult | Error | None:
    """Redeem a claim token, binding a paid account to the caller

     Authenticated, and on the billing base rather than `/public`, because redeeming BINDS an adh
    identity to a paid account and there is nothing to bind without a session — a claim route mounted on
    `/public` would read the principal as undefined on every request and refuse every claim. The page
    that collects the token is the public half and lives in the frontend; it posts here once the visitor
    is signed in. A delegated (acting) principal is refused outright: delegation means "act on their
    behalf", and irreversibly claiming ownership of something they paid for is not that.

    IDEMPOTENT FOR THE CLAIMANT, single-use for everyone else. A repeat presentation by the identity
    that already claimed it returns the same body as the first call, so a prefetching mail client or a
    retried POST does not tell the payer their link is invalid; a DIFFERENT identity presenting the same
    token still gets the 404.

    Args:
        body (BillingClaimRequest | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        BillingClaimResult | Error
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
        )
    ).parsed
