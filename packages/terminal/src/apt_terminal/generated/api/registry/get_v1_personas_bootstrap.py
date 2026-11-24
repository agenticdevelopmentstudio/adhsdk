from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.get_v1_personas_bootstrap_response_200 import GetV1PersonasBootstrapResponse200
from ...models.stripe_error import StripeError
from ...types import UNSET, Response, Unset


def _get_kwargs(
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
        "url": "/v1/personas/bootstrap",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> GetV1PersonasBootstrapResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = GetV1PersonasBootstrapResponse200.from_dict(response.json())

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

    if response.status_code == 503:
        response_503 = StripeError.from_dict(response.json())

        return response_503

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[GetV1PersonasBootstrapResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1PersonasBootstrapResponse200 | StripeError]:
    """Everything a persona implementation needs to start, from its token alone

     Requires a persona or visitor API token (`tmp_…`) in the Authorization header — NOT a user session
    JWT, which is a 400, and not an application token, which is a 403. The token identifies the persona;
    there is nothing to pass.

    A visitor token gets the same shape with the anonymous floor applied: no tools, no memory, read-only
    buckets, and the public conversation URL. If the persona has since been made non-public, a visitor
    token stops working (403) even though it has not expired.

    Replaces GET /persona/bootstrap.

    Args:
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1PersonasBootstrapResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        expand=expand,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    expand: list[str] | Unset = UNSET,
) -> GetV1PersonasBootstrapResponse200 | StripeError | None:
    """Everything a persona implementation needs to start, from its token alone

     Requires a persona or visitor API token (`tmp_…`) in the Authorization header — NOT a user session
    JWT, which is a 400, and not an application token, which is a 403. The token identifies the persona;
    there is nothing to pass.

    A visitor token gets the same shape with the anonymous floor applied: no tools, no memory, read-only
    buckets, and the public conversation URL. If the persona has since been made non-public, a visitor
    token stops working (403) even though it has not expired.

    Replaces GET /persona/bootstrap.

    Args:
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1PersonasBootstrapResponse200 | StripeError
    """

    return sync_detailed(
        client=client,
        expand=expand,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1PersonasBootstrapResponse200 | StripeError]:
    """Everything a persona implementation needs to start, from its token alone

     Requires a persona or visitor API token (`tmp_…`) in the Authorization header — NOT a user session
    JWT, which is a 400, and not an application token, which is a 403. The token identifies the persona;
    there is nothing to pass.

    A visitor token gets the same shape with the anonymous floor applied: no tools, no memory, read-only
    buckets, and the public conversation URL. If the persona has since been made non-public, a visitor
    token stops working (403) even though it has not expired.

    Replaces GET /persona/bootstrap.

    Args:
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1PersonasBootstrapResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        expand=expand,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    expand: list[str] | Unset = UNSET,
) -> GetV1PersonasBootstrapResponse200 | StripeError | None:
    """Everything a persona implementation needs to start, from its token alone

     Requires a persona or visitor API token (`tmp_…`) in the Authorization header — NOT a user session
    JWT, which is a 400, and not an application token, which is a 403. The token identifies the persona;
    there is nothing to pass.

    A visitor token gets the same shape with the anonymous floor applied: no tools, no memory, read-only
    buckets, and the public conversation URL. If the persona has since been made non-public, a visitor
    token stops working (403) even though it has not expired.

    Replaces GET /persona/bootstrap.

    Args:
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1PersonasBootstrapResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            client=client,
            expand=expand,
        )
    ).parsed
