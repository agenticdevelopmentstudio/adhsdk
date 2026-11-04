from http import HTTPStatus
from typing import Any, cast

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    client_id: str,
    provider_id: str,
    return_: str | Unset = UNSET,
    login_challenge: str | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["clientId"] = client_id

    params["providerId"] = provider_id

    params["return"] = return_

    params["login_challenge"] = login_challenge

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/oauth/signin/start",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Any | Error | None:
    if response.status_code == 302:
        response_302 = cast(Any, None)
        return response_302

    if response.status_code == 400:
        response_400 = Error.from_dict(response.json())

        return response_400

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Any | Error]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient | Client,
    client_id: str,
    provider_id: str,
    return_: str | Unset = UNSET,
    login_challenge: str | Unset = UNSET,
) -> Response[Any | Error]:
    """Begin the server redirect flow → 302 to the provider

    Args:
        client_id (str):
        provider_id (str):
        return_ (str | Unset):
        login_challenge (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Any | Error]
    """

    kwargs = _get_kwargs(
        client_id=client_id,
        provider_id=provider_id,
        return_=return_,
        login_challenge=login_challenge,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient | Client,
    client_id: str,
    provider_id: str,
    return_: str | Unset = UNSET,
    login_challenge: str | Unset = UNSET,
) -> Any | Error | None:
    """Begin the server redirect flow → 302 to the provider

    Args:
        client_id (str):
        provider_id (str):
        return_ (str | Unset):
        login_challenge (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Any | Error
    """

    return sync_detailed(
        client=client,
        client_id=client_id,
        provider_id=provider_id,
        return_=return_,
        login_challenge=login_challenge,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient | Client,
    client_id: str,
    provider_id: str,
    return_: str | Unset = UNSET,
    login_challenge: str | Unset = UNSET,
) -> Response[Any | Error]:
    """Begin the server redirect flow → 302 to the provider

    Args:
        client_id (str):
        provider_id (str):
        return_ (str | Unset):
        login_challenge (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Any | Error]
    """

    kwargs = _get_kwargs(
        client_id=client_id,
        provider_id=provider_id,
        return_=return_,
        login_challenge=login_challenge,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient | Client,
    client_id: str,
    provider_id: str,
    return_: str | Unset = UNSET,
    login_challenge: str | Unset = UNSET,
) -> Any | Error | None:
    """Begin the server redirect flow → 302 to the provider

    Args:
        client_id (str):
        provider_id (str):
        return_ (str | Unset):
        login_challenge (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Any | Error
    """

    return (
        await asyncio_detailed(
            client=client,
            client_id=client_id,
            provider_id=provider_id,
            return_=return_,
            login_challenge=login_challenge,
        )
    ).parsed
