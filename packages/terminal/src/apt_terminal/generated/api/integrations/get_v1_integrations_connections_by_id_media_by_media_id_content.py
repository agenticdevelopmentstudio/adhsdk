from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.get_v1_integrations_connections_by_id_media_by_media_id_content_response_200 import (
    GetV1IntegrationsConnectionsByIdMediaByMediaIdContentResponse200,
)
from ...models.stripe_error import StripeError
from ...types import UNSET, Response, Unset


def _get_kwargs(
    id: str,
    media_id: str,
    *,
    w: str,
    h: str,
    expand: list[str] | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["w"] = w

    params["h"] = h

    json_expand: list[str] | Unset = UNSET
    if not isinstance(expand, Unset):
        json_expand = expand

    params["expand[]"] = json_expand

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/v1/integrations/connections/{id}/media/{media_id}/content".format(
            id=quote(str(id), safe=""),
            media_id=quote(str(media_id), safe=""),
        ),
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> GetV1IntegrationsConnectionsByIdMediaByMediaIdContentResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = GetV1IntegrationsConnectionsByIdMediaByMediaIdContentResponse200.from_dict(
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

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[GetV1IntegrationsConnectionsByIdMediaByMediaIdContentResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    id: str,
    media_id: str,
    *,
    client: AuthenticatedClient,
    w: str,
    h: str,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1IntegrationsConnectionsByIdMediaByMediaIdContentResponse200 | StripeError]:
    """Get a five-minute signed URL for one photo at one size

     Makes no Google call. The URL points at the public media-content route. 404 unless the connection is
    the caller's own google-photos one and the item is on it.

    Replaces GET /integrations/me/connections/{id}/media/{mediaItemId}/content.

    Args:
        id (str):
        media_id (str):
        w (str):
        h (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1IntegrationsConnectionsByIdMediaByMediaIdContentResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
        media_id=media_id,
        w=w,
        h=h,
        expand=expand,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    media_id: str,
    *,
    client: AuthenticatedClient,
    w: str,
    h: str,
    expand: list[str] | Unset = UNSET,
) -> GetV1IntegrationsConnectionsByIdMediaByMediaIdContentResponse200 | StripeError | None:
    """Get a five-minute signed URL for one photo at one size

     Makes no Google call. The URL points at the public media-content route. 404 unless the connection is
    the caller's own google-photos one and the item is on it.

    Replaces GET /integrations/me/connections/{id}/media/{mediaItemId}/content.

    Args:
        id (str):
        media_id (str):
        w (str):
        h (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1IntegrationsConnectionsByIdMediaByMediaIdContentResponse200 | StripeError
    """

    return sync_detailed(
        id=id,
        media_id=media_id,
        client=client,
        w=w,
        h=h,
        expand=expand,
    ).parsed


async def asyncio_detailed(
    id: str,
    media_id: str,
    *,
    client: AuthenticatedClient,
    w: str,
    h: str,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1IntegrationsConnectionsByIdMediaByMediaIdContentResponse200 | StripeError]:
    """Get a five-minute signed URL for one photo at one size

     Makes no Google call. The URL points at the public media-content route. 404 unless the connection is
    the caller's own google-photos one and the item is on it.

    Replaces GET /integrations/me/connections/{id}/media/{mediaItemId}/content.

    Args:
        id (str):
        media_id (str):
        w (str):
        h (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1IntegrationsConnectionsByIdMediaByMediaIdContentResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
        media_id=media_id,
        w=w,
        h=h,
        expand=expand,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    media_id: str,
    *,
    client: AuthenticatedClient,
    w: str,
    h: str,
    expand: list[str] | Unset = UNSET,
) -> GetV1IntegrationsConnectionsByIdMediaByMediaIdContentResponse200 | StripeError | None:
    """Get a five-minute signed URL for one photo at one size

     Makes no Google call. The URL points at the public media-content route. 404 unless the connection is
    the caller's own google-photos one and the item is on it.

    Replaces GET /integrations/me/connections/{id}/media/{mediaItemId}/content.

    Args:
        id (str):
        media_id (str):
        w (str):
        h (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1IntegrationsConnectionsByIdMediaByMediaIdContentResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            id=id,
            media_id=media_id,
            client=client,
            w=w,
            h=h,
            expand=expand,
        )
    ).parsed
