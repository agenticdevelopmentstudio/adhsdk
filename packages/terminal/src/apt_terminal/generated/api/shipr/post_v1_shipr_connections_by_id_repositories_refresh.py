from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.post_v1_shipr_connections_by_id_repositories_refresh_response_200 import (
    PostV1ShiprConnectionsByIdRepositoriesRefreshResponse200,
)
from ...models.stripe_error import StripeError
from ...types import Response


def _get_kwargs(
    id: str,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/shipr/connections/{id}/repositories/refresh".format(
            id=quote(str(id), safe=""),
        ),
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostV1ShiprConnectionsByIdRepositoriesRefreshResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = PostV1ShiprConnectionsByIdRepositoriesRefreshResponse200.from_dict(
            response.json()
        )

        return response_200

    if response.status_code == 401:
        response_401 = StripeError.from_dict(response.json())

        return response_401

    if response.status_code == 403:
        response_403 = StripeError.from_dict(response.json())

        return response_403

    if response.status_code == 404:
        response_404 = StripeError.from_dict(response.json())

        return response_404

    if response.status_code == 502:
        response_502 = StripeError.from_dict(response.json())

        return response_502

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[PostV1ShiprConnectionsByIdRepositoriesRefreshResponse200 | StripeError]:
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
) -> Response[PostV1ShiprConnectionsByIdRepositoriesRefreshResponse200 | StripeError]:
    """Ask GitHub again what this connection was granted

     The Test button, and the read-then-refresh the picker does on open. Always goes to GitHub — a stored
    list never short-circuits it, because the whole reason to call this rather than the GET is to find
    out whether the credentials still work and what has changed since.

    The answer replaces the stored row wholesale rather than merging into it: a grant is a set, and a
    merge would keep a repository the installation has since lost, which is exactly the kind of entry an
    operator would pick and only discover was gone at the first push. A call that cannot reach GitHub is
    a 502 and leaves the stored row untouched — a list read an hour ago can still be picked from, and an
    empty one cannot.

    Replaces POST /shipr/connections/{id}/repositories/refresh.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1ShiprConnectionsByIdRepositoriesRefreshResponse200 | StripeError]
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
) -> PostV1ShiprConnectionsByIdRepositoriesRefreshResponse200 | StripeError | None:
    """Ask GitHub again what this connection was granted

     The Test button, and the read-then-refresh the picker does on open. Always goes to GitHub — a stored
    list never short-circuits it, because the whole reason to call this rather than the GET is to find
    out whether the credentials still work and what has changed since.

    The answer replaces the stored row wholesale rather than merging into it: a grant is a set, and a
    merge would keep a repository the installation has since lost, which is exactly the kind of entry an
    operator would pick and only discover was gone at the first push. A call that cannot reach GitHub is
    a 502 and leaves the stored row untouched — a list read an hour ago can still be picked from, and an
    empty one cannot.

    Replaces POST /shipr/connections/{id}/repositories/refresh.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1ShiprConnectionsByIdRepositoriesRefreshResponse200 | StripeError
    """

    return sync_detailed(
        id=id,
        client=client,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
) -> Response[PostV1ShiprConnectionsByIdRepositoriesRefreshResponse200 | StripeError]:
    """Ask GitHub again what this connection was granted

     The Test button, and the read-then-refresh the picker does on open. Always goes to GitHub — a stored
    list never short-circuits it, because the whole reason to call this rather than the GET is to find
    out whether the credentials still work and what has changed since.

    The answer replaces the stored row wholesale rather than merging into it: a grant is a set, and a
    merge would keep a repository the installation has since lost, which is exactly the kind of entry an
    operator would pick and only discover was gone at the first push. A call that cannot reach GitHub is
    a 502 and leaves the stored row untouched — a list read an hour ago can still be picked from, and an
    empty one cannot.

    Replaces POST /shipr/connections/{id}/repositories/refresh.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1ShiprConnectionsByIdRepositoriesRefreshResponse200 | StripeError]
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
) -> PostV1ShiprConnectionsByIdRepositoriesRefreshResponse200 | StripeError | None:
    """Ask GitHub again what this connection was granted

     The Test button, and the read-then-refresh the picker does on open. Always goes to GitHub — a stored
    list never short-circuits it, because the whole reason to call this rather than the GET is to find
    out whether the credentials still work and what has changed since.

    The answer replaces the stored row wholesale rather than merging into it: a grant is a set, and a
    merge would keep a repository the installation has since lost, which is exactly the kind of entry an
    operator would pick and only discover was gone at the first push. A call that cannot reach GitHub is
    a 502 and leaves the stored row untouched — a list read an hour ago can still be picked from, and an
    empty one cannot.

    Replaces POST /shipr/connections/{id}/repositories/refresh.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1ShiprConnectionsByIdRepositoriesRefreshResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
        )
    ).parsed
