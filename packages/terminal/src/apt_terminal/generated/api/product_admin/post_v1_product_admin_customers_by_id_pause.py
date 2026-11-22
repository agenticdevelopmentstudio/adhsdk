from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.post_v1_product_admin_customers_by_id_pause_response_200 import (
    PostV1ProductAdminCustomersByIdPauseResponse200,
)
from ...models.product_customer_pause import ProductCustomerPause
from ...models.stripe_error import StripeError
from ...types import Response


def _get_kwargs(
    id: str,
    *,
    body: ProductCustomerPause,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/product_admin/customers/{id}/pause".format(
            id=quote(str(id), safe=""),
        ),
    }

    _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostV1ProductAdminCustomersByIdPauseResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = PostV1ProductAdminCustomersByIdPauseResponse200.from_dict(response.json())

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

    if response.status_code == 404:
        response_404 = StripeError.from_dict(response.json())

        return response_404

    if response.status_code == 422:
        response_422 = StripeError.from_dict(response.json())

        return response_422

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[PostV1ProductAdminCustomersByIdPauseResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
    body: ProductCustomerPause,
) -> Response[PostV1ProductAdminCustomersByIdPauseResponse200 | StripeError]:
    """Pause a customer

     Refuses their sign-in and every request from the next one, and revokes their sign-in sessions. 422
    for the caller or another admin.

    Replaces POST /product-admin/customers/{id}/pause.

    Args:
        id (str):
        body (ProductCustomerPause):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1ProductAdminCustomersByIdPauseResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    *,
    client: AuthenticatedClient,
    body: ProductCustomerPause,
) -> PostV1ProductAdminCustomersByIdPauseResponse200 | StripeError | None:
    """Pause a customer

     Refuses their sign-in and every request from the next one, and revokes their sign-in sessions. 422
    for the caller or another admin.

    Replaces POST /product-admin/customers/{id}/pause.

    Args:
        id (str):
        body (ProductCustomerPause):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1ProductAdminCustomersByIdPauseResponse200 | StripeError
    """

    return sync_detailed(
        id=id,
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
    body: ProductCustomerPause,
) -> Response[PostV1ProductAdminCustomersByIdPauseResponse200 | StripeError]:
    """Pause a customer

     Refuses their sign-in and every request from the next one, and revokes their sign-in sessions. 422
    for the caller or another admin.

    Replaces POST /product-admin/customers/{id}/pause.

    Args:
        id (str):
        body (ProductCustomerPause):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1ProductAdminCustomersByIdPauseResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    *,
    client: AuthenticatedClient,
    body: ProductCustomerPause,
) -> PostV1ProductAdminCustomersByIdPauseResponse200 | StripeError | None:
    """Pause a customer

     Refuses their sign-in and every request from the next one, and revokes their sign-in sessions. 422
    for the caller or another admin.

    Replaces POST /product-admin/customers/{id}/pause.

    Args:
        id (str):
        body (ProductCustomerPause):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1ProductAdminCustomersByIdPauseResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            body=body,
        )
    ).parsed
