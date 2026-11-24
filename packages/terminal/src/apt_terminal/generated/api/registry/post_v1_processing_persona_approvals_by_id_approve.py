from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.post_v1_processing_persona_approvals_by_id_approve_response_200 import (
    PostV1ProcessingPersonaApprovalsByIdApproveResponse200,
)
from ...models.stripe_error import StripeError
from ...types import Response


def _get_kwargs(
    id: str,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/processing/persona_approvals/{id}/approve".format(
            id=quote(str(id), safe=""),
        ),
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostV1ProcessingPersonaApprovalsByIdApproveResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = PostV1ProcessingPersonaApprovalsByIdApproveResponse200.from_dict(
            response.json()
        )

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
) -> Response[PostV1ProcessingPersonaApprovalsByIdApproveResponse200 | StripeError]:
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
) -> Response[PostV1ProcessingPersonaApprovalsByIdApproveResponse200 | StripeError]:
    """Approve a parked action — runs it in the original acting context

     Replaces POST /processing/personas/approvals/{id}/approve.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1ProcessingPersonaApprovalsByIdApproveResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    *,
    client: AuthenticatedClient,
) -> PostV1ProcessingPersonaApprovalsByIdApproveResponse200 | StripeError | None:
    """Approve a parked action — runs it in the original acting context

     Replaces POST /processing/personas/approvals/{id}/approve.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1ProcessingPersonaApprovalsByIdApproveResponse200 | StripeError
    """

    return sync_detailed(
        id=id,
        client=client,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
) -> Response[PostV1ProcessingPersonaApprovalsByIdApproveResponse200 | StripeError]:
    """Approve a parked action — runs it in the original acting context

     Replaces POST /processing/personas/approvals/{id}/approve.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1ProcessingPersonaApprovalsByIdApproveResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    *,
    client: AuthenticatedClient,
) -> PostV1ProcessingPersonaApprovalsByIdApproveResponse200 | StripeError | None:
    """Approve a parked action — runs it in the original acting context

     Replaces POST /processing/personas/approvals/{id}/approve.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1ProcessingPersonaApprovalsByIdApproveResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
        )
    ).parsed
