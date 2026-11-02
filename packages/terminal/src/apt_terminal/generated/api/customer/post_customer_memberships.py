from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.post_customer_memberships_body import PostCustomerMembershipsBody
from ...models.post_customer_memberships_response_200 import PostCustomerMembershipsResponse200
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    body: PostCustomerMembershipsBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/customer/memberships",
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | PostCustomerMembershipsResponse200 | None:
    if response.status_code == 200:
        response_200 = PostCustomerMembershipsResponse200.from_dict(response.json())

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

    if response.status_code == 404:
        response_404 = Error.from_dict(response.json())

        return response_404

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | PostCustomerMembershipsResponse200]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    body: PostCustomerMembershipsBody | Unset = UNSET,
) -> Response[Error | PostCustomerMembershipsResponse200]:
    """Make this person a customer of another ecosystem too (admin)

     IDEMPOTENT: adding someone who is already a member reports the row they already had, with `created:
    false`. The new row takes its own slug — carrying the source slug over would collide with whoever
    holds it in the target, and a membership is not a claim on a handle. Refused with 400 for a customer
    who has no email, since nothing could ever tie the new row back to this person.

    Args:
        body (PostCustomerMembershipsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PostCustomerMembershipsResponse200]
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
    body: PostCustomerMembershipsBody | Unset = UNSET,
) -> Error | PostCustomerMembershipsResponse200 | None:
    """Make this person a customer of another ecosystem too (admin)

     IDEMPOTENT: adding someone who is already a member reports the row they already had, with `created:
    false`. The new row takes its own slug — carrying the source slug over would collide with whoever
    holds it in the target, and a membership is not a claim on a handle. Refused with 400 for a customer
    who has no email, since nothing could ever tie the new row back to this person.

    Args:
        body (PostCustomerMembershipsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PostCustomerMembershipsResponse200
    """

    return sync_detailed(
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    body: PostCustomerMembershipsBody | Unset = UNSET,
) -> Response[Error | PostCustomerMembershipsResponse200]:
    """Make this person a customer of another ecosystem too (admin)

     IDEMPOTENT: adding someone who is already a member reports the row they already had, with `created:
    false`. The new row takes its own slug — carrying the source slug over would collide with whoever
    holds it in the target, and a membership is not a claim on a handle. Refused with 400 for a customer
    who has no email, since nothing could ever tie the new row back to this person.

    Args:
        body (PostCustomerMembershipsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PostCustomerMembershipsResponse200]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    body: PostCustomerMembershipsBody | Unset = UNSET,
) -> Error | PostCustomerMembershipsResponse200 | None:
    """Make this person a customer of another ecosystem too (admin)

     IDEMPOTENT: adding someone who is already a member reports the row they already had, with `created:
    false`. The new row takes its own slug — carrying the source slug over would collide with whoever
    holds it in the target, and a membership is not a claim on a handle. Refused with 400 for a customer
    who has no email, since nothing could ever tie the new row back to this person.

    Args:
        body (PostCustomerMembershipsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PostCustomerMembershipsResponse200
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
        )
    ).parsed
