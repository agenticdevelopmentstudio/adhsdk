from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.get_v1_billing_context_response_200 import GetV1BillingContextResponse200
from ...models.stripe_error import StripeError
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    expand: list[str] | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    json_expand: list[str] | Unset = UNSET
    if not isinstance(expand, Unset):
        json_expand = expand

    params["expand[]"] = json_expand

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/v1/billing/context",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> GetV1BillingContextResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = GetV1BillingContextResponse200.from_dict(response.json())

        return response_200

    if response.status_code == 401:
        response_401 = StripeError.from_dict(response.json())

        return response_401

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[GetV1BillingContextResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1BillingContextResponse200 | StripeError]:
    """What a billing UI needs before it can draw a control

     The one billing route that is NOT behind `requireBillingOperator`, and deliberately so: that gate
    answers 404 when the ecosystem’s `billing` flag is off — which is precisely the state an operator is
    trying to leave — so every other route here is invisible to the person who has to turn it on.

    It leaks nothing that gate protects. `ecosystemId` is the caller’s own acting scope, which their
    token already carries; the rest are facts ABOUT that scope, not rows from it. A non-owner gets
    `canManage: false` and a UI with no controls, rather than a 404 that would read as a claim about the
    product rather than about the reader.

    `ecosystemId` comes from `actingIdentity(principal)` and is by construction the same id
    `/billing/accounts`, `/billing/prices`, `/billing/events` and the redrive scope to. A browser cannot
    derive it, which is why this route exists at all.

    Replaces GET /billing/context.

    Args:
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1BillingContextResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        expand=expand,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    expand: list[str] | Unset = UNSET,
) -> GetV1BillingContextResponse200 | StripeError | None:
    """What a billing UI needs before it can draw a control

     The one billing route that is NOT behind `requireBillingOperator`, and deliberately so: that gate
    answers 404 when the ecosystem’s `billing` flag is off — which is precisely the state an operator is
    trying to leave — so every other route here is invisible to the person who has to turn it on.

    It leaks nothing that gate protects. `ecosystemId` is the caller’s own acting scope, which their
    token already carries; the rest are facts ABOUT that scope, not rows from it. A non-owner gets
    `canManage: false` and a UI with no controls, rather than a 404 that would read as a claim about the
    product rather than about the reader.

    `ecosystemId` comes from `actingIdentity(principal)` and is by construction the same id
    `/billing/accounts`, `/billing/prices`, `/billing/events` and the redrive scope to. A browser cannot
    derive it, which is why this route exists at all.

    Replaces GET /billing/context.

    Args:
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1BillingContextResponse200 | StripeError
    """

    return sync_detailed(
        client=client,
        expand=expand,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1BillingContextResponse200 | StripeError]:
    """What a billing UI needs before it can draw a control

     The one billing route that is NOT behind `requireBillingOperator`, and deliberately so: that gate
    answers 404 when the ecosystem’s `billing` flag is off — which is precisely the state an operator is
    trying to leave — so every other route here is invisible to the person who has to turn it on.

    It leaks nothing that gate protects. `ecosystemId` is the caller’s own acting scope, which their
    token already carries; the rest are facts ABOUT that scope, not rows from it. A non-owner gets
    `canManage: false` and a UI with no controls, rather than a 404 that would read as a claim about the
    product rather than about the reader.

    `ecosystemId` comes from `actingIdentity(principal)` and is by construction the same id
    `/billing/accounts`, `/billing/prices`, `/billing/events` and the redrive scope to. A browser cannot
    derive it, which is why this route exists at all.

    Replaces GET /billing/context.

    Args:
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1BillingContextResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        expand=expand,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    expand: list[str] | Unset = UNSET,
) -> GetV1BillingContextResponse200 | StripeError | None:
    """What a billing UI needs before it can draw a control

     The one billing route that is NOT behind `requireBillingOperator`, and deliberately so: that gate
    answers 404 when the ecosystem’s `billing` flag is off — which is precisely the state an operator is
    trying to leave — so every other route here is invisible to the person who has to turn it on.

    It leaks nothing that gate protects. `ecosystemId` is the caller’s own acting scope, which their
    token already carries; the rest are facts ABOUT that scope, not rows from it. A non-owner gets
    `canManage: false` and a UI with no controls, rather than a 404 that would read as a claim about the
    product rather than about the reader.

    `ecosystemId` comes from `actingIdentity(principal)` and is by construction the same id
    `/billing/accounts`, `/billing/prices`, `/billing/events` and the redrive scope to. A browser cannot
    derive it, which is why this route exists at all.

    Replaces GET /billing/context.

    Args:
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1BillingContextResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            client=client,
            expand=expand,
        )
    ).parsed
