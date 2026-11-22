from http import HTTPStatus
from typing import Any, cast
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.get_v1_set_grants_effective_by_customer_id_response_200_type_0 import (
    GetV1SetGrantsEffectiveByCustomerIdResponse200Type0,
)
from ...models.stripe_error import StripeError
from ...types import UNSET, Response, Unset


def _get_kwargs(
    customer_id: str,
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
        "url": "/v1/set_grants/effective/{customer_id}".format(
            customer_id=quote(str(customer_id), safe=""),
        ),
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> GetV1SetGrantsEffectiveByCustomerIdResponse200Type0 | None | StripeError | None:
    if response.status_code == 200:

        def _parse_response_200(
            data: object,
        ) -> GetV1SetGrantsEffectiveByCustomerIdResponse200Type0 | None:
            if data is None:
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                response_200_type_0 = GetV1SetGrantsEffectiveByCustomerIdResponse200Type0.from_dict(
                    data
                )

                return response_200_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(GetV1SetGrantsEffectiveByCustomerIdResponse200Type0 | None, data)

        response_200 = _parse_response_200(response.json())

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

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[GetV1SetGrantsEffectiveByCustomerIdResponse200Type0 | None | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    customer_id: str,
    *,
    client: AuthenticatedClient,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1SetGrantsEffectiveByCustomerIdResponse200Type0 | None | StripeError]:
    """Read a customer's effective sets

     Replaces GET /sets/effective/{customerId}.

    Args:
        customer_id (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1SetGrantsEffectiveByCustomerIdResponse200Type0 | None | StripeError]
    """

    kwargs = _get_kwargs(
        customer_id=customer_id,
        expand=expand,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    customer_id: str,
    *,
    client: AuthenticatedClient,
    expand: list[str] | Unset = UNSET,
) -> GetV1SetGrantsEffectiveByCustomerIdResponse200Type0 | None | StripeError | None:
    """Read a customer's effective sets

     Replaces GET /sets/effective/{customerId}.

    Args:
        customer_id (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1SetGrantsEffectiveByCustomerIdResponse200Type0 | None | StripeError
    """

    return sync_detailed(
        customer_id=customer_id,
        client=client,
        expand=expand,
    ).parsed


async def asyncio_detailed(
    customer_id: str,
    *,
    client: AuthenticatedClient,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1SetGrantsEffectiveByCustomerIdResponse200Type0 | None | StripeError]:
    """Read a customer's effective sets

     Replaces GET /sets/effective/{customerId}.

    Args:
        customer_id (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1SetGrantsEffectiveByCustomerIdResponse200Type0 | None | StripeError]
    """

    kwargs = _get_kwargs(
        customer_id=customer_id,
        expand=expand,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    customer_id: str,
    *,
    client: AuthenticatedClient,
    expand: list[str] | Unset = UNSET,
) -> GetV1SetGrantsEffectiveByCustomerIdResponse200Type0 | None | StripeError | None:
    """Read a customer's effective sets

     Replaces GET /sets/effective/{customerId}.

    Args:
        customer_id (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1SetGrantsEffectiveByCustomerIdResponse200Type0 | None | StripeError
    """

    return (
        await asyncio_detailed(
            customer_id=customer_id,
            client=client,
            expand=expand,
        )
    ).parsed
