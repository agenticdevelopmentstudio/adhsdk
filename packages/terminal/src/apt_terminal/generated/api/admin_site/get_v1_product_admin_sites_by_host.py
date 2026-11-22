from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.get_v1_product_admin_sites_by_host_response_200 import (
    GetV1ProductAdminSitesByHostResponse200,
)
from ...models.stripe_error import StripeError
from ...types import UNSET, Response, Unset


def _get_kwargs(
    host: str,
    *,
    expand: list[str] | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    json_expand: list[str] | Unset = UNSET
    if not isinstance(expand, Unset):
        json_expand = expand

    params["expand[]"] = json_expand

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/v1/product_admin_sites/{host}".format(
            host=quote(str(host), safe=""),
        ),
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> GetV1ProductAdminSitesByHostResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = GetV1ProductAdminSitesByHostResponse200.from_dict(response.json())

        return response_200

    if response.status_code == 404:
        response_404 = StripeError.from_dict(response.json())

        return response_404

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[GetV1ProductAdminSitesByHostResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    host: str,
    *,
    client: AuthenticatedClient | Client,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1ProductAdminSitesByHostResponse200 | StripeError]:
    """Which product an admin site host belongs to (unauthenticated)

     Replaces GET /public/product-admin-sites/{host}.

    Args:
        host (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1ProductAdminSitesByHostResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        host=host,
        expand=expand,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    host: str,
    *,
    client: AuthenticatedClient | Client,
    expand: list[str] | Unset = UNSET,
) -> GetV1ProductAdminSitesByHostResponse200 | StripeError | None:
    """Which product an admin site host belongs to (unauthenticated)

     Replaces GET /public/product-admin-sites/{host}.

    Args:
        host (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1ProductAdminSitesByHostResponse200 | StripeError
    """

    return sync_detailed(
        host=host,
        client=client,
        expand=expand,
    ).parsed


async def asyncio_detailed(
    host: str,
    *,
    client: AuthenticatedClient | Client,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1ProductAdminSitesByHostResponse200 | StripeError]:
    """Which product an admin site host belongs to (unauthenticated)

     Replaces GET /public/product-admin-sites/{host}.

    Args:
        host (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1ProductAdminSitesByHostResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        host=host,
        expand=expand,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    host: str,
    *,
    client: AuthenticatedClient | Client,
    expand: list[str] | Unset = UNSET,
) -> GetV1ProductAdminSitesByHostResponse200 | StripeError | None:
    """Which product an admin site host belongs to (unauthenticated)

     Replaces GET /public/product-admin-sites/{host}.

    Args:
        host (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1ProductAdminSitesByHostResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            host=host,
            client=client,
            expand=expand,
        )
    ).parsed
