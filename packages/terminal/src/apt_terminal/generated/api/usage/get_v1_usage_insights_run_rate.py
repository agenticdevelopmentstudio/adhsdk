from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.get_v1_usage_insights_run_rate_response_200 import (
    GetV1UsageInsightsRunRateResponse200,
)
from ...models.stripe_error import StripeError
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    month: str,
    expand: list[str] | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["month"] = month

    json_expand: list[str] | Unset = UNSET
    if not isinstance(expand, Unset):
        json_expand = expand

    params["expand[]"] = json_expand

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/v1/usage/insights/run_rate",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> GetV1UsageInsightsRunRateResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = GetV1UsageInsightsRunRateResponse200.from_dict(response.json())

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
) -> Response[GetV1UsageInsightsRunRateResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    month: str,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1UsageInsightsRunRateResponse200 | StripeError]:
    """A month's run rate: direct to date, fixed, projected (admin)

     `month` is YYYY-MM; a future month is a 400. The current month counts its days through yesterday
    (UTC) — today is still being written.

    Replaces GET /usage/insight/run-rate.

    Args:
        month (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1UsageInsightsRunRateResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        month=month,
        expand=expand,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    month: str,
    expand: list[str] | Unset = UNSET,
) -> GetV1UsageInsightsRunRateResponse200 | StripeError | None:
    """A month's run rate: direct to date, fixed, projected (admin)

     `month` is YYYY-MM; a future month is a 400. The current month counts its days through yesterday
    (UTC) — today is still being written.

    Replaces GET /usage/insight/run-rate.

    Args:
        month (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1UsageInsightsRunRateResponse200 | StripeError
    """

    return sync_detailed(
        client=client,
        month=month,
        expand=expand,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    month: str,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1UsageInsightsRunRateResponse200 | StripeError]:
    """A month's run rate: direct to date, fixed, projected (admin)

     `month` is YYYY-MM; a future month is a 400. The current month counts its days through yesterday
    (UTC) — today is still being written.

    Replaces GET /usage/insight/run-rate.

    Args:
        month (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1UsageInsightsRunRateResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        month=month,
        expand=expand,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    month: str,
    expand: list[str] | Unset = UNSET,
) -> GetV1UsageInsightsRunRateResponse200 | StripeError | None:
    """A month's run rate: direct to date, fixed, projected (admin)

     `month` is YYYY-MM; a future month is a 400. The current month counts its days through yesterday
    (UTC) — today is still being written.

    Replaces GET /usage/insight/run-rate.

    Args:
        month (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1UsageInsightsRunRateResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            client=client,
            month=month,
            expand=expand,
        )
    ).parsed
