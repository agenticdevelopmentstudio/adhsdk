from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.get_v1_usage_enforcement_response_200 import GetV1UsageEnforcementResponse200
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
        "url": "/v1/usage/enforcement",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> GetV1UsageEnforcementResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = GetV1UsageEnforcementResponse200.from_dict(response.json())

        return response_200

    if response.status_code == 401:
        response_401 = StripeError.from_dict(response.json())

        return response_401

    if response.status_code == 403:
        response_403 = StripeError.from_dict(response.json())

        return response_403

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[GetV1UsageEnforcementResponse200 | StripeError]:
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
) -> Response[GetV1UsageEnforcementResponse200 | StripeError]:
    """Effective usage-enforcement switch + pricing knobs (admin)

     The global kill switch above every tier’s `quota_enforced`, with the input that decided it:
    `USAGE_ENFORCEMENT_ENABLED` wins when set, otherwise the `usage_enforcement` row in
    `system.feature_flags` (absent ⇒ off). Also reports the environment-only pricing and retention
    knobs, which govern what enforcement charges once it bites, plus the visitor floor’s two daily
    budgets — the only caps that refuse whatever `enabled` says. Writes go to `/system/feature-flags` —
    POST when `flag` is null, PUT `/{flag.id}` otherwise.

    Replaces GET /usage/enforcement.

    Args:
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1UsageEnforcementResponse200 | StripeError]
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
) -> GetV1UsageEnforcementResponse200 | StripeError | None:
    """Effective usage-enforcement switch + pricing knobs (admin)

     The global kill switch above every tier’s `quota_enforced`, with the input that decided it:
    `USAGE_ENFORCEMENT_ENABLED` wins when set, otherwise the `usage_enforcement` row in
    `system.feature_flags` (absent ⇒ off). Also reports the environment-only pricing and retention
    knobs, which govern what enforcement charges once it bites, plus the visitor floor’s two daily
    budgets — the only caps that refuse whatever `enabled` says. Writes go to `/system/feature-flags` —
    POST when `flag` is null, PUT `/{flag.id}` otherwise.

    Replaces GET /usage/enforcement.

    Args:
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1UsageEnforcementResponse200 | StripeError
    """

    return sync_detailed(
        client=client,
        expand=expand,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1UsageEnforcementResponse200 | StripeError]:
    """Effective usage-enforcement switch + pricing knobs (admin)

     The global kill switch above every tier’s `quota_enforced`, with the input that decided it:
    `USAGE_ENFORCEMENT_ENABLED` wins when set, otherwise the `usage_enforcement` row in
    `system.feature_flags` (absent ⇒ off). Also reports the environment-only pricing and retention
    knobs, which govern what enforcement charges once it bites, plus the visitor floor’s two daily
    budgets — the only caps that refuse whatever `enabled` says. Writes go to `/system/feature-flags` —
    POST when `flag` is null, PUT `/{flag.id}` otherwise.

    Replaces GET /usage/enforcement.

    Args:
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1UsageEnforcementResponse200 | StripeError]
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
) -> GetV1UsageEnforcementResponse200 | StripeError | None:
    """Effective usage-enforcement switch + pricing knobs (admin)

     The global kill switch above every tier’s `quota_enforced`, with the input that decided it:
    `USAGE_ENFORCEMENT_ENABLED` wins when set, otherwise the `usage_enforcement` row in
    `system.feature_flags` (absent ⇒ off). Also reports the environment-only pricing and retention
    knobs, which govern what enforcement charges once it bites, plus the visitor floor’s two daily
    budgets — the only caps that refuse whatever `enabled` says. Writes go to `/system/feature-flags` —
    POST when `flag` is null, PUT `/{flag.id}` otherwise.

    Replaces GET /usage/enforcement.

    Args:
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1UsageEnforcementResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            client=client,
            expand=expand,
        )
    ).parsed
