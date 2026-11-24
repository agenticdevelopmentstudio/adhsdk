from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.post_v1_auth_sms_codes_body import PostV1AuthSmsCodesBody
from ...models.post_v1_auth_sms_codes_response_202 import PostV1AuthSmsCodesResponse202
from ...models.stripe_error import StripeError
from ...types import Response


def _get_kwargs(
    *,
    body: PostV1AuthSmsCodesBody,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/auth/sms_codes",
    }

    _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostV1AuthSmsCodesResponse202 | StripeError | None:
    if response.status_code == 202:
        response_202 = PostV1AuthSmsCodesResponse202.from_dict(response.json())

        return response_202

    if response.status_code == 400:
        response_400 = StripeError.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = StripeError.from_dict(response.json())

        return response_401

    if response.status_code == 409:
        response_409 = StripeError.from_dict(response.json())

        return response_409

    if response.status_code == 422:
        response_422 = StripeError.from_dict(response.json())

        return response_422

    if response.status_code == 429:
        response_429 = StripeError.from_dict(response.json())

        return response_429

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[PostV1AuthSmsCodesResponse202 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient | Client,
    body: PostV1AuthSmsCodesBody,
) -> Response[PostV1AuthSmsCodesResponse202 | StripeError]:
    """Send the SMS login code to the verified primary phone

     Replaces POST /auth/login/mfa/sms/send.

    Args:
        body (PostV1AuthSmsCodesBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1AuthSmsCodesResponse202 | StripeError]
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
    client: AuthenticatedClient | Client,
    body: PostV1AuthSmsCodesBody,
) -> PostV1AuthSmsCodesResponse202 | StripeError | None:
    """Send the SMS login code to the verified primary phone

     Replaces POST /auth/login/mfa/sms/send.

    Args:
        body (PostV1AuthSmsCodesBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1AuthSmsCodesResponse202 | StripeError
    """

    return sync_detailed(
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient | Client,
    body: PostV1AuthSmsCodesBody,
) -> Response[PostV1AuthSmsCodesResponse202 | StripeError]:
    """Send the SMS login code to the verified primary phone

     Replaces POST /auth/login/mfa/sms/send.

    Args:
        body (PostV1AuthSmsCodesBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1AuthSmsCodesResponse202 | StripeError]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient | Client,
    body: PostV1AuthSmsCodesBody,
) -> PostV1AuthSmsCodesResponse202 | StripeError | None:
    """Send the SMS login code to the verified primary phone

     Replaces POST /auth/login/mfa/sms/send.

    Args:
        body (PostV1AuthSmsCodesBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1AuthSmsCodesResponse202 | StripeError
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
        )
    ).parsed
