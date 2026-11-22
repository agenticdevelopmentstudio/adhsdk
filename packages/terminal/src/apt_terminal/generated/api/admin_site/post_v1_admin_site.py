from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.admin_site_put import AdminSitePut
from ...models.post_v1_admin_site_response_200 import PostV1AdminSiteResponse200
from ...models.stripe_error import StripeError
from ...types import Response


def _get_kwargs(
    *,
    body: AdminSitePut,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/admin_site",
    }

    _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostV1AdminSiteResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = PostV1AdminSiteResponse200.from_dict(response.json())

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

    if response.status_code == 409:
        response_409 = StripeError.from_dict(response.json())

        return response_409

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[PostV1AdminSiteResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    body: AdminSitePut,
) -> Response[PostV1AdminSiteResponse200 | StripeError]:
    """Set up or move a product's admin site

     Makes (or reuses, or revives) the product's staff `admin-site` application and gives it a login
    registration whose one return origin is `https://<host>` and whose one redirect is
    `https://<host>/auth/callback`. 409 when the product has its own `admin-site` application, or
    another product's site already uses the host.

    Replaces PUT /ecosystem/admin-site.

    Args:
        body (AdminSitePut):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1AdminSiteResponse200 | StripeError]
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
    body: AdminSitePut,
) -> PostV1AdminSiteResponse200 | StripeError | None:
    """Set up or move a product's admin site

     Makes (or reuses, or revives) the product's staff `admin-site` application and gives it a login
    registration whose one return origin is `https://<host>` and whose one redirect is
    `https://<host>/auth/callback`. 409 when the product has its own `admin-site` application, or
    another product's site already uses the host.

    Replaces PUT /ecosystem/admin-site.

    Args:
        body (AdminSitePut):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1AdminSiteResponse200 | StripeError
    """

    return sync_detailed(
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    body: AdminSitePut,
) -> Response[PostV1AdminSiteResponse200 | StripeError]:
    """Set up or move a product's admin site

     Makes (or reuses, or revives) the product's staff `admin-site` application and gives it a login
    registration whose one return origin is `https://<host>` and whose one redirect is
    `https://<host>/auth/callback`. 409 when the product has its own `admin-site` application, or
    another product's site already uses the host.

    Replaces PUT /ecosystem/admin-site.

    Args:
        body (AdminSitePut):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1AdminSiteResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    body: AdminSitePut,
) -> PostV1AdminSiteResponse200 | StripeError | None:
    """Set up or move a product's admin site

     Makes (or reuses, or revives) the product's staff `admin-site` application and gives it a login
    registration whose one return origin is `https://<host>` and whose one redirect is
    `https://<host>/auth/callback`. 409 when the product has its own `admin-site` application, or
    another product's site already uses the host.

    Replaces PUT /ecosystem/admin-site.

    Args:
        body (AdminSitePut):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1AdminSiteResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
        )
    ).parsed
