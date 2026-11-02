from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.post_auth_login_mfa_webauthn_options_body import PostAuthLoginMfaWebauthnOptionsBody
from ...models.post_auth_login_mfa_webauthn_options_response_200 import (
    PostAuthLoginMfaWebauthnOptionsResponse200,
)
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    body: PostAuthLoginMfaWebauthnOptionsBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/auth/login/mfa/webauthn/options",
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | PostAuthLoginMfaWebauthnOptionsResponse200 | None:
    if response.status_code == 200:
        response_200 = PostAuthLoginMfaWebauthnOptionsResponse200.from_dict(response.json())

        return response_200

    if response.status_code == 400:
        response_400 = Error.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = Error.from_dict(response.json())

        return response_401

    if response.status_code == 422:
        response_422 = Error.from_dict(response.json())

        return response_422

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | PostAuthLoginMfaWebauthnOptionsResponse200]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient | Client,
    body: PostAuthLoginMfaWebauthnOptionsBody | Unset = UNSET,
) -> Response[Error | PostAuthLoginMfaWebauthnOptionsResponse200]:
    """WebAuthn 2nd-factor: assertion options bound to the pending challenge

    Args:
        body (PostAuthLoginMfaWebauthnOptionsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PostAuthLoginMfaWebauthnOptionsResponse200]
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
    body: PostAuthLoginMfaWebauthnOptionsBody | Unset = UNSET,
) -> Error | PostAuthLoginMfaWebauthnOptionsResponse200 | None:
    """WebAuthn 2nd-factor: assertion options bound to the pending challenge

    Args:
        body (PostAuthLoginMfaWebauthnOptionsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PostAuthLoginMfaWebauthnOptionsResponse200
    """

    return sync_detailed(
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient | Client,
    body: PostAuthLoginMfaWebauthnOptionsBody | Unset = UNSET,
) -> Response[Error | PostAuthLoginMfaWebauthnOptionsResponse200]:
    """WebAuthn 2nd-factor: assertion options bound to the pending challenge

    Args:
        body (PostAuthLoginMfaWebauthnOptionsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PostAuthLoginMfaWebauthnOptionsResponse200]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient | Client,
    body: PostAuthLoginMfaWebauthnOptionsBody | Unset = UNSET,
) -> Error | PostAuthLoginMfaWebauthnOptionsResponse200 | None:
    """WebAuthn 2nd-factor: assertion options bound to the pending challenge

    Args:
        body (PostAuthLoginMfaWebauthnOptionsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PostAuthLoginMfaWebauthnOptionsResponse200
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
        )
    ).parsed
