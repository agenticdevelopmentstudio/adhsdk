from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.get_v1_usage_insights_overview_interval import GetV1UsageInsightsOverviewInterval
from ...models.get_v1_usage_insights_overview_response_200 import (
    GetV1UsageInsightsOverviewResponse200,
)
from ...models.stripe_error import StripeError
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    from_: str,
    to: str,
    interval: GetV1UsageInsightsOverviewInterval | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["from"] = from_

    params["to"] = to

    json_interval: str | Unset = UNSET
    if not isinstance(interval, Unset):
        json_interval = interval.value

    params["interval"] = json_interval

    json_expand: list[str] | Unset = UNSET
    if not isinstance(expand, Unset):
        json_expand = expand

    params["expand[]"] = json_expand

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/v1/usage/insights/overview",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> GetV1UsageInsightsOverviewResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = GetV1UsageInsightsOverviewResponse200.from_dict(response.json())

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

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[GetV1UsageInsightsOverviewResponse200 | StripeError]:
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
    interval: GetV1UsageInsightsOverviewInterval | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1UsageInsightsOverviewResponse200 | StripeError]:
    """Platform usage and direct cost as a time series (admin)

     `from`..`to` are YYYY-MM-DD, both inclusive, at most 366 days — wider is a 400. One point per bucket
    the range touches, empty ones included.

    Replaces GET /usage/insight/overview.

    Args:
        from_ (str):
        to (str):
        interval (GetV1UsageInsightsOverviewInterval | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1UsageInsightsOverviewResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        from_=from_,
        to=to,
        interval=interval,
        expand=expand,
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
    interval: GetV1UsageInsightsOverviewInterval | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> GetV1UsageInsightsOverviewResponse200 | StripeError | None:
    """Platform usage and direct cost as a time series (admin)

     `from`..`to` are YYYY-MM-DD, both inclusive, at most 366 days — wider is a 400. One point per bucket
    the range touches, empty ones included.

    Replaces GET /usage/insight/overview.

    Args:
        from_ (str):
        to (str):
        interval (GetV1UsageInsightsOverviewInterval | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1UsageInsightsOverviewResponse200 | StripeError
    """

    return sync_detailed(
        client=client,
        from_=from_,
        to=to,
        interval=interval,
        expand=expand,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    from_: str,
    to: str,
    interval: GetV1UsageInsightsOverviewInterval | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1UsageInsightsOverviewResponse200 | StripeError]:
    """Platform usage and direct cost as a time series (admin)

     `from`..`to` are YYYY-MM-DD, both inclusive, at most 366 days — wider is a 400. One point per bucket
    the range touches, empty ones included.

    Replaces GET /usage/insight/overview.

    Args:
        from_ (str):
        to (str):
        interval (GetV1UsageInsightsOverviewInterval | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1UsageInsightsOverviewResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        from_=from_,
        to=to,
        interval=interval,
        expand=expand,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    from_: str,
    to: str,
    interval: GetV1UsageInsightsOverviewInterval | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> GetV1UsageInsightsOverviewResponse200 | StripeError | None:
    """Platform usage and direct cost as a time series (admin)

     `from`..`to` are YYYY-MM-DD, both inclusive, at most 366 days — wider is a 400. One point per bucket
    the range touches, empty ones included.

    Replaces GET /usage/insight/overview.

    Args:
        from_ (str):
        to (str):
        interval (GetV1UsageInsightsOverviewInterval | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1UsageInsightsOverviewResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            client=client,
            from_=from_,
            to=to,
            interval=interval,
            expand=expand,
        )
    ).parsed
