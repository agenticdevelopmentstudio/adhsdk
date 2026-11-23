from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.post_v1_public_support_grants_by_id_approve_code_response_202 import (
    PostV1PublicSupportGrantsByIdApproveCodeResponse202,
)
from ...models.stripe_error import StripeError
from ...models.support_link_token import SupportLinkToken
from ...types import Response


def _get_kwargs(
    id: str,
    *,
    body: SupportLinkToken,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/public/support/grants/{id}/approve/code".format(
            id=quote(str(id), safe=""),
        ),
    }

    _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostV1PublicSupportGrantsByIdApproveCodeResponse202 | StripeError | None:
    if response.status_code == 202:
        response_202 = PostV1PublicSupportGrantsByIdApproveCodeResponse202.from_dict(
            response.json()
        )

        return response_202

    if response.status_code == 400:
        response_400 = StripeError.from_dict(response.json())

        return response_400

    if response.status_code == 404:
        response_404 = StripeError.from_dict(response.json())

        return response_404

    if response.status_code == 409:
        response_409 = StripeError.from_dict(response.json())

        return response_409

    if response.status_code == 410:
        response_410 = StripeError.from_dict(response.json())

        return response_410

    if response.status_code == 422:
        response_422 = StripeError.from_dict(response.json())

        return response_422

    if response.status_code == 429:
        response_429 = StripeError.from_dict(response.json())

        return response_429

    if response.status_code == 500:
        response_500 = StripeError.from_dict(response.json())

        return response_500

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[PostV1PublicSupportGrantsByIdApproveCodeResponse202 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    id: str,
    *,
    client: AuthenticatedClient | Client,
    body: SupportLinkToken,
) -> Response[PostV1PublicSupportGrantsByIdApproveCodeResponse202 | StripeError]:
    """Email a code that approves a support request

     The code goes to the target's primary verified email. 429 within 30 seconds of the last code; 422
    when there is no verified email or the send failed. 409 `decided` once decided or revoked; 410
    `lapsed` for a request not decided within seven days.

    Replaces POST /public/support/grants/{id}/approve/code.

    Args:
        id (str):
        body (SupportLinkToken):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1PublicSupportGrantsByIdApproveCodeResponse202 | StripeError]
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
    client: AuthenticatedClient | Client,
    body: SupportLinkToken,
) -> PostV1PublicSupportGrantsByIdApproveCodeResponse202 | StripeError | None:
    """Email a code that approves a support request

     The code goes to the target's primary verified email. 429 within 30 seconds of the last code; 422
    when there is no verified email or the send failed. 409 `decided` once decided or revoked; 410
    `lapsed` for a request not decided within seven days.

    Replaces POST /public/support/grants/{id}/approve/code.

    Args:
        id (str):
        body (SupportLinkToken):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1PublicSupportGrantsByIdApproveCodeResponse202 | StripeError
    """

    return sync_detailed(
        id=id,
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient | Client,
    body: SupportLinkToken,
) -> Response[PostV1PublicSupportGrantsByIdApproveCodeResponse202 | StripeError]:
    """Email a code that approves a support request

     The code goes to the target's primary verified email. 429 within 30 seconds of the last code; 422
    when there is no verified email or the send failed. 409 `decided` once decided or revoked; 410
    `lapsed` for a request not decided within seven days.

    Replaces POST /public/support/grants/{id}/approve/code.

    Args:
        id (str):
        body (SupportLinkToken):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1PublicSupportGrantsByIdApproveCodeResponse202 | StripeError]
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
    client: AuthenticatedClient | Client,
    body: SupportLinkToken,
) -> PostV1PublicSupportGrantsByIdApproveCodeResponse202 | StripeError | None:
    """Email a code that approves a support request

     The code goes to the target's primary verified email. 429 within 30 seconds of the last code; 422
    when there is no verified email or the send failed. 409 `decided` once decided or revoked; 410
    `lapsed` for a request not decided within seven days.

    Replaces POST /public/support/grants/{id}/approve/code.

    Args:
        id (str):
        body (SupportLinkToken):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1PublicSupportGrantsByIdApproveCodeResponse202 | StripeError
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            body=body,
        )
    ).parsed
