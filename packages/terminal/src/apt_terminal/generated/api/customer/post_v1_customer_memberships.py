from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.post_v1_customer_memberships_body import PostV1CustomerMembershipsBody
from ...models.post_v1_customer_memberships_response_200 import PostV1CustomerMembershipsResponse200
from ...models.stripe_error import StripeError
from ...types import Response


def _get_kwargs(
    *,
    body: PostV1CustomerMembershipsBody,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/customer_memberships",
    }

    _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostV1CustomerMembershipsResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = PostV1CustomerMembershipsResponse200.from_dict(response.json())

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
) -> Response[PostV1CustomerMembershipsResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    body: PostV1CustomerMembershipsBody,
) -> Response[PostV1CustomerMembershipsResponse200 | StripeError]:
    """Make this person a customer of another ecosystem too (admin)

     IDEMPOTENT: adding someone who is already a member reports the row they already had, with `created:
    false`. The new row takes its own slug — carrying the source slug over would collide with whoever
    holds it in the target, and a membership is not a claim on a handle. Refused with 400 for a customer
    who has no email, since nothing could ever tie the new row back to this person.

    Replaces POST /customer/memberships.

    Args:
        body (PostV1CustomerMembershipsBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1CustomerMembershipsResponse200 | StripeError]
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
    body: PostV1CustomerMembershipsBody,
) -> PostV1CustomerMembershipsResponse200 | StripeError | None:
    """Make this person a customer of another ecosystem too (admin)

     IDEMPOTENT: adding someone who is already a member reports the row they already had, with `created:
    false`. The new row takes its own slug — carrying the source slug over would collide with whoever
    holds it in the target, and a membership is not a claim on a handle. Refused with 400 for a customer
    who has no email, since nothing could ever tie the new row back to this person.

    Replaces POST /customer/memberships.

    Args:
        body (PostV1CustomerMembershipsBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1CustomerMembershipsResponse200 | StripeError
    """

    return sync_detailed(
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    body: PostV1CustomerMembershipsBody,
) -> Response[PostV1CustomerMembershipsResponse200 | StripeError]:
    """Make this person a customer of another ecosystem too (admin)

     IDEMPOTENT: adding someone who is already a member reports the row they already had, with `created:
    false`. The new row takes its own slug — carrying the source slug over would collide with whoever
    holds it in the target, and a membership is not a claim on a handle. Refused with 400 for a customer
    who has no email, since nothing could ever tie the new row back to this person.

    Replaces POST /customer/memberships.

    Args:
        body (PostV1CustomerMembershipsBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1CustomerMembershipsResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    body: PostV1CustomerMembershipsBody,
) -> PostV1CustomerMembershipsResponse200 | StripeError | None:
    """Make this person a customer of another ecosystem too (admin)

     IDEMPOTENT: adding someone who is already a member reports the row they already had, with `created:
    false`. The new row takes its own slug — carrying the source slug over would collide with whoever
    holds it in the target, and a membership is not a claim on a handle. Refused with 400 for a customer
    who has no email, since nothing could ever tie the new row back to this person.

    Replaces POST /customer/memberships.

    Args:
        body (PostV1CustomerMembershipsBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1CustomerMembershipsResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
        )
    ).parsed
