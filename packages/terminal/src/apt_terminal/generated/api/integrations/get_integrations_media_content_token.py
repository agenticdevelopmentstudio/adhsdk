from http import HTTPStatus
from io import BytesIO
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.problem_details import ProblemDetails
from ...types import File, Response


def _get_kwargs(
    token: str,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/integrations/media-content/{token}".format(
            token=quote(str(token), safe=""),
        ),
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> File | ProblemDetails | None:
    if response.status_code == 200:
        response_200 = File(payload=BytesIO(response.content))

        return response_200

    if response.status_code == 401:
        response_401 = ProblemDetails.from_dict(response.json())

        return response_401

    if response.status_code == 404:
        response_404 = ProblemDetails.from_dict(response.json())

        return response_404

    if response.status_code == 502:
        response_502 = ProblemDetails.from_dict(response.json())

        return response_502

    if response.status_code == 503:
        response_503 = ProblemDetails.from_dict(response.json())

        return response_503

    if response.status_code == 504:
        response_504 = ProblemDetails.from_dict(response.json())

        return response_504

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[File | ProblemDetails]:
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
) -> Response[File | ProblemDetails]:
    """Fetch a Google Photos image by signed URL (public)

     No bearer: an `<img>` cannot send one. The token is the credential. It names one connection, one
    media item and one size, and expires after five minutes. Returns the image bytes with the upstream
    content type. Errors are opaque: 401 for a bad, expired or forged token, 404 for an unknown item,
    502 when the image could not be fetched, 504 when the fetch timed out.

    Args:
        token (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[File | ProblemDetails]
    """

    kwargs = _get_kwargs(
        token=token,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    token: str,
    *,
    client: AuthenticatedClient | Client,
) -> File | ProblemDetails | None:
    """Fetch a Google Photos image by signed URL (public)

     No bearer: an `<img>` cannot send one. The token is the credential. It names one connection, one
    media item and one size, and expires after five minutes. Returns the image bytes with the upstream
    content type. Errors are opaque: 401 for a bad, expired or forged token, 404 for an unknown item,
    502 when the image could not be fetched, 504 when the fetch timed out.

    Args:
        token (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        File | ProblemDetails
    """

    return sync_detailed(
        token=token,
        client=client,
    ).parsed


async def asyncio_detailed(
    token: str,
    *,
    client: AuthenticatedClient | Client,
) -> Response[File | ProblemDetails]:
    """Fetch a Google Photos image by signed URL (public)

     No bearer: an `<img>` cannot send one. The token is the credential. It names one connection, one
    media item and one size, and expires after five minutes. Returns the image bytes with the upstream
    content type. Errors are opaque: 401 for a bad, expired or forged token, 404 for an unknown item,
    502 when the image could not be fetched, 504 when the fetch timed out.

    Args:
        token (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[File | ProblemDetails]
    """

    kwargs = _get_kwargs(
        token=token,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    token: str,
    *,
    client: AuthenticatedClient | Client,
) -> File | ProblemDetails | None:
    """Fetch a Google Photos image by signed URL (public)

     No bearer: an `<img>` cannot send one. The token is the credential. It names one connection, one
    media item and one size, and expires after five minutes. Returns the image bytes with the upstream
    content type. Errors are opaque: 401 for a bad, expired or forged token, 404 for an unknown item,
    502 when the image could not be fetched, 504 when the fetch timed out.

    Args:
        token (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        File | ProblemDetails
    """

    return (
        await asyncio_detailed(
            token=token,
            client=client,
        )
    ).parsed
