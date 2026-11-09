from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.post_v1_usage_fixed_costs_by_id_response_200 import (
    PostV1UsageFixedCostsByIdResponse200,
)
from ...models.stripe_error import StripeError
from ...models.usage_fixed_cost_patch import UsageFixedCostPatch
from ...types import Response


def _get_kwargs(
    id: str,
    *,
    body: UsageFixedCostPatch,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/usage/fixed_costs/{id}".format(
            id=quote(str(id), safe=""),
        ),
    }

    _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostV1UsageFixedCostsByIdResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = PostV1UsageFixedCostsByIdResponse200.from_dict(response.json())

        return response_200

    if response.status_code == 400:
        response_400 = StripeError.from_dict(response.json())

        return response_400

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
) -> Response[PostV1UsageFixedCostsByIdResponse200 | StripeError]:
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
    body: UsageFixedCostPatch,
) -> Response[PostV1UsageFixedCostsByIdResponse200 | StripeError]:
    """End, annotate or (before it starts) edit a fixed cost (admin)

     `effectiveTo` (inclusive; may be in the past — the correction path for a mistaken open row), `label`
    and `note` may always change. `monthlyMicros` and `effectiveFrom` only while `effectiveFrom` is
    today (UTC) or later, else 409 `a fixed cost already in effect is immutable except to end it or
    annotate it — end it and add a new row`. `effectiveTo` before `effectiveFrom` is a 400.

    Replaces PATCH /usage/fixed-costs/{id}.

    Args:
        id (str):
        body (UsageFixedCostPatch):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1UsageFixedCostsByIdResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    *,
    client: AuthenticatedClient,
    body: UsageFixedCostPatch,
) -> PostV1UsageFixedCostsByIdResponse200 | StripeError | None:
    """End, annotate or (before it starts) edit a fixed cost (admin)

     `effectiveTo` (inclusive; may be in the past — the correction path for a mistaken open row), `label`
    and `note` may always change. `monthlyMicros` and `effectiveFrom` only while `effectiveFrom` is
    today (UTC) or later, else 409 `a fixed cost already in effect is immutable except to end it or
    annotate it — end it and add a new row`. `effectiveTo` before `effectiveFrom` is a 400.

    Replaces PATCH /usage/fixed-costs/{id}.

    Args:
        id (str):
        body (UsageFixedCostPatch):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1UsageFixedCostsByIdResponse200 | StripeError
    """

    return sync_detailed(
        id=id,
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
    body: UsageFixedCostPatch,
) -> Response[PostV1UsageFixedCostsByIdResponse200 | StripeError]:
    """End, annotate or (before it starts) edit a fixed cost (admin)

     `effectiveTo` (inclusive; may be in the past — the correction path for a mistaken open row), `label`
    and `note` may always change. `monthlyMicros` and `effectiveFrom` only while `effectiveFrom` is
    today (UTC) or later, else 409 `a fixed cost already in effect is immutable except to end it or
    annotate it — end it and add a new row`. `effectiveTo` before `effectiveFrom` is a 400.

    Replaces PATCH /usage/fixed-costs/{id}.

    Args:
        id (str):
        body (UsageFixedCostPatch):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1UsageFixedCostsByIdResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    *,
    client: AuthenticatedClient,
    body: UsageFixedCostPatch,
) -> PostV1UsageFixedCostsByIdResponse200 | StripeError | None:
    """End, annotate or (before it starts) edit a fixed cost (admin)

     `effectiveTo` (inclusive; may be in the past — the correction path for a mistaken open row), `label`
    and `note` may always change. `monthlyMicros` and `effectiveFrom` only while `effectiveFrom` is
    today (UTC) or later, else 409 `a fixed cost already in effect is immutable except to end it or
    annotate it — end it and add a new row`. `effectiveTo` before `effectiveFrom` is a 400.

    Replaces PATCH /usage/fixed-costs/{id}.

    Args:
        id (str):
        body (UsageFixedCostPatch):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1UsageFixedCostsByIdResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            body=body,
        )
    ).parsed
