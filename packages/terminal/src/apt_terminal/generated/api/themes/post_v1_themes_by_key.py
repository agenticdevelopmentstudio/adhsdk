from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.post_v1_themes_by_key_body import PostV1ThemesByKeyBody
from ...models.post_v1_themes_by_key_response_200 import PostV1ThemesByKeyResponse200
from ...models.stripe_error import StripeError
from ...types import Response


def _get_kwargs(
    key: str,
    *,
    body: PostV1ThemesByKeyBody,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/themes/{key}".format(
            key=quote(str(key), safe=""),
        ),
    }

    _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostV1ThemesByKeyResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = PostV1ThemesByKeyResponse200.from_dict(response.json())

        return response_200

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

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[PostV1ThemesByKeyResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    key: str,
    *,
    client: AuthenticatedClient,
    body: PostV1ThemesByKeyBody,
) -> Response[PostV1ThemesByKeyResponse200 | StripeError]:
    """Update a live theme (staging/testing only)

     Replaces PUT /themes/{key}.

    Args:
        key (str):
        body (PostV1ThemesByKeyBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1ThemesByKeyResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        key=key,
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    key: str,
    *,
    client: AuthenticatedClient,
    body: PostV1ThemesByKeyBody,
) -> PostV1ThemesByKeyResponse200 | StripeError | None:
    """Update a live theme (staging/testing only)

     Replaces PUT /themes/{key}.

    Args:
        key (str):
        body (PostV1ThemesByKeyBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1ThemesByKeyResponse200 | StripeError
    """

    return sync_detailed(
        key=key,
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    key: str,
    *,
    client: AuthenticatedClient,
    body: PostV1ThemesByKeyBody,
) -> Response[PostV1ThemesByKeyResponse200 | StripeError]:
    """Update a live theme (staging/testing only)

     Replaces PUT /themes/{key}.

    Args:
        key (str):
        body (PostV1ThemesByKeyBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1ThemesByKeyResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        key=key,
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    key: str,
    *,
    client: AuthenticatedClient,
    body: PostV1ThemesByKeyBody,
) -> PostV1ThemesByKeyResponse200 | StripeError | None:
    """Update a live theme (staging/testing only)

     Replaces PUT /themes/{key}.

    Args:
        key (str):
        body (PostV1ThemesByKeyBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1ThemesByKeyResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            key=key,
            client=client,
            body=body,
        )
    ).parsed
