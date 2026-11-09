from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.get_v1_usage_insights_breakdown_response_200 import (
    GetV1UsageInsightsBreakdownResponse200,
)
from ...models.get_v1_usage_insights_breakdown_sort import GetV1UsageInsightsBreakdownSort
from ...models.stripe_error import StripeError
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    by: str | Unset = UNSET,
    key: str | Unset = UNSET,
    from_: str,
    to: str,
    sort: GetV1UsageInsightsBreakdownSort | Unset = UNSET,
    limit: int | Unset = 50,
    offset: int | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["by"] = by

    params["key"] = key

    params["from"] = from_

    params["to"] = to

    json_sort: str | Unset = UNSET
    if not isinstance(sort, Unset):
        json_sort = sort.value

    params["sort"] = json_sort

    params["limit"] = limit

    params["offset"] = offset

    json_expand: list[str] | Unset = UNSET
    if not isinstance(expand, Unset):
        json_expand = expand

    params["expand[]"] = json_expand

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/v1/usage/insights/breakdown",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> GetV1UsageInsightsBreakdownResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = GetV1UsageInsightsBreakdownResponse200.from_dict(response.json())

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
) -> Response[GetV1UsageInsightsBreakdownResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    by: str | Unset = UNSET,
    key: str | Unset = UNSET,
    from_: str,
    to: str,
    sort: GetV1UsageInsightsBreakdownSort | Unset = UNSET,
    limit: int | Unset = 50,
    offset: int | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1UsageInsightsBreakdownResponse200 | StripeError]:
    """Usage and cost per organization, ecosystem, user or persona (admin)

     `from`..`to` are YYYY-MM-DD, both inclusive, at most 366 days — wider is a 400. One row per key; a
    persona call on a user's behalf counts under both. `limit` is 1–200 (default 50).

    Replaces GET /usage/insight/breakdown, GET /usage/insight/breakdown/{by}/{key}.

    Args:
        by (str | Unset):
        key (str | Unset):
        from_ (str):
        to (str):
        sort (GetV1UsageInsightsBreakdownSort | Unset):
        limit (int | Unset):  Default: 50.
        offset (int | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1UsageInsightsBreakdownResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        by=by,
        key=key,
        from_=from_,
        to=to,
        sort=sort,
        limit=limit,
        offset=offset,
        expand=expand,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    by: str | Unset = UNSET,
    key: str | Unset = UNSET,
    from_: str,
    to: str,
    sort: GetV1UsageInsightsBreakdownSort | Unset = UNSET,
    limit: int | Unset = 50,
    offset: int | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> GetV1UsageInsightsBreakdownResponse200 | StripeError | None:
    """Usage and cost per organization, ecosystem, user or persona (admin)

     `from`..`to` are YYYY-MM-DD, both inclusive, at most 366 days — wider is a 400. One row per key; a
    persona call on a user's behalf counts under both. `limit` is 1–200 (default 50).

    Replaces GET /usage/insight/breakdown, GET /usage/insight/breakdown/{by}/{key}.

    Args:
        by (str | Unset):
        key (str | Unset):
        from_ (str):
        to (str):
        sort (GetV1UsageInsightsBreakdownSort | Unset):
        limit (int | Unset):  Default: 50.
        offset (int | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1UsageInsightsBreakdownResponse200 | StripeError
    """

    return sync_detailed(
        client=client,
        by=by,
        key=key,
        from_=from_,
        to=to,
        sort=sort,
        limit=limit,
        offset=offset,
        expand=expand,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    by: str | Unset = UNSET,
    key: str | Unset = UNSET,
    from_: str,
    to: str,
    sort: GetV1UsageInsightsBreakdownSort | Unset = UNSET,
    limit: int | Unset = 50,
    offset: int | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1UsageInsightsBreakdownResponse200 | StripeError]:
    """Usage and cost per organization, ecosystem, user or persona (admin)

     `from`..`to` are YYYY-MM-DD, both inclusive, at most 366 days — wider is a 400. One row per key; a
    persona call on a user's behalf counts under both. `limit` is 1–200 (default 50).

    Replaces GET /usage/insight/breakdown, GET /usage/insight/breakdown/{by}/{key}.

    Args:
        by (str | Unset):
        key (str | Unset):
        from_ (str):
        to (str):
        sort (GetV1UsageInsightsBreakdownSort | Unset):
        limit (int | Unset):  Default: 50.
        offset (int | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1UsageInsightsBreakdownResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        by=by,
        key=key,
        from_=from_,
        to=to,
        sort=sort,
        limit=limit,
        offset=offset,
        expand=expand,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    by: str | Unset = UNSET,
    key: str | Unset = UNSET,
    from_: str,
    to: str,
    sort: GetV1UsageInsightsBreakdownSort | Unset = UNSET,
    limit: int | Unset = 50,
    offset: int | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> GetV1UsageInsightsBreakdownResponse200 | StripeError | None:
    """Usage and cost per organization, ecosystem, user or persona (admin)

     `from`..`to` are YYYY-MM-DD, both inclusive, at most 366 days — wider is a 400. One row per key; a
    persona call on a user's behalf counts under both. `limit` is 1–200 (default 50).

    Replaces GET /usage/insight/breakdown, GET /usage/insight/breakdown/{by}/{key}.

    Args:
        by (str | Unset):
        key (str | Unset):
        from_ (str):
        to (str):
        sort (GetV1UsageInsightsBreakdownSort | Unset):
        limit (int | Unset):  Default: 50.
        offset (int | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1UsageInsightsBreakdownResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            client=client,
            by=by,
            key=key,
            from_=from_,
            to=to,
            sort=sort,
            limit=limit,
            offset=offset,
            expand=expand,
        )
    ).parsed
