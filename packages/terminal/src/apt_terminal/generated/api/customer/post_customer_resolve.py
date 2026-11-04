from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.customer_resolve_result import CustomerResolveResult
from ...models.error import Error
from ...models.post_customer_resolve_body import PostCustomerResolveBody
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    body: PostCustomerResolveBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/customer/resolve",
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> CustomerResolveResult | Error | None:
    if response.status_code == 200:
        response_200 = CustomerResolveResult.from_dict(response.json())

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

    if response.status_code == 409:
        response_409 = Error.from_dict(response.json())

        return response_409

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[CustomerResolveResult | Error]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    body: PostCustomerResolveBody | Unset = UNSET,
) -> Response[CustomerResolveResult | Error]:
    """Map one of the caller's external user ids onto a stable ADH customerId (BYO bridge)

    Args:
        body (PostCustomerResolveBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[CustomerResolveResult | Error]
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
    body: PostCustomerResolveBody | Unset = UNSET,
) -> CustomerResolveResult | Error | None:
    """Map one of the caller's external user ids onto a stable ADH customerId (BYO bridge)

    Args:
        body (PostCustomerResolveBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        CustomerResolveResult | Error
    """

    return sync_detailed(
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    body: PostCustomerResolveBody | Unset = UNSET,
) -> Response[CustomerResolveResult | Error]:
    """Map one of the caller's external user ids onto a stable ADH customerId (BYO bridge)

    Args:
        body (PostCustomerResolveBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[CustomerResolveResult | Error]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    body: PostCustomerResolveBody | Unset = UNSET,
) -> CustomerResolveResult | Error | None:
    """Map one of the caller's external user ids onto a stable ADH customerId (BYO bridge)

    Args:
        body (PostCustomerResolveBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        CustomerResolveResult | Error
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
        )
    ).parsed
