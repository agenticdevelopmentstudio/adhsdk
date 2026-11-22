from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.post_v1_customers_me_email_verification_start_response_202 import (
    PostV1CustomersMeEmailVerificationStartResponse202,
)
from ...models.stripe_error import StripeError
from ...types import Response


def _get_kwargs() -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/customers/me/email_verification/start",
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostV1CustomersMeEmailVerificationStartResponse202 | StripeError | None:
    if response.status_code == 202:
        response_202 = PostV1CustomersMeEmailVerificationStartResponse202.from_dict(response.json())

        return response_202

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

    if response.status_code == 422:
        response_422 = StripeError.from_dict(response.json())

        return response_422

    if response.status_code == 429:
        response_429 = StripeError.from_dict(response.json())

        return response_429

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[PostV1CustomersMeEmailVerificationStartResponse202 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
) -> Response[PostV1CustomersMeEmailVerificationStartResponse202 | StripeError]:
    """Send a code to the signed-in customer's own sign-up email

     Under a customer token. The code goes to the customer's `customers.email`; no address is accepted.
    409 when the email is already verified or held by another account, 429 within the resend cooldown,
    422 when the code could not be sent.

    Replaces POST /customer/email/verify/start.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1CustomersMeEmailVerificationStartResponse202 | StripeError]
    """

    kwargs = _get_kwargs()

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
) -> PostV1CustomersMeEmailVerificationStartResponse202 | StripeError | None:
    """Send a code to the signed-in customer's own sign-up email

     Under a customer token. The code goes to the customer's `customers.email`; no address is accepted.
    409 when the email is already verified or held by another account, 429 within the resend cooldown,
    422 when the code could not be sent.

    Replaces POST /customer/email/verify/start.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1CustomersMeEmailVerificationStartResponse202 | StripeError
    """

    return sync_detailed(
        client=client,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
) -> Response[PostV1CustomersMeEmailVerificationStartResponse202 | StripeError]:
    """Send a code to the signed-in customer's own sign-up email

     Under a customer token. The code goes to the customer's `customers.email`; no address is accepted.
    409 when the email is already verified or held by another account, 429 within the resend cooldown,
    422 when the code could not be sent.

    Replaces POST /customer/email/verify/start.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1CustomersMeEmailVerificationStartResponse202 | StripeError]
    """

    kwargs = _get_kwargs()

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
) -> PostV1CustomersMeEmailVerificationStartResponse202 | StripeError | None:
    """Send a code to the signed-in customer's own sign-up email

     Under a customer token. The code goes to the customer's `customers.email`; no address is accepted.
    409 when the email is already verified or held by another account, 429 within the resend cooldown,
    422 when the code could not be sent.

    Replaces POST /customer/email/verify/start.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1CustomersMeEmailVerificationStartResponse202 | StripeError
    """

    return (
        await asyncio_detailed(
            client=client,
        )
    ).parsed
