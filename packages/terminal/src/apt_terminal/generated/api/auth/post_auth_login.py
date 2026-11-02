from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.auth_result import AuthResult
from ...models.error import Error
from ...models.mfa_challenge import MfaChallenge
from ...models.post_auth_login_body import PostAuthLoginBody
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    body: PostAuthLoginBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/auth/login",
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> AuthResult | Error | MfaChallenge | None:
    if response.status_code == 200:
        response_200 = AuthResult.from_dict(response.json())

        return response_200

    if response.status_code == 202:
        response_202 = MfaChallenge.from_dict(response.json())

        return response_202

    if response.status_code == 401:
        response_401 = Error.from_dict(response.json())

        return response_401

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[AuthResult | Error | MfaChallenge]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient | Client,
    body: PostAuthLoginBody | Unset = UNSET,
) -> Response[AuthResult | Error | MfaChallenge]:
    """Sign in (may require a second factor)

    Args:
        body (PostAuthLoginBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[AuthResult | Error | MfaChallenge]
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
    body: PostAuthLoginBody | Unset = UNSET,
) -> AuthResult | Error | MfaChallenge | None:
    """Sign in (may require a second factor)

    Args:
        body (PostAuthLoginBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        AuthResult | Error | MfaChallenge
    """

    return sync_detailed(
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient | Client,
    body: PostAuthLoginBody | Unset = UNSET,
) -> Response[AuthResult | Error | MfaChallenge]:
    """Sign in (may require a second factor)

    Args:
        body (PostAuthLoginBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[AuthResult | Error | MfaChallenge]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient | Client,
    body: PostAuthLoginBody | Unset = UNSET,
) -> AuthResult | Error | MfaChallenge | None:
    """Sign in (may require a second factor)

    Args:
        body (PostAuthLoginBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        AuthResult | Error | MfaChallenge
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
        )
    ).parsed
