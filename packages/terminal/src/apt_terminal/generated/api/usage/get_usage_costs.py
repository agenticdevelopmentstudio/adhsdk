from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.get_usage_costs_category import GetUsageCostsCategory
from ...models.get_usage_costs_group_by import GetUsageCostsGroupBy
from ...models.get_usage_costs_paid_by import GetUsageCostsPaidBy
from ...models.usage_cost_report import UsageCostReport
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    from_: str,
    to: str,
    ecosystem_id: str | Unset = UNSET,
    category: GetUsageCostsCategory | Unset = UNSET,
    provider: str | Unset = UNSET,
    paid_by: GetUsageCostsPaidBy | Unset = UNSET,
    group_by: GetUsageCostsGroupBy | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["from"] = from_

    params["to"] = to

    params["ecosystemId"] = ecosystem_id

    json_category: str | Unset = UNSET
    if not isinstance(category, Unset):
        json_category = category.value

    params["category"] = json_category

    params["provider"] = provider

    json_paid_by: str | Unset = UNSET
    if not isinstance(paid_by, Unset):
        json_paid_by = paid_by.value

    params["paidBy"] = json_paid_by

    json_group_by: str | Unset = UNSET
    if not isinstance(group_by, Unset):
        json_group_by = group_by.value

    params["groupBy"] = json_group_by

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/usage/costs",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | UsageCostReport | None:
    if response.status_code == 200:
        response_200 = UsageCostReport.from_dict(response.json())

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

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | UsageCostReport]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    from_: str,
    to: str,
    ecosystem_id: str | Unset = UNSET,
    category: GetUsageCostsCategory | Unset = UNSET,
    provider: str | Unset = UNSET,
    paid_by: GetUsageCostsPaidBy | Unset = UNSET,
    group_by: GetUsageCostsGroupBy | Unset = UNSET,
) -> Response[Error | UsageCostReport]:
    """Cost report from the daily rollup (admin)

     Sums `usage.cost_daily` over `from`..`to` (both inclusive, at most 366 days — wider is a 400), one
    row per day or per spend key. Money is integer µUSD; a non-zero `unpricedLines` means `costMicros`
    is a floor. `ecosystemId=platform` selects platform-level spend (the nil uuid key).

    Args:
        from_ (str):
        to (str):
        ecosystem_id (str | Unset):
        category (GetUsageCostsCategory | Unset):
        provider (str | Unset):
        paid_by (GetUsageCostsPaidBy | Unset):
        group_by (GetUsageCostsGroupBy | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | UsageCostReport]
    """

    kwargs = _get_kwargs(
        from_=from_,
        to=to,
        ecosystem_id=ecosystem_id,
        category=category,
        provider=provider,
        paid_by=paid_by,
        group_by=group_by,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    from_: str,
    to: str,
    ecosystem_id: str | Unset = UNSET,
    category: GetUsageCostsCategory | Unset = UNSET,
    provider: str | Unset = UNSET,
    paid_by: GetUsageCostsPaidBy | Unset = UNSET,
    group_by: GetUsageCostsGroupBy | Unset = UNSET,
) -> Error | UsageCostReport | None:
    """Cost report from the daily rollup (admin)

     Sums `usage.cost_daily` over `from`..`to` (both inclusive, at most 366 days — wider is a 400), one
    row per day or per spend key. Money is integer µUSD; a non-zero `unpricedLines` means `costMicros`
    is a floor. `ecosystemId=platform` selects platform-level spend (the nil uuid key).

    Args:
        from_ (str):
        to (str):
        ecosystem_id (str | Unset):
        category (GetUsageCostsCategory | Unset):
        provider (str | Unset):
        paid_by (GetUsageCostsPaidBy | Unset):
        group_by (GetUsageCostsGroupBy | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | UsageCostReport
    """

    return sync_detailed(
        client=client,
        from_=from_,
        to=to,
        ecosystem_id=ecosystem_id,
        category=category,
        provider=provider,
        paid_by=paid_by,
        group_by=group_by,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    from_: str,
    to: str,
    ecosystem_id: str | Unset = UNSET,
    category: GetUsageCostsCategory | Unset = UNSET,
    provider: str | Unset = UNSET,
    paid_by: GetUsageCostsPaidBy | Unset = UNSET,
    group_by: GetUsageCostsGroupBy | Unset = UNSET,
) -> Response[Error | UsageCostReport]:
    """Cost report from the daily rollup (admin)

     Sums `usage.cost_daily` over `from`..`to` (both inclusive, at most 366 days — wider is a 400), one
    row per day or per spend key. Money is integer µUSD; a non-zero `unpricedLines` means `costMicros`
    is a floor. `ecosystemId=platform` selects platform-level spend (the nil uuid key).

    Args:
        from_ (str):
        to (str):
        ecosystem_id (str | Unset):
        category (GetUsageCostsCategory | Unset):
        provider (str | Unset):
        paid_by (GetUsageCostsPaidBy | Unset):
        group_by (GetUsageCostsGroupBy | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | UsageCostReport]
    """

    kwargs = _get_kwargs(
        from_=from_,
        to=to,
        ecosystem_id=ecosystem_id,
        category=category,
        provider=provider,
        paid_by=paid_by,
        group_by=group_by,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    from_: str,
    to: str,
    ecosystem_id: str | Unset = UNSET,
    category: GetUsageCostsCategory | Unset = UNSET,
    provider: str | Unset = UNSET,
    paid_by: GetUsageCostsPaidBy | Unset = UNSET,
    group_by: GetUsageCostsGroupBy | Unset = UNSET,
) -> Error | UsageCostReport | None:
    """Cost report from the daily rollup (admin)

     Sums `usage.cost_daily` over `from`..`to` (both inclusive, at most 366 days — wider is a 400), one
    row per day or per spend key. Money is integer µUSD; a non-zero `unpricedLines` means `costMicros`
    is a floor. `ecosystemId=platform` selects platform-level spend (the nil uuid key).

    Args:
        from_ (str):
        to (str):
        ecosystem_id (str | Unset):
        category (GetUsageCostsCategory | Unset):
        provider (str | Unset):
        paid_by (GetUsageCostsPaidBy | Unset):
        group_by (GetUsageCostsGroupBy | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | UsageCostReport
    """

    return (
        await asyncio_detailed(
            client=client,
            from_=from_,
            to=to,
            ecosystem_id=ecosystem_id,
            category=category,
            provider=provider,
            paid_by=paid_by,
            group_by=group_by,
        )
    ).parsed
