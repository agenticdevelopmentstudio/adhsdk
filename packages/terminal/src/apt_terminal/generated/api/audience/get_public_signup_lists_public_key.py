from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.signup_list_public import SignupListPublic
from ...types import Response


def _get_kwargs(
    public_key: str,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/public/signup-lists/{public_key}".format(
            public_key=quote(str(public_key), safe=""),
        ),
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | SignupListPublic | None:
    if response.status_code == 200:
        response_200 = SignupListPublic.from_dict(response.json())

        return response_200

    if response.status_code == 404:
        response_404 = Error.from_dict(response.json())

        return response_404

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | SignupListPublic]:
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
) -> Response[Error | SignupListPublic]:
    """A signup list's public display config plus a fresh submit nonce

    Args:
        public_key (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | SignupListPublic]
    """

    kwargs = _get_kwargs(
        public_key=public_key,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    public_key: str,
    *,
    client: AuthenticatedClient | Client,
) -> Error | SignupListPublic | None:
    """A signup list's public display config plus a fresh submit nonce

    Args:
        public_key (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | SignupListPublic
    """

    return sync_detailed(
        public_key=public_key,
        client=client,
    ).parsed


async def asyncio_detailed(
    public_key: str,
    *,
    client: AuthenticatedClient | Client,
) -> Response[Error | SignupListPublic]:
    """A signup list's public display config plus a fresh submit nonce

    Args:
        public_key (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | SignupListPublic]
    """

    kwargs = _get_kwargs(
        public_key=public_key,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    public_key: str,
    *,
    client: AuthenticatedClient | Client,
) -> Error | SignupListPublic | None:
    """A signup list's public display config plus a fresh submit nonce

    Args:
        public_key (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | SignupListPublic
    """

    return (
        await asyncio_detailed(
            public_key=public_key,
            client=client,
        )
    ).parsed
