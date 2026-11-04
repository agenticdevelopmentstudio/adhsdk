from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.usage_insight_run_rate import UsageInsightRunRate
from ...types import UNSET, Response


def _get_kwargs(
    *,
    month: str,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["month"] = month

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/usage/insight/run-rate",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | UsageInsightRunRate | None:
    if response.status_code == 200:
        response_200 = UsageInsightRunRate.from_dict(response.json())

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
) -> Response[Error | UsageInsightRunRate]:
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
) -> Response[Error | UsageInsightRunRate]:
    """A month's run rate: direct to date, fixed, projected (admin)

     `month` is YYYY-MM; a future month is a 400. The current month counts its days through yesterday
    (UTC) — today is still being written.

    Args:
        month (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | UsageInsightRunRate]
    """

    kwargs = _get_kwargs(
        month=month,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    month: str,
) -> Error | UsageInsightRunRate | None:
    """A month's run rate: direct to date, fixed, projected (admin)

     `month` is YYYY-MM; a future month is a 400. The current month counts its days through yesterday
    (UTC) — today is still being written.

    Args:
        month (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | UsageInsightRunRate
    """

    return sync_detailed(
        client=client,
        month=month,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    month: str,
) -> Response[Error | UsageInsightRunRate]:
    """A month's run rate: direct to date, fixed, projected (admin)

     `month` is YYYY-MM; a future month is a 400. The current month counts its days through yesterday
    (UTC) — today is still being written.

    Args:
        month (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | UsageInsightRunRate]
    """

    kwargs = _get_kwargs(
        month=month,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    month: str,
) -> Error | UsageInsightRunRate | None:
    """A month's run rate: direct to date, fixed, projected (admin)

     `month` is YYYY-MM; a future month is a 400. The current month counts its days through yesterday
    (UTC) — today is still being written.

    Args:
        month (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | UsageInsightRunRate
    """

    return (
        await asyncio_detailed(
            client=client,
            month=month,
        )
    ).parsed
