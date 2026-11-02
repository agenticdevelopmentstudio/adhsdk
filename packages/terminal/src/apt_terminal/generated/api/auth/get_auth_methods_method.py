from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.auth_method_setting import AuthMethodSetting
from ...models.error import Error
from ...types import Response


def _get_kwargs(
    method: str,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/auth/methods/{method}".format(
            method=quote(str(method), safe=""),
        ),
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> AuthMethodSetting | Error | None:
    if response.status_code == 200:
        response_200 = AuthMethodSetting.from_dict(response.json())

        return response_200

    if response.status_code == 401:
        response_401 = Error.from_dict(response.json())

        return response_401

    if response.status_code == 403:
        response_403 = Error.from_dict(response.json())

        return response_403

    if response.status_code == 404:
        response_404 = Error.from_dict(response.json())

        return response_404

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[AuthMethodSetting | Error]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    method: str,
    *,
    client: AuthenticatedClient,
) -> Response[AuthMethodSetting | Error]:
    """Get an auth method setting (admin)

    Args:
        method (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[AuthMethodSetting | Error]
    """

    kwargs = _get_kwargs(
        method=method,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    method: str,
    *,
    client: AuthenticatedClient,
) -> AuthMethodSetting | Error | None:
    """Get an auth method setting (admin)

    Args:
        method (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        AuthMethodSetting | Error
    """

    return sync_detailed(
        method=method,
        client=client,
    ).parsed


async def asyncio_detailed(
    method: str,
    *,
    client: AuthenticatedClient,
) -> Response[AuthMethodSetting | Error]:
    """Get an auth method setting (admin)

    Args:
        method (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[AuthMethodSetting | Error]
    """

    kwargs = _get_kwargs(
        method=method,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    method: str,
    *,
    client: AuthenticatedClient,
) -> AuthMethodSetting | Error | None:
    """Get an auth method setting (admin)

    Args:
        method (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        AuthMethodSetting | Error
    """

    return (
        await asyncio_detailed(
            method=method,
            client=client,
        )
    ).parsed
