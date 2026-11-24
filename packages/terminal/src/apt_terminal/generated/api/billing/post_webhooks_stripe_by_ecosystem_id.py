from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.legacy_billing_ack import LegacyBillingAck
from ...models.legacy_error import LegacyError
from ...models.legacy_stripe_webhook_event import LegacyStripeWebhookEvent
from ...types import Response


def _get_kwargs(
    ecosystem_id: str,
    *,
    body: LegacyStripeWebhookEvent,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/webhooks/stripe/{ecosystem_id}".format(
            ecosystem_id=quote(str(ecosystem_id), safe=""),
        ),
    }

    _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> LegacyBillingAck | LegacyError | None:
    if response.status_code == 200:
        response_200 = LegacyBillingAck.from_dict(response.json())

        return response_200

    if response.status_code == 401:
        response_401 = LegacyError.from_dict(response.json())

        return response_401

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[LegacyBillingAck | LegacyError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    ecosystem_id: str,
    *,
    client: AuthenticatedClient | Client,
    body: LegacyStripeWebhookEvent,
) -> Response[LegacyBillingAck | LegacyError]:
    """Stripe event receiver (HMAC over the raw body, not a JWT)

     The only writer of `billing.accounts`. The signature is computed over the EXACT raw bytes, so the
    body is read as text and never re-serialized. Every stored secret for the ecosystem is tried in
    turn, which is what makes a secret rotation a non-event.

    It STORES the event before it does anything that can fail, keyed uniquely on `(ecosystem_id,
    stripe_event_id)` — one Stripe account can serve two ecosystems under BYOK, so the Stripe event id
    alone is not a deduplication key. A replay of an already-stored event short-circuits to the same 200
    without re-applying it.

    Replaces POST /public/webhooks/stripe/{ecosystemId}.

    Args:
        ecosystem_id (str):
        body (LegacyStripeWebhookEvent):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[LegacyBillingAck | LegacyError]
    """

    kwargs = _get_kwargs(
        ecosystem_id=ecosystem_id,
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    ecosystem_id: str,
    *,
    client: AuthenticatedClient | Client,
    body: LegacyStripeWebhookEvent,
) -> LegacyBillingAck | LegacyError | None:
    """Stripe event receiver (HMAC over the raw body, not a JWT)

     The only writer of `billing.accounts`. The signature is computed over the EXACT raw bytes, so the
    body is read as text and never re-serialized. Every stored secret for the ecosystem is tried in
    turn, which is what makes a secret rotation a non-event.

    It STORES the event before it does anything that can fail, keyed uniquely on `(ecosystem_id,
    stripe_event_id)` — one Stripe account can serve two ecosystems under BYOK, so the Stripe event id
    alone is not a deduplication key. A replay of an already-stored event short-circuits to the same 200
    without re-applying it.

    Replaces POST /public/webhooks/stripe/{ecosystemId}.

    Args:
        ecosystem_id (str):
        body (LegacyStripeWebhookEvent):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        LegacyBillingAck | LegacyError
    """

    return sync_detailed(
        ecosystem_id=ecosystem_id,
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    ecosystem_id: str,
    *,
    client: AuthenticatedClient | Client,
    body: LegacyStripeWebhookEvent,
) -> Response[LegacyBillingAck | LegacyError]:
    """Stripe event receiver (HMAC over the raw body, not a JWT)

     The only writer of `billing.accounts`. The signature is computed over the EXACT raw bytes, so the
    body is read as text and never re-serialized. Every stored secret for the ecosystem is tried in
    turn, which is what makes a secret rotation a non-event.

    It STORES the event before it does anything that can fail, keyed uniquely on `(ecosystem_id,
    stripe_event_id)` — one Stripe account can serve two ecosystems under BYOK, so the Stripe event id
    alone is not a deduplication key. A replay of an already-stored event short-circuits to the same 200
    without re-applying it.

    Replaces POST /public/webhooks/stripe/{ecosystemId}.

    Args:
        ecosystem_id (str):
        body (LegacyStripeWebhookEvent):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[LegacyBillingAck | LegacyError]
    """

    kwargs = _get_kwargs(
        ecosystem_id=ecosystem_id,
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    ecosystem_id: str,
    *,
    client: AuthenticatedClient | Client,
    body: LegacyStripeWebhookEvent,
) -> LegacyBillingAck | LegacyError | None:
    """Stripe event receiver (HMAC over the raw body, not a JWT)

     The only writer of `billing.accounts`. The signature is computed over the EXACT raw bytes, so the
    body is read as text and never re-serialized. Every stored secret for the ecosystem is tried in
    turn, which is what makes a secret rotation a non-event.

    It STORES the event before it does anything that can fail, keyed uniquely on `(ecosystem_id,
    stripe_event_id)` — one Stripe account can serve two ecosystems under BYOK, so the Stripe event id
    alone is not a deduplication key. A replay of an already-stored event short-circuits to the same 200
    without re-applying it.

    Replaces POST /public/webhooks/stripe/{ecosystemId}.

    Args:
        ecosystem_id (str):
        body (LegacyStripeWebhookEvent):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        LegacyBillingAck | LegacyError
    """

    return (
        await asyncio_detailed(
            ecosystem_id=ecosystem_id,
            client=client,
            body=body,
        )
    ).parsed
