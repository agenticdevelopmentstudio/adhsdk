from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.post_v1_set_grants_response_201 import PostV1SetGrantsResponse201
from ...models.set_grant_create import SetGrantCreate
from ...models.stripe_error import StripeError
from ...types import UNSET, Response


def _get_kwargs(
    *,
    body: SetGrantCreate,
    ecosystem: str,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    params: dict[str, Any] = {}

    params["ecosystem"] = ecosystem

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/set_grants",
        "params": params,
    }

    _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostV1SetGrantsResponse201 | StripeError | None:
    if response.status_code == 201:
        response_201 = PostV1SetGrantsResponse201.from_dict(response.json())

        return response_201

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
) -> Response[PostV1SetGrantsResponse201 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    body: SetGrantCreate,
    ecosystem: str,
) -> Response[PostV1SetGrantsResponse201 | StripeError]:
    """Grant a set to a customer

     A direct grant. Refused (rule 4) when it conflicts with a set the customer holds; granting a set
    already held returns that grant.

    Replaces POST /sets/grants.

    Args:
        ecosystem (str):
        body (SetGrantCreate):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1SetGrantsResponse201 | StripeError]
    """

    kwargs = _get_kwargs(
        body=body,
        ecosystem=ecosystem,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    body: SetGrantCreate,
    ecosystem: str,
) -> PostV1SetGrantsResponse201 | StripeError | None:
    """Grant a set to a customer

     A direct grant. Refused (rule 4) when it conflicts with a set the customer holds; granting a set
    already held returns that grant.

    Replaces POST /sets/grants.

    Args:
        ecosystem (str):
        body (SetGrantCreate):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1SetGrantsResponse201 | StripeError
    """

    return sync_detailed(
        client=client,
        body=body,
        ecosystem=ecosystem,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    body: SetGrantCreate,
    ecosystem: str,
) -> Response[PostV1SetGrantsResponse201 | StripeError]:
    """Grant a set to a customer

     A direct grant. Refused (rule 4) when it conflicts with a set the customer holds; granting a set
    already held returns that grant.

    Replaces POST /sets/grants.

    Args:
        ecosystem (str):
        body (SetGrantCreate):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1SetGrantsResponse201 | StripeError]
    """

    kwargs = _get_kwargs(
        body=body,
        ecosystem=ecosystem,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    body: SetGrantCreate,
    ecosystem: str,
) -> PostV1SetGrantsResponse201 | StripeError | None:
    """Grant a set to a customer

     A direct grant. Refused (rule 4) when it conflicts with a set the customer holds; granting a set
    already held returns that grant.

    Replaces POST /sets/grants.

    Args:
        ecosystem (str):
        body (SetGrantCreate):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1SetGrantsResponse201 | StripeError
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
            ecosystem=ecosystem,
        )
    ).parsed
