from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.get_usage_insight_breakdown_by import GetUsageInsightBreakdownBy
from ...models.get_usage_insight_breakdown_sort import GetUsageInsightBreakdownSort
from ...models.usage_insight_breakdown import UsageInsightBreakdown
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    from_: str,
    to: str,
    by: GetUsageInsightBreakdownBy,
    sort: GetUsageInsightBreakdownSort | Unset = UNSET,
    limit: int | Unset = 50,
    offset: int | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["from"] = from_

    params["to"] = to

    json_by = by.value
    params["by"] = json_by

    json_sort: str | Unset = UNSET
    if not isinstance(sort, Unset):
        json_sort = sort.value

    params["sort"] = json_sort

    params["limit"] = limit

    params["offset"] = offset

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/usage/insight/breakdown",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | UsageInsightBreakdown | None:
    if response.status_code == 200:
        response_200 = UsageInsightBreakdown.from_dict(response.json())

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
) -> Response[Error | UsageInsightBreakdown]:
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
    by: GetUsageInsightBreakdownBy,
    sort: GetUsageInsightBreakdownSort | Unset = UNSET,
    limit: int | Unset = 50,
    offset: int | Unset = UNSET,
) -> Response[Error | UsageInsightBreakdown]:
    """Usage and cost per organization, ecosystem, user or persona (admin)

     `from`..`to` are YYYY-MM-DD, both inclusive, at most 366 days — wider is a 400. One row per key; a
    persona call on a user's behalf counts under both. `limit` is 1–200 (default 50).

    Args:
        from_ (str):
        to (str):
        by (GetUsageInsightBreakdownBy):
        sort (GetUsageInsightBreakdownSort | Unset):
        limit (int | Unset):  Default: 50.
        offset (int | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | UsageInsightBreakdown]
    """

    kwargs = _get_kwargs(
        from_=from_,
        to=to,
        by=by,
        sort=sort,
        limit=limit,
        offset=offset,
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
    by: GetUsageInsightBreakdownBy,
    sort: GetUsageInsightBreakdownSort | Unset = UNSET,
    limit: int | Unset = 50,
    offset: int | Unset = UNSET,
) -> Error | UsageInsightBreakdown | None:
    """Usage and cost per organization, ecosystem, user or persona (admin)

     `from`..`to` are YYYY-MM-DD, both inclusive, at most 366 days — wider is a 400. One row per key; a
    persona call on a user's behalf counts under both. `limit` is 1–200 (default 50).

    Args:
        from_ (str):
        to (str):
        by (GetUsageInsightBreakdownBy):
        sort (GetUsageInsightBreakdownSort | Unset):
        limit (int | Unset):  Default: 50.
        offset (int | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | UsageInsightBreakdown
    """

    return sync_detailed(
        client=client,
        from_=from_,
        to=to,
        by=by,
        sort=sort,
        limit=limit,
        offset=offset,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    from_: str,
    to: str,
    by: GetUsageInsightBreakdownBy,
    sort: GetUsageInsightBreakdownSort | Unset = UNSET,
    limit: int | Unset = 50,
    offset: int | Unset = UNSET,
) -> Response[Error | UsageInsightBreakdown]:
    """Usage and cost per organization, ecosystem, user or persona (admin)

     `from`..`to` are YYYY-MM-DD, both inclusive, at most 366 days — wider is a 400. One row per key; a
    persona call on a user's behalf counts under both. `limit` is 1–200 (default 50).

    Args:
        from_ (str):
        to (str):
        by (GetUsageInsightBreakdownBy):
        sort (GetUsageInsightBreakdownSort | Unset):
        limit (int | Unset):  Default: 50.
        offset (int | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | UsageInsightBreakdown]
    """

    kwargs = _get_kwargs(
        from_=from_,
        to=to,
        by=by,
        sort=sort,
        limit=limit,
        offset=offset,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    from_: str,
    to: str,
    by: GetUsageInsightBreakdownBy,
    sort: GetUsageInsightBreakdownSort | Unset = UNSET,
    limit: int | Unset = 50,
    offset: int | Unset = UNSET,
) -> Error | UsageInsightBreakdown | None:
    """Usage and cost per organization, ecosystem, user or persona (admin)

     `from`..`to` are YYYY-MM-DD, both inclusive, at most 366 days — wider is a 400. One row per key; a
    persona call on a user's behalf counts under both. `limit` is 1–200 (default 50).

    Args:
        from_ (str):
        to (str):
        by (GetUsageInsightBreakdownBy):
        sort (GetUsageInsightBreakdownSort | Unset):
        limit (int | Unset):  Default: 50.
        offset (int | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | UsageInsightBreakdown
    """

    return (
        await asyncio_detailed(
            client=client,
            from_=from_,
            to=to,
            by=by,
            sort=sort,
            limit=limit,
            offset=offset,
        )
    ).parsed
