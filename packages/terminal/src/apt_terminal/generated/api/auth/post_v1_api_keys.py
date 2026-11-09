from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.post_v1_api_keys_body_type_0 import PostV1ApiKeysBodyType0
from ...models.post_v1_api_keys_body_type_1 import PostV1ApiKeysBodyType1
from ...models.post_v1_api_keys_response_201 import PostV1ApiKeysResponse201
from ...models.stripe_error import StripeError
from ...types import Response


def _get_kwargs(
    *,
    body: PostV1ApiKeysBodyType0 | PostV1ApiKeysBodyType1,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/api_keys",
    }

    if isinstance(body, PostV1ApiKeysBodyType0):
        _kwargs["json"] = body.to_dict()
    else:
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostV1ApiKeysResponse201 | StripeError | None:
    if response.status_code == 201:
        response_201 = PostV1ApiKeysResponse201.from_dict(response.json())

        return response_201

    if response.status_code == 400:
        response_400 = StripeError.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = StripeError.from_dict(response.json())

        return response_401

    if response.status_code == 403:
        response_403 = StripeError.from_dict(response.json())

        return response_403

    if response.status_code == 404:
        response_404 = StripeError.from_dict(response.json())

        return response_404

    if response.status_code == 409:
        response_409 = StripeError.from_dict(response.json())

        return response_409

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[PostV1ApiKeysResponse201 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    body: PostV1ApiKeysBodyType0 | PostV1ApiKeysBodyType1,
) -> Response[PostV1ApiKeysResponse201 | StripeError]:
    """Mint an API token (raw value shown once)

     Replaces POST /auth/tokens, POST /tokens.

    Args:
        body (PostV1ApiKeysBodyType0 | PostV1ApiKeysBodyType1):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1ApiKeysResponse201 | StripeError]
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
    body: PostV1ApiKeysBodyType0 | PostV1ApiKeysBodyType1,
) -> PostV1ApiKeysResponse201 | StripeError | None:
    """Mint an API token (raw value shown once)

     Replaces POST /auth/tokens, POST /tokens.

    Args:
        body (PostV1ApiKeysBodyType0 | PostV1ApiKeysBodyType1):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1ApiKeysResponse201 | StripeError
    """

    return sync_detailed(
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    body: PostV1ApiKeysBodyType0 | PostV1ApiKeysBodyType1,
) -> Response[PostV1ApiKeysResponse201 | StripeError]:
    """Mint an API token (raw value shown once)

     Replaces POST /auth/tokens, POST /tokens.

    Args:
        body (PostV1ApiKeysBodyType0 | PostV1ApiKeysBodyType1):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1ApiKeysResponse201 | StripeError]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    body: PostV1ApiKeysBodyType0 | PostV1ApiKeysBodyType1,
) -> PostV1ApiKeysResponse201 | StripeError | None:
    """Mint an API token (raw value shown once)

     Replaces POST /auth/tokens, POST /tokens.

    Args:
        body (PostV1ApiKeysBodyType0 | PostV1ApiKeysBodyType1):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1ApiKeysResponse201 | StripeError
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
        )
    ).parsed
