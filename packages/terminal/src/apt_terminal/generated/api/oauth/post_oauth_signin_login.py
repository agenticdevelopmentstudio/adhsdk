from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.mfa_challenge import MfaChallenge
from ...models.post_oauth_signin_login_body import PostOauthSigninLoginBody
from ...models.post_oauth_signin_login_response_200 import PostOauthSigninLoginResponse200
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    body: PostOauthSigninLoginBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/oauth/signin/login",
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | MfaChallenge | PostOauthSigninLoginResponse200 | None:
    if response.status_code == 200:
        response_200 = PostOauthSigninLoginResponse200.from_dict(response.json())

        return response_200

    if response.status_code == 202:
        response_202 = MfaChallenge.from_dict(response.json())

        return response_202

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
) -> Response[Error | MfaChallenge | PostOauthSigninLoginResponse200]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient | Client,
    body: PostOauthSigninLoginBody | Unset = UNSET,
) -> Response[Error | MfaChallenge | PostOauthSigninLoginResponse200]:
    """Central credential login → sets the SSO session, returns the brand redirect URL

    Args:
        body (PostOauthSigninLoginBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | MfaChallenge | PostOauthSigninLoginResponse200]
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
    body: PostOauthSigninLoginBody | Unset = UNSET,
) -> Error | MfaChallenge | PostOauthSigninLoginResponse200 | None:
    """Central credential login → sets the SSO session, returns the brand redirect URL

    Args:
        body (PostOauthSigninLoginBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | MfaChallenge | PostOauthSigninLoginResponse200
    """

    return sync_detailed(
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient | Client,
    body: PostOauthSigninLoginBody | Unset = UNSET,
) -> Response[Error | MfaChallenge | PostOauthSigninLoginResponse200]:
    """Central credential login → sets the SSO session, returns the brand redirect URL

    Args:
        body (PostOauthSigninLoginBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | MfaChallenge | PostOauthSigninLoginResponse200]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient | Client,
    body: PostOauthSigninLoginBody | Unset = UNSET,
) -> Error | MfaChallenge | PostOauthSigninLoginResponse200 | None:
    """Central credential login → sets the SSO session, returns the brand redirect URL

    Args:
        body (PostOauthSigninLoginBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | MfaChallenge | PostOauthSigninLoginResponse200
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
        )
    ).parsed
