from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.post_v1_support_grants_response_201 import PostV1SupportGrantsResponse201
from ...models.stripe_error import StripeError
from ...models.support_grant_request import SupportGrantRequest
from ...types import Response


def _get_kwargs(
    *,
    body: SupportGrantRequest,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/support/grants",
    }

    _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostV1SupportGrantsResponse201 | StripeError | None:
    if response.status_code == 201:
        response_201 = PostV1SupportGrantsResponse201.from_dict(response.json())

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

    if response.status_code == 409:
        response_409 = StripeError.from_dict(response.json())

        return response_409

    if response.status_code == 422:
        response_422 = StripeError.from_dict(response.json())

        return response_422

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[PostV1SupportGrantsResponse201 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    body: SupportGrantRequest,
) -> Response[PostV1SupportGrantsResponse201 | StripeError]:
    """Ask a customer for consent to read their content

     Product admins only. Needs a second factor from a sign-in in the last ten minutes: 403 with
    `error.code` `step_up_required` otherwise. 403 `not_target` for someone who is not a live customer
    of the product; 409 `exists` while a live grant for the pair stands.

    Replaces POST /support/grants.

    Args:
        body (SupportGrantRequest):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1SupportGrantsResponse201 | StripeError]
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
    body: SupportGrantRequest,
) -> PostV1SupportGrantsResponse201 | StripeError | None:
    """Ask a customer for consent to read their content

     Product admins only. Needs a second factor from a sign-in in the last ten minutes: 403 with
    `error.code` `step_up_required` otherwise. 403 `not_target` for someone who is not a live customer
    of the product; 409 `exists` while a live grant for the pair stands.

    Replaces POST /support/grants.

    Args:
        body (SupportGrantRequest):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1SupportGrantsResponse201 | StripeError
    """

    return sync_detailed(
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    body: SupportGrantRequest,
) -> Response[PostV1SupportGrantsResponse201 | StripeError]:
    """Ask a customer for consent to read their content

     Product admins only. Needs a second factor from a sign-in in the last ten minutes: 403 with
    `error.code` `step_up_required` otherwise. 403 `not_target` for someone who is not a live customer
    of the product; 409 `exists` while a live grant for the pair stands.

    Replaces POST /support/grants.

    Args:
        body (SupportGrantRequest):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1SupportGrantsResponse201 | StripeError]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    body: SupportGrantRequest,
) -> PostV1SupportGrantsResponse201 | StripeError | None:
    """Ask a customer for consent to read their content

     Product admins only. Needs a second factor from a sign-in in the last ten minutes: 403 with
    `error.code` `step_up_required` otherwise. 403 `not_target` for someone who is not a live customer
    of the product; 409 `exists` while a live grant for the pair stands.

    Replaces POST /support/grants.

    Args:
        body (SupportGrantRequest):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1SupportGrantsResponse201 | StripeError
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
        )
    ).parsed
