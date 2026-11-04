from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.usage_insight_items import UsageInsightItems
from ...types import UNSET, Response


def _get_kwargs(
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
        "url": "/usage/insight/items",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | UsageInsightItems | None:
    if response.status_code == 200:
        response_200 = UsageInsightItems.from_dict(response.json())

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
) -> Response[Error | UsageInsightItems]:
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
) -> Response[Error | UsageInsightItems]:
    """Every cost item seen in a range, priced (admin)

     `from`..`to` are YYYY-MM-DD, both inclusive, at most 366 days — wider is a 400. Sorted by cost,
    highest first; unpriced items sort below priced ones.

    Args:
        from_ (str):
        to (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | UsageInsightItems]
    """

    kwargs = _get_kwargs(
        from_=from_,
        to=to,
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
) -> Error | UsageInsightItems | None:
    """Every cost item seen in a range, priced (admin)

     `from`..`to` are YYYY-MM-DD, both inclusive, at most 366 days — wider is a 400. Sorted by cost,
    highest first; unpriced items sort below priced ones.

    Args:
        from_ (str):
        to (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | UsageInsightItems
    """

    return sync_detailed(
        client=client,
        from_=from_,
        to=to,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    from_: str,
    to: str,
) -> Response[Error | UsageInsightItems]:
    """Every cost item seen in a range, priced (admin)

     `from`..`to` are YYYY-MM-DD, both inclusive, at most 366 days — wider is a 400. Sorted by cost,
    highest first; unpriced items sort below priced ones.

    Args:
        from_ (str):
        to (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | UsageInsightItems]
    """

    kwargs = _get_kwargs(
        from_=from_,
        to=to,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    from_: str,
    to: str,
) -> Error | UsageInsightItems | None:
    """Every cost item seen in a range, priced (admin)

     `from`..`to` are YYYY-MM-DD, both inclusive, at most 366 days — wider is a 400. Sorted by cost,
    highest first; unpriced items sort below priced ones.

    Args:
        from_ (str):
        to (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | UsageInsightItems
    """

    return (
        await asyncio_detailed(
            client=client,
            from_=from_,
            to=to,
        )
    ).parsed
