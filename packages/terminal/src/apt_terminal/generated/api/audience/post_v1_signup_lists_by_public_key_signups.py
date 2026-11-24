from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.post_v1_signup_lists_by_public_key_signups_body import (
    PostV1SignupListsByPublicKeySignupsBody,
)
from ...models.post_v1_signup_lists_by_public_key_signups_response_200 import (
    PostV1SignupListsByPublicKeySignupsResponse200,
)
from ...models.stripe_error import StripeError
from ...types import Response


def _get_kwargs(
    public_key: str,
    *,
    body: PostV1SignupListsByPublicKeySignupsBody,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/signup_lists/{public_key}/signups".format(
            public_key=quote(str(public_key), safe=""),
        ),
    }

    _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostV1SignupListsByPublicKeySignupsResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = PostV1SignupListsByPublicKeySignupsResponse200.from_dict(response.json())

        return response_200

    if response.status_code == 400:
        response_400 = StripeError.from_dict(response.json())

        return response_400

    if response.status_code == 404:
        response_404 = StripeError.from_dict(response.json())

        return response_404

    if response.status_code == 429:
        response_429 = StripeError.from_dict(response.json())

        return response_429

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[PostV1SignupListsByPublicKeySignupsResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    public_key: str,
    *,
    client: AuthenticatedClient | Client,
    body: PostV1SignupListsByPublicKeySignupsBody,
) -> Response[PostV1SignupListsByPublicKeySignupsResponse200 | StripeError]:
    """Join a signup list (unauthenticated; nonce + honeypot + per-IP cap)

     Replaces POST /public/signup-lists/{publicKey}/signups.

    Args:
        public_key (str):
        body (PostV1SignupListsByPublicKeySignupsBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1SignupListsByPublicKeySignupsResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        public_key=public_key,
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    public_key: str,
    *,
    client: AuthenticatedClient | Client,
    body: PostV1SignupListsByPublicKeySignupsBody,
) -> PostV1SignupListsByPublicKeySignupsResponse200 | StripeError | None:
    """Join a signup list (unauthenticated; nonce + honeypot + per-IP cap)

     Replaces POST /public/signup-lists/{publicKey}/signups.

    Args:
        public_key (str):
        body (PostV1SignupListsByPublicKeySignupsBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1SignupListsByPublicKeySignupsResponse200 | StripeError
    """

    return sync_detailed(
        public_key=public_key,
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    public_key: str,
    *,
    client: AuthenticatedClient | Client,
    body: PostV1SignupListsByPublicKeySignupsBody,
) -> Response[PostV1SignupListsByPublicKeySignupsResponse200 | StripeError]:
    """Join a signup list (unauthenticated; nonce + honeypot + per-IP cap)

     Replaces POST /public/signup-lists/{publicKey}/signups.

    Args:
        public_key (str):
        body (PostV1SignupListsByPublicKeySignupsBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1SignupListsByPublicKeySignupsResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        public_key=public_key,
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    public_key: str,
    *,
    client: AuthenticatedClient | Client,
    body: PostV1SignupListsByPublicKeySignupsBody,
) -> PostV1SignupListsByPublicKeySignupsResponse200 | StripeError | None:
    """Join a signup list (unauthenticated; nonce + honeypot + per-IP cap)

     Replaces POST /public/signup-lists/{publicKey}/signups.

    Args:
        public_key (str):
        body (PostV1SignupListsByPublicKeySignupsBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1SignupListsByPublicKeySignupsResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            public_key=public_key,
            client=client,
            body=body,
        )
    ).parsed
