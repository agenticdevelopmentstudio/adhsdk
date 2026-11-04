from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.get_oauth_signin_discovery_response_200 import GetOauthSigninDiscoveryResponse200
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    client_id: str | Unset = UNSET,
    ecosystem: str | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["clientId"] = client_id

    params["ecosystem"] = ecosystem

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/oauth/signin/discovery",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | GetOauthSigninDiscoveryResponse200 | None:
    if response.status_code == 200:
        response_200 = GetOauthSigninDiscoveryResponse200.from_dict(response.json())

        return response_200

    if response.status_code == 400:
        response_400 = Error.from_dict(response.json())

        return response_400

    if response.status_code == 404:
        response_404 = Error.from_dict(response.json())

        return response_404

    if response.status_code == 500:
        response_500 = Error.from_dict(response.json())

        return response_500

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | GetOauthSigninDiscoveryResponse200]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient | Client,
    client_id: str | Unset = UNSET,
    ecosystem: str | Unset = UNSET,
) -> Response[Error | GetOauthSigninDiscoveryResponse200]:
    """Client-auth discovery: issuer, endpoints, sign-in apps, realm switches, providers

    Args:
        client_id (str | Unset):
        ecosystem (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GetOauthSigninDiscoveryResponse200]
    """

    kwargs = _get_kwargs(
        client_id=client_id,
        ecosystem=ecosystem,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient | Client,
    client_id: str | Unset = UNSET,
    ecosystem: str | Unset = UNSET,
) -> Error | GetOauthSigninDiscoveryResponse200 | None:
    """Client-auth discovery: issuer, endpoints, sign-in apps, realm switches, providers

    Args:
        client_id (str | Unset):
        ecosystem (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GetOauthSigninDiscoveryResponse200
    """

    return sync_detailed(
        client=client,
        client_id=client_id,
        ecosystem=ecosystem,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient | Client,
    client_id: str | Unset = UNSET,
    ecosystem: str | Unset = UNSET,
) -> Response[Error | GetOauthSigninDiscoveryResponse200]:
    """Client-auth discovery: issuer, endpoints, sign-in apps, realm switches, providers

    Args:
        client_id (str | Unset):
        ecosystem (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GetOauthSigninDiscoveryResponse200]
    """

    kwargs = _get_kwargs(
        client_id=client_id,
        ecosystem=ecosystem,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient | Client,
    client_id: str | Unset = UNSET,
    ecosystem: str | Unset = UNSET,
) -> Error | GetOauthSigninDiscoveryResponse200 | None:
    """Client-auth discovery: issuer, endpoints, sign-in apps, realm switches, providers

    Args:
        client_id (str | Unset):
        ecosystem (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GetOauthSigninDiscoveryResponse200
    """

    return (
        await asyncio_detailed(
            client=client,
            client_id=client_id,
            ecosystem=ecosystem,
        )
    ).parsed
