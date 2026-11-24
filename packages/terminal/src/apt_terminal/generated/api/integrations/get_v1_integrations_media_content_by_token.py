from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.get_v1_integrations_media_content_by_token_response_200 import (
    GetV1IntegrationsMediaContentByTokenResponse200,
)
from ...models.stripe_error import StripeError
from ...types import UNSET, Response, Unset


def _get_kwargs(
    token: str,
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
        "url": "/v1/integrations/media_content/{token}".format(
            token=quote(str(token), safe=""),
        ),
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> GetV1IntegrationsMediaContentByTokenResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = GetV1IntegrationsMediaContentByTokenResponse200.from_dict(response.json())

        return response_200

    if response.status_code == 401:
        response_401 = StripeError.from_dict(response.json())

        return response_401

    if response.status_code == 404:
        response_404 = StripeError.from_dict(response.json())

        return response_404

    if response.status_code == 502:
        response_502 = StripeError.from_dict(response.json())

        return response_502

    if response.status_code == 503:
        response_503 = StripeError.from_dict(response.json())

        return response_503

    if response.status_code == 504:
        response_504 = StripeError.from_dict(response.json())

        return response_504

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[GetV1IntegrationsMediaContentByTokenResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    token: str,
    *,
    client: AuthenticatedClient | Client,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1IntegrationsMediaContentByTokenResponse200 | StripeError]:
    """Fetch a Google Photos image by signed URL (public)

     No bearer: an `<img>` cannot send one. The token is the credential. It names one connection, one
    media item and one size, and expires after five minutes. Returns the image bytes with the upstream
    content type. Errors are opaque: 401 for a bad, expired or forged token, 404 for an unknown item,
    502 when the image could not be fetched, 504 when the fetch timed out.

    Replaces GET /integrations/media-content/{token}.

    Args:
        token (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1IntegrationsMediaContentByTokenResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        token=token,
        expand=expand,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    token: str,
    *,
    client: AuthenticatedClient | Client,
    expand: list[str] | Unset = UNSET,
) -> GetV1IntegrationsMediaContentByTokenResponse200 | StripeError | None:
    """Fetch a Google Photos image by signed URL (public)

     No bearer: an `<img>` cannot send one. The token is the credential. It names one connection, one
    media item and one size, and expires after five minutes. Returns the image bytes with the upstream
    content type. Errors are opaque: 401 for a bad, expired or forged token, 404 for an unknown item,
    502 when the image could not be fetched, 504 when the fetch timed out.

    Replaces GET /integrations/media-content/{token}.

    Args:
        token (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1IntegrationsMediaContentByTokenResponse200 | StripeError
    """

    return sync_detailed(
        token=token,
        client=client,
        expand=expand,
    ).parsed


async def asyncio_detailed(
    token: str,
    *,
    client: AuthenticatedClient | Client,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1IntegrationsMediaContentByTokenResponse200 | StripeError]:
    """Fetch a Google Photos image by signed URL (public)

     No bearer: an `<img>` cannot send one. The token is the credential. It names one connection, one
    media item and one size, and expires after five minutes. Returns the image bytes with the upstream
    content type. Errors are opaque: 401 for a bad, expired or forged token, 404 for an unknown item,
    502 when the image could not be fetched, 504 when the fetch timed out.

    Replaces GET /integrations/media-content/{token}.

    Args:
        token (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1IntegrationsMediaContentByTokenResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        token=token,
        expand=expand,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    token: str,
    *,
    client: AuthenticatedClient | Client,
    expand: list[str] | Unset = UNSET,
) -> GetV1IntegrationsMediaContentByTokenResponse200 | StripeError | None:
    """Fetch a Google Photos image by signed URL (public)

     No bearer: an `<img>` cannot send one. The token is the credential. It names one connection, one
    media item and one size, and expires after five minutes. Returns the image bytes with the upstream
    content type. Errors are opaque: 401 for a bad, expired or forged token, 404 for an unknown item,
    502 when the image could not be fetched, 504 when the fetch timed out.

    Replaces GET /integrations/media-content/{token}.

    Args:
        token (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1IntegrationsMediaContentByTokenResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            token=token,
            client=client,
            expand=expand,
        )
    ).parsed
