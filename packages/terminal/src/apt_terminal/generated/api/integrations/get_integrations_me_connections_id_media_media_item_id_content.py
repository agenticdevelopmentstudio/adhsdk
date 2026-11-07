from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.get_integrations_me_connections_id_media_media_item_id_content_response_200 import (
    GetIntegrationsMeConnectionsIdMediaMediaItemIdContentResponse200,
)
from ...models.problem_details import ProblemDetails
from ...types import UNSET, Response


def _get_kwargs(
    id: str,
    media_item_id: str,
    *,
    w: str,
    h: str,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["w"] = w

    params["h"] = h

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/integrations/me/connections/{id}/media/{media_item_id}/content".format(
            id=quote(str(id), safe=""),
            media_item_id=quote(str(media_item_id), safe=""),
        ),
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> GetIntegrationsMeConnectionsIdMediaMediaItemIdContentResponse200 | ProblemDetails | None:
    if response.status_code == 200:
        response_200 = GetIntegrationsMeConnectionsIdMediaMediaItemIdContentResponse200.from_dict(
            response.json()
        )

        return response_200

    if response.status_code == 400:
        response_400 = ProblemDetails.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = ProblemDetails.from_dict(response.json())

        return response_401

    if response.status_code == 403:
        response_403 = ProblemDetails.from_dict(response.json())

        return response_403

    if response.status_code == 404:
        response_404 = ProblemDetails.from_dict(response.json())

        return response_404

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[GetIntegrationsMeConnectionsIdMediaMediaItemIdContentResponse200 | ProblemDetails]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    id: str,
    media_item_id: str,
    *,
    client: AuthenticatedClient,
    w: str,
    h: str,
) -> Response[GetIntegrationsMeConnectionsIdMediaMediaItemIdContentResponse200 | ProblemDetails]:
    """Get a five-minute signed URL for one photo at one size

     Makes no Google call. The URL points at the public media-content route. 404 unless the connection is
    the caller's own google-photos one and the item is on it.

    Args:
        id (str):
        media_item_id (str):
        w (str):
        h (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetIntegrationsMeConnectionsIdMediaMediaItemIdContentResponse200 | ProblemDetails]
    """

    kwargs = _get_kwargs(
        id=id,
        media_item_id=media_item_id,
        w=w,
        h=h,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    media_item_id: str,
    *,
    client: AuthenticatedClient,
    w: str,
    h: str,
) -> GetIntegrationsMeConnectionsIdMediaMediaItemIdContentResponse200 | ProblemDetails | None:
    """Get a five-minute signed URL for one photo at one size

     Makes no Google call. The URL points at the public media-content route. 404 unless the connection is
    the caller's own google-photos one and the item is on it.

    Args:
        id (str):
        media_item_id (str):
        w (str):
        h (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetIntegrationsMeConnectionsIdMediaMediaItemIdContentResponse200 | ProblemDetails
    """

    return sync_detailed(
        id=id,
        media_item_id=media_item_id,
        client=client,
        w=w,
        h=h,
    ).parsed


async def asyncio_detailed(
    id: str,
    media_item_id: str,
    *,
    client: AuthenticatedClient,
    w: str,
    h: str,
) -> Response[GetIntegrationsMeConnectionsIdMediaMediaItemIdContentResponse200 | ProblemDetails]:
    """Get a five-minute signed URL for one photo at one size

     Makes no Google call. The URL points at the public media-content route. 404 unless the connection is
    the caller's own google-photos one and the item is on it.

    Args:
        id (str):
        media_item_id (str):
        w (str):
        h (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetIntegrationsMeConnectionsIdMediaMediaItemIdContentResponse200 | ProblemDetails]
    """

    kwargs = _get_kwargs(
        id=id,
        media_item_id=media_item_id,
        w=w,
        h=h,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    media_item_id: str,
    *,
    client: AuthenticatedClient,
    w: str,
    h: str,
) -> GetIntegrationsMeConnectionsIdMediaMediaItemIdContentResponse200 | ProblemDetails | None:
    """Get a five-minute signed URL for one photo at one size

     Makes no Google call. The URL points at the public media-content route. 404 unless the connection is
    the caller's own google-photos one and the item is on it.

    Args:
        id (str):
        media_item_id (str):
        w (str):
        h (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetIntegrationsMeConnectionsIdMediaMediaItemIdContentResponse200 | ProblemDetails
    """

    return (
        await asyncio_detailed(
            id=id,
            media_item_id=media_item_id,
            client=client,
            w=w,
            h=h,
        )
    ).parsed
