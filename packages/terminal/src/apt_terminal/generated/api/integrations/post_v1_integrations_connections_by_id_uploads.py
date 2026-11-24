from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.post_v1_integrations_connections_by_id_uploads_response_200 import (
    PostV1IntegrationsConnectionsByIdUploadsResponse200,
)
from ...models.stripe_error import StripeError
from ...types import Response


def _get_kwargs(
    id: str,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/integrations/connections/{id}/uploads".format(
            id=quote(str(id), safe=""),
        ),
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostV1IntegrationsConnectionsByIdUploadsResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = PostV1IntegrationsConnectionsByIdUploadsResponse200.from_dict(
            response.json()
        )

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

    if response.status_code == 413:
        response_413 = StripeError.from_dict(response.json())

        return response_413

    if response.status_code == 502:
        response_502 = StripeError.from_dict(response.json())

        return response_502

    if response.status_code == 504:
        response_504 = StripeError.from_dict(response.json())

        return response_504

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[PostV1IntegrationsConnectionsByIdUploadsResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
) -> Response[PostV1IntegrationsConnectionsByIdUploadsResponse200 | StripeError]:
    """Upload photo bytes to Google Photos

     The request body is the raw bytes. They are streamed to Google, never buffered, and capped at 200 MB
    (413). Run action `upload` with the returned token to create the media item. 504 when Google is too
    slow, 502 on a network failure.

    Replaces POST /integrations/me/connections/{id}/google-photos/uploads.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1IntegrationsConnectionsByIdUploadsResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    *,
    client: AuthenticatedClient,
) -> PostV1IntegrationsConnectionsByIdUploadsResponse200 | StripeError | None:
    """Upload photo bytes to Google Photos

     The request body is the raw bytes. They are streamed to Google, never buffered, and capped at 200 MB
    (413). Run action `upload` with the returned token to create the media item. 504 when Google is too
    slow, 502 on a network failure.

    Replaces POST /integrations/me/connections/{id}/google-photos/uploads.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1IntegrationsConnectionsByIdUploadsResponse200 | StripeError
    """

    return sync_detailed(
        id=id,
        client=client,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
) -> Response[PostV1IntegrationsConnectionsByIdUploadsResponse200 | StripeError]:
    """Upload photo bytes to Google Photos

     The request body is the raw bytes. They are streamed to Google, never buffered, and capped at 200 MB
    (413). Run action `upload` with the returned token to create the media item. 504 when Google is too
    slow, 502 on a network failure.

    Replaces POST /integrations/me/connections/{id}/google-photos/uploads.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1IntegrationsConnectionsByIdUploadsResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    *,
    client: AuthenticatedClient,
) -> PostV1IntegrationsConnectionsByIdUploadsResponse200 | StripeError | None:
    """Upload photo bytes to Google Photos

     The request body is the raw bytes. They are streamed to Google, never buffered, and capped at 200 MB
    (413). Run action `upload` with the returned token to create the media item. 504 when Google is too
    slow, 502 on a network failure.

    Replaces POST /integrations/me/connections/{id}/google-photos/uploads.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1IntegrationsConnectionsByIdUploadsResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
        )
    ).parsed
