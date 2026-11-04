from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.usage_rate import UsageRate
from ...models.usage_rate_create import UsageRateCreate
from ...types import Response


def _get_kwargs(
    *,
    body: UsageRateCreate,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/usage/rates",
    }

    _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | UsageRate | None:
    if response.status_code == 201:
        response_201 = UsageRate.from_dict(response.json())

        return response_201

    if response.status_code == 400:
        response_400 = Error.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = Error.from_dict(response.json())

        return response_401

    if response.status_code == 403:
        response_403 = Error.from_dict(response.json())

        return response_403

    if response.status_code == 409:
        response_409 = Error.from_dict(response.json())

        return response_409

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | UsageRate]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    body: UsageRateCreate,
) -> Response[Error | UsageRate]:
    """Add a price (admin)

     A price change is a new row from the day it takes effect. `microsPerUnit` is exact decimal text. 409
    when a rate for that item, quantity key and start day exists.

    Args:
        body (UsageRateCreate):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | UsageRate]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    body: UsageRateCreate,
) -> Error | UsageRate | None:
    """Add a price (admin)

     A price change is a new row from the day it takes effect. `microsPerUnit` is exact decimal text. 409
    when a rate for that item, quantity key and start day exists.

    Args:
        body (UsageRateCreate):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | UsageRate
    """

    return sync_detailed(
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    body: UsageRateCreate,
) -> Response[Error | UsageRate]:
    """Add a price (admin)

     A price change is a new row from the day it takes effect. `microsPerUnit` is exact decimal text. 409
    when a rate for that item, quantity key and start day exists.

    Args:
        body (UsageRateCreate):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | UsageRate]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    body: UsageRateCreate,
) -> Error | UsageRate | None:
    """Add a price (admin)

     A price change is a new row from the day it takes effect. `microsPerUnit` is exact decimal text. 409
    when a rate for that item, quantity key and start day exists.

    Args:
        body (UsageRateCreate):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | UsageRate
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
        )
    ).parsed
