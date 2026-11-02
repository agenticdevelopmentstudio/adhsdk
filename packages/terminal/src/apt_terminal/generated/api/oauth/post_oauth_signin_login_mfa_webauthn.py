from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.post_oauth_signin_login_mfa_webauthn_body import PostOauthSigninLoginMfaWebauthnBody
from ...models.post_oauth_signin_login_mfa_webauthn_response_200 import (
    PostOauthSigninLoginMfaWebauthnResponse200,
)
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    body: PostOauthSigninLoginMfaWebauthnBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/oauth/signin/login/mfa/webauthn",
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | PostOauthSigninLoginMfaWebauthnResponse200 | None:
    if response.status_code == 200:
        response_200 = PostOauthSigninLoginMfaWebauthnResponse200.from_dict(response.json())

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

    if response.status_code == 415:
        response_415 = Error.from_dict(response.json())

        return response_415

    if response.status_code == 503:
        response_503 = Error.from_dict(response.json())

        return response_503

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | PostOauthSigninLoginMfaWebauthnResponse200]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient | Client,
    body: PostOauthSigninLoginMfaWebauthnBody | Unset = UNSET,
) -> Response[Error | PostOauthSigninLoginMfaWebauthnResponse200]:
    """Central login: verify the 2nd-factor assertion → SSO session (aal=2) + brand redirect URL

    Args:
        body (PostOauthSigninLoginMfaWebauthnBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PostOauthSigninLoginMfaWebauthnResponse200]
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
    body: PostOauthSigninLoginMfaWebauthnBody | Unset = UNSET,
) -> Error | PostOauthSigninLoginMfaWebauthnResponse200 | None:
    """Central login: verify the 2nd-factor assertion → SSO session (aal=2) + brand redirect URL

    Args:
        body (PostOauthSigninLoginMfaWebauthnBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PostOauthSigninLoginMfaWebauthnResponse200
    """

    return sync_detailed(
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient | Client,
    body: PostOauthSigninLoginMfaWebauthnBody | Unset = UNSET,
) -> Response[Error | PostOauthSigninLoginMfaWebauthnResponse200]:
    """Central login: verify the 2nd-factor assertion → SSO session (aal=2) + brand redirect URL

    Args:
        body (PostOauthSigninLoginMfaWebauthnBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PostOauthSigninLoginMfaWebauthnResponse200]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient | Client,
    body: PostOauthSigninLoginMfaWebauthnBody | Unset = UNSET,
) -> Error | PostOauthSigninLoginMfaWebauthnResponse200 | None:
    """Central login: verify the 2nd-factor assertion → SSO session (aal=2) + brand redirect URL

    Args:
        body (PostOauthSigninLoginMfaWebauthnBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PostOauthSigninLoginMfaWebauthnResponse200
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
        )
    ).parsed
