from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.usage_enforcement import UsageEnforcement
from ...types import Response


def _get_kwargs() -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/usage/enforcement",
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | UsageEnforcement | None:
    if response.status_code == 200:
        response_200 = UsageEnforcement.from_dict(response.json())

        return response_200

    if response.status_code == 401:
        response_401 = Error.from_dict(response.json())

        return response_401

    if response.status_code == 403:
        response_403 = Error.from_dict(response.json())

        return response_403

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | UsageEnforcement]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
) -> Response[Error | UsageEnforcement]:
    """Effective usage-enforcement switch + pricing knobs (admin)

     The global kill switch above every tier’s `quota_enforced`, with the input that decided it:
    `USAGE_ENFORCEMENT_ENABLED` wins when set, otherwise the `usage_enforcement` row in
    `system.feature_flags` (absent ⇒ off). Also reports the environment-only pricing and retention
    knobs, which govern what enforcement charges once it bites, plus the visitor floor’s two daily
    budgets — the only caps that refuse whatever `enabled` says. Writes go to `/system/feature-flags` —
    POST when `flag` is null, PUT `/{flag.id}` otherwise.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | UsageEnforcement]
    """

    kwargs = _get_kwargs()

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
) -> Error | UsageEnforcement | None:
    """Effective usage-enforcement switch + pricing knobs (admin)

     The global kill switch above every tier’s `quota_enforced`, with the input that decided it:
    `USAGE_ENFORCEMENT_ENABLED` wins when set, otherwise the `usage_enforcement` row in
    `system.feature_flags` (absent ⇒ off). Also reports the environment-only pricing and retention
    knobs, which govern what enforcement charges once it bites, plus the visitor floor’s two daily
    budgets — the only caps that refuse whatever `enabled` says. Writes go to `/system/feature-flags` —
    POST when `flag` is null, PUT `/{flag.id}` otherwise.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | UsageEnforcement
    """

    return sync_detailed(
        client=client,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
) -> Response[Error | UsageEnforcement]:
    """Effective usage-enforcement switch + pricing knobs (admin)

     The global kill switch above every tier’s `quota_enforced`, with the input that decided it:
    `USAGE_ENFORCEMENT_ENABLED` wins when set, otherwise the `usage_enforcement` row in
    `system.feature_flags` (absent ⇒ off). Also reports the environment-only pricing and retention
    knobs, which govern what enforcement charges once it bites, plus the visitor floor’s two daily
    budgets — the only caps that refuse whatever `enabled` says. Writes go to `/system/feature-flags` —
    POST when `flag` is null, PUT `/{flag.id}` otherwise.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | UsageEnforcement]
    """

    kwargs = _get_kwargs()

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
) -> Error | UsageEnforcement | None:
    """Effective usage-enforcement switch + pricing knobs (admin)

     The global kill switch above every tier’s `quota_enforced`, with the input that decided it:
    `USAGE_ENFORCEMENT_ENABLED` wins when set, otherwise the `usage_enforcement` row in
    `system.feature_flags` (absent ⇒ off). Also reports the environment-only pricing and retention
    knobs, which govern what enforcement charges once it bites, plus the visitor floor’s two daily
    budgets — the only caps that refuse whatever `enabled` says. Writes go to `/system/feature-flags` —
    POST when `flag` is null, PUT `/{flag.id}` otherwise.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | UsageEnforcement
    """

    return (
        await asyncio_detailed(
            client=client,
        )
    ).parsed
