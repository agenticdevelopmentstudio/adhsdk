from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.post_v1_auth_passkey_challenges_body import PostV1AuthPasskeyChallengesBody
from ...models.post_v1_auth_passkey_challenges_response_200 import (
    PostV1AuthPasskeyChallengesResponse200,
)
from ...models.stripe_error import StripeError
from ...types import Response


def _get_kwargs(
    *,
    body: PostV1AuthPasskeyChallengesBody,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/auth/passkey_challenges",
    }

    _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostV1AuthPasskeyChallengesResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = PostV1AuthPasskeyChallengesResponse200.from_dict(response.json())

        return response_200

    if response.status_code == 400:
        response_400 = StripeError.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = StripeError.from_dict(response.json())

        return response_401

    if response.status_code == 422:
        response_422 = StripeError.from_dict(response.json())

        return response_422

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[PostV1AuthPasskeyChallengesResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient | Client,
    body: PostV1AuthPasskeyChallengesBody,
) -> Response[PostV1AuthPasskeyChallengesResponse200 | StripeError]:
    """WebAuthn 2nd-factor: assertion options bound to the pending challenge

     Replaces POST /auth/login/mfa/webauthn/options, POST /auth/login/webauthn/options.

    Args:
        body (PostV1AuthPasskeyChallengesBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1AuthPasskeyChallengesResponse200 | StripeError]
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
    body: PostV1AuthPasskeyChallengesBody,
) -> PostV1AuthPasskeyChallengesResponse200 | StripeError | None:
    """WebAuthn 2nd-factor: assertion options bound to the pending challenge

     Replaces POST /auth/login/mfa/webauthn/options, POST /auth/login/webauthn/options.

    Args:
        body (PostV1AuthPasskeyChallengesBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1AuthPasskeyChallengesResponse200 | StripeError
    """

    return sync_detailed(
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient | Client,
    body: PostV1AuthPasskeyChallengesBody,
) -> Response[PostV1AuthPasskeyChallengesResponse200 | StripeError]:
    """WebAuthn 2nd-factor: assertion options bound to the pending challenge

     Replaces POST /auth/login/mfa/webauthn/options, POST /auth/login/webauthn/options.

    Args:
        body (PostV1AuthPasskeyChallengesBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1AuthPasskeyChallengesResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient | Client,
    body: PostV1AuthPasskeyChallengesBody,
) -> PostV1AuthPasskeyChallengesResponse200 | StripeError | None:
    """WebAuthn 2nd-factor: assertion options bound to the pending challenge

     Replaces POST /auth/login/mfa/webauthn/options, POST /auth/login/webauthn/options.

    Args:
        body (PostV1AuthPasskeyChallengesBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1AuthPasskeyChallengesResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
        )
    ).parsed
