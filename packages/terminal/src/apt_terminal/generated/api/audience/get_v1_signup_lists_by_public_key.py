from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.get_v1_signup_lists_by_public_key_response_200 import (
    GetV1SignupListsByPublicKeyResponse200,
)
from ...models.stripe_error import StripeError
from ...types import UNSET, Response, Unset


def _get_kwargs(
    public_key: str,
    *,
    expand: list[str] | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    json_expand: list[str] | Unset = UNSET
    if not isinstance(expand, Unset):
        json_expand = expand

    params["expand[]"] = json_expand

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/v1/signup_lists/{public_key}".format(
            public_key=quote(str(public_key), safe=""),
        ),
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> GetV1SignupListsByPublicKeyResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = GetV1SignupListsByPublicKeyResponse200.from_dict(response.json())

        return response_200

    if response.status_code == 404:
        response_404 = StripeError.from_dict(response.json())

        return response_404

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[GetV1SignupListsByPublicKeyResponse200 | StripeError]:
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
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1SignupListsByPublicKeyResponse200 | StripeError]:
    """A signup list's public display config plus a fresh submit nonce

     Replaces GET /public/signup-lists/{publicKey}.

    Args:
        public_key (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1SignupListsByPublicKeyResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        public_key=public_key,
        expand=expand,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    public_key: str,
    *,
    client: AuthenticatedClient | Client,
    expand: list[str] | Unset = UNSET,
) -> GetV1SignupListsByPublicKeyResponse200 | StripeError | None:
    """A signup list's public display config plus a fresh submit nonce

     Replaces GET /public/signup-lists/{publicKey}.

    Args:
        public_key (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1SignupListsByPublicKeyResponse200 | StripeError
    """

    return sync_detailed(
        public_key=public_key,
        client=client,
        expand=expand,
    ).parsed


async def asyncio_detailed(
    public_key: str,
    *,
    client: AuthenticatedClient | Client,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1SignupListsByPublicKeyResponse200 | StripeError]:
    """A signup list's public display config plus a fresh submit nonce

     Replaces GET /public/signup-lists/{publicKey}.

    Args:
        public_key (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1SignupListsByPublicKeyResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        public_key=public_key,
        expand=expand,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    public_key: str,
    *,
    client: AuthenticatedClient | Client,
    expand: list[str] | Unset = UNSET,
) -> GetV1SignupListsByPublicKeyResponse200 | StripeError | None:
    """A signup list's public display config plus a fresh submit nonce

     Replaces GET /public/signup-lists/{publicKey}.

    Args:
        public_key (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1SignupListsByPublicKeyResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            public_key=public_key,
            client=client,
            expand=expand,
        )
    ).parsed
