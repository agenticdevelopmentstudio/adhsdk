from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.billing_resend_claim import BillingResendClaim
from ...models.error import Error
from ...types import Response


def _get_kwargs(
    id: str,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/billing/accounts/{id}/resend-claim".format(
            id=quote(str(id), safe=""),
        ),
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> BillingResendClaim | Error | None:
    if response.status_code == 200:
        response_200 = BillingResendClaim.from_dict(response.json())

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
) -> Response[BillingResendClaim | Error]:
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
) -> Response[BillingResendClaim | Error]:
    """Mint a fresh claim token for one account and mail it again

     It MINTS rather than resends: the stored value is a one-way hash, so the original token is
    unrecoverable and there is nothing to re-send. A fresh token restarts the claim TTL — which is what
    an expired link needs — and invalidates the previous one by overwriting the hash, which is what an
    operator who suspects the first link leaked wants. Delivery happens after the transaction commits
    and cannot fail the call: the mailer never throws and logs every path that does not send, so a
    second failure is visible in the logs and this route can simply be called again. A 200 therefore
    means "a new token exists", not "the payer received it".

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[BillingResendClaim | Error]
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
) -> BillingResendClaim | Error | None:
    """Mint a fresh claim token for one account and mail it again

     It MINTS rather than resends: the stored value is a one-way hash, so the original token is
    unrecoverable and there is nothing to re-send. A fresh token restarts the claim TTL — which is what
    an expired link needs — and invalidates the previous one by overwriting the hash, which is what an
    operator who suspects the first link leaked wants. Delivery happens after the transaction commits
    and cannot fail the call: the mailer never throws and logs every path that does not send, so a
    second failure is visible in the logs and this route can simply be called again. A 200 therefore
    means "a new token exists", not "the payer received it".

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        BillingResendClaim | Error
    """

    return sync_detailed(
        id=id,
        client=client,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
) -> Response[BillingResendClaim | Error]:
    """Mint a fresh claim token for one account and mail it again

     It MINTS rather than resends: the stored value is a one-way hash, so the original token is
    unrecoverable and there is nothing to re-send. A fresh token restarts the claim TTL — which is what
    an expired link needs — and invalidates the previous one by overwriting the hash, which is what an
    operator who suspects the first link leaked wants. Delivery happens after the transaction commits
    and cannot fail the call: the mailer never throws and logs every path that does not send, so a
    second failure is visible in the logs and this route can simply be called again. A 200 therefore
    means "a new token exists", not "the payer received it".

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[BillingResendClaim | Error]
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
) -> BillingResendClaim | Error | None:
    """Mint a fresh claim token for one account and mail it again

     It MINTS rather than resends: the stored value is a one-way hash, so the original token is
    unrecoverable and there is nothing to re-send. A fresh token restarts the claim TTL — which is what
    an expired link needs — and invalidates the previous one by overwriting the hash, which is what an
    operator who suspects the first link leaked wants. Delivery happens after the transaction commits
    and cannot fail the call: the mailer never throws and logs every path that does not send, so a
    second failure is visible in the logs and this route can simply be called again. A 200 therefore
    means "a new token exists", not "the payer received it".

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        BillingResendClaim | Error
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
        )
    ).parsed
