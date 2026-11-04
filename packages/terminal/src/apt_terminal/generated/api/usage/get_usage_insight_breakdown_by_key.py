from http import HTTPStatus
from typing import Any
from urllib.parse import quote
from uuid import UUID

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.get_usage_insight_breakdown_by_key_by import GetUsageInsightBreakdownByKeyBy
from ...models.usage_insight_breakdown_detail import UsageInsightBreakdownDetail
from ...types import UNSET, Response


def _get_kwargs(
    by: GetUsageInsightBreakdownByKeyBy,
    key: UUID,
    *,
    from_: str,
    to: str,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["from"] = from_

    params["to"] = to

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/usage/insight/breakdown/{by}/{key}".format(
            by=quote(str(by), safe=""),
            key=quote(str(key), safe=""),
        ),
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | UsageInsightBreakdownDetail | None:
    if response.status_code == 200:
        response_200 = UsageInsightBreakdownDetail.from_dict(response.json())

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
) -> Response[Error | UsageInsightBreakdownDetail]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    by: GetUsageInsightBreakdownByKeyBy,
    key: UUID,
    *,
    client: AuthenticatedClient,
    from_: str,
    to: str,
) -> Response[Error | UsageInsightBreakdownDetail]:
    """One breakdown key's items and daily trend (admin)

     `from`..`to` are YYYY-MM-DD, both inclusive, at most 366 days — wider is a 400.

    Args:
        by (GetUsageInsightBreakdownByKeyBy):
        key (UUID):
        from_ (str):
        to (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | UsageInsightBreakdownDetail]
    """

    kwargs = _get_kwargs(
        by=by,
        key=key,
        from_=from_,
        to=to,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    by: GetUsageInsightBreakdownByKeyBy,
    key: UUID,
    *,
    client: AuthenticatedClient,
    from_: str,
    to: str,
) -> Error | UsageInsightBreakdownDetail | None:
    """One breakdown key's items and daily trend (admin)

     `from`..`to` are YYYY-MM-DD, both inclusive, at most 366 days — wider is a 400.

    Args:
        by (GetUsageInsightBreakdownByKeyBy):
        key (UUID):
        from_ (str):
        to (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | UsageInsightBreakdownDetail
    """

    return sync_detailed(
        by=by,
        key=key,
        client=client,
        from_=from_,
        to=to,
    ).parsed


async def asyncio_detailed(
    by: GetUsageInsightBreakdownByKeyBy,
    key: UUID,
    *,
    client: AuthenticatedClient,
    from_: str,
    to: str,
) -> Response[Error | UsageInsightBreakdownDetail]:
    """One breakdown key's items and daily trend (admin)

     `from`..`to` are YYYY-MM-DD, both inclusive, at most 366 days — wider is a 400.

    Args:
        by (GetUsageInsightBreakdownByKeyBy):
        key (UUID):
        from_ (str):
        to (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | UsageInsightBreakdownDetail]
    """

    kwargs = _get_kwargs(
        by=by,
        key=key,
        from_=from_,
        to=to,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    by: GetUsageInsightBreakdownByKeyBy,
    key: UUID,
    *,
    client: AuthenticatedClient,
    from_: str,
    to: str,
) -> Error | UsageInsightBreakdownDetail | None:
    """One breakdown key's items and daily trend (admin)

     `from`..`to` are YYYY-MM-DD, both inclusive, at most 366 days — wider is a 400.

    Args:
        by (GetUsageInsightBreakdownByKeyBy):
        key (UUID):
        from_ (str):
        to (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | UsageInsightBreakdownDetail
    """

    return (
        await asyncio_detailed(
            by=by,
            key=key,
            client=client,
            from_=from_,
            to=to,
        )
    ).parsed
