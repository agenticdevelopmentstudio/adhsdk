from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.post_account_mfa_webauthn_register_options_body import (
    PostAccountMfaWebauthnRegisterOptionsBody,
)
from ...models.post_account_mfa_webauthn_register_options_response_200 import (
    PostAccountMfaWebauthnRegisterOptionsResponse200,
)
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    body: PostAccountMfaWebauthnRegisterOptionsBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/account/mfa/webauthn/register/options",
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | PostAccountMfaWebauthnRegisterOptionsResponse200 | None:
    if response.status_code == 200:
        response_200 = PostAccountMfaWebauthnRegisterOptionsResponse200.from_dict(response.json())

        return response_200

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
) -> Response[Error | PostAccountMfaWebauthnRegisterOptionsResponse200]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    body: PostAccountMfaWebauthnRegisterOptionsBody | Unset = UNSET,
) -> Response[Error | PostAccountMfaWebauthnRegisterOptionsResponse200]:
    """Begin passkey/security-key registration → ceremony options + challenge token

    Args:
        body (PostAccountMfaWebauthnRegisterOptionsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PostAccountMfaWebauthnRegisterOptionsResponse200]
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
    body: PostAccountMfaWebauthnRegisterOptionsBody | Unset = UNSET,
) -> Error | PostAccountMfaWebauthnRegisterOptionsResponse200 | None:
    """Begin passkey/security-key registration → ceremony options + challenge token

    Args:
        body (PostAccountMfaWebauthnRegisterOptionsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PostAccountMfaWebauthnRegisterOptionsResponse200
    """

    return sync_detailed(
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    body: PostAccountMfaWebauthnRegisterOptionsBody | Unset = UNSET,
) -> Response[Error | PostAccountMfaWebauthnRegisterOptionsResponse200]:
    """Begin passkey/security-key registration → ceremony options + challenge token

    Args:
        body (PostAccountMfaWebauthnRegisterOptionsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PostAccountMfaWebauthnRegisterOptionsResponse200]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    body: PostAccountMfaWebauthnRegisterOptionsBody | Unset = UNSET,
) -> Error | PostAccountMfaWebauthnRegisterOptionsResponse200 | None:
    """Begin passkey/security-key registration → ceremony options + challenge token

    Args:
        body (PostAccountMfaWebauthnRegisterOptionsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PostAccountMfaWebauthnRegisterOptionsResponse200
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
        )
    ).parsed
