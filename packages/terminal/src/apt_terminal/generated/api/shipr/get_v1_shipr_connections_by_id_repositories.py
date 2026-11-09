from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.get_v1_shipr_connections_by_id_repositories_response_200 import (
    GetV1ShiprConnectionsByIdRepositoriesResponse200,
)
from ...models.stripe_error import StripeError
from ...types import UNSET, Response, Unset


def _get_kwargs(
    id: str,
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
        "url": "/v1/shipr/connections/{id}/repositories".format(
            id=quote(str(id), safe=""),
        ),
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> GetV1ShiprConnectionsByIdRepositoriesResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = GetV1ShiprConnectionsByIdRepositoriesResponse200.from_dict(response.json())

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
) -> Response[GetV1ShiprConnectionsByIdRepositoriesResponse200 | StripeError]:
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
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1ShiprConnectionsByIdRepositoriesResponse200 | StripeError]:
    """Every repository one connection can reach

     What the installation was granted, which is exactly the set `register` can act on — offering
    anything wider means an operator picks a repository whose first push fails minutes later. The
    account-and-repository picker that produced this set is GitHub’s own installation page, so there is
    no org listing beside it. A connection that is not the caller’s own is a 404, never a 403: a 403
    would confirm it exists.

    This reads what was last stored, so it is a database read and normally cannot fail on GitHub’s
    account. The one exception is a connection nothing has been stored for yet: answering `[]` there
    would report an empty grant on the single occasion it is certainly untrue, so a miss goes and asks —
    which is why 502 is still among the responses. Use the refresh below to ask deliberately.

    Replaces GET /shipr/connections/{id}/repositories.

    Args:
        id (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1ShiprConnectionsByIdRepositoriesResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
        expand=expand,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    *,
    client: AuthenticatedClient,
    expand: list[str] | Unset = UNSET,
) -> GetV1ShiprConnectionsByIdRepositoriesResponse200 | StripeError | None:
    """Every repository one connection can reach

     What the installation was granted, which is exactly the set `register` can act on — offering
    anything wider means an operator picks a repository whose first push fails minutes later. The
    account-and-repository picker that produced this set is GitHub’s own installation page, so there is
    no org listing beside it. A connection that is not the caller’s own is a 404, never a 403: a 403
    would confirm it exists.

    This reads what was last stored, so it is a database read and normally cannot fail on GitHub’s
    account. The one exception is a connection nothing has been stored for yet: answering `[]` there
    would report an empty grant on the single occasion it is certainly untrue, so a miss goes and asks —
    which is why 502 is still among the responses. Use the refresh below to ask deliberately.

    Replaces GET /shipr/connections/{id}/repositories.

    Args:
        id (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1ShiprConnectionsByIdRepositoriesResponse200 | StripeError
    """

    return sync_detailed(
        id=id,
        client=client,
        expand=expand,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1ShiprConnectionsByIdRepositoriesResponse200 | StripeError]:
    """Every repository one connection can reach

     What the installation was granted, which is exactly the set `register` can act on — offering
    anything wider means an operator picks a repository whose first push fails minutes later. The
    account-and-repository picker that produced this set is GitHub’s own installation page, so there is
    no org listing beside it. A connection that is not the caller’s own is a 404, never a 403: a 403
    would confirm it exists.

    This reads what was last stored, so it is a database read and normally cannot fail on GitHub’s
    account. The one exception is a connection nothing has been stored for yet: answering `[]` there
    would report an empty grant on the single occasion it is certainly untrue, so a miss goes and asks —
    which is why 502 is still among the responses. Use the refresh below to ask deliberately.

    Replaces GET /shipr/connections/{id}/repositories.

    Args:
        id (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1ShiprConnectionsByIdRepositoriesResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
        expand=expand,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    *,
    client: AuthenticatedClient,
    expand: list[str] | Unset = UNSET,
) -> GetV1ShiprConnectionsByIdRepositoriesResponse200 | StripeError | None:
    """Every repository one connection can reach

     What the installation was granted, which is exactly the set `register` can act on — offering
    anything wider means an operator picks a repository whose first push fails minutes later. The
    account-and-repository picker that produced this set is GitHub’s own installation page, so there is
    no org listing beside it. A connection that is not the caller’s own is a 404, never a 403: a 403
    would confirm it exists.

    This reads what was last stored, so it is a database read and normally cannot fail on GitHub’s
    account. The one exception is a connection nothing has been stored for yet: answering `[]` there
    would report an empty grant on the single occasion it is certainly untrue, so a miss goes and asks —
    which is why 502 is still among the responses. Use the refresh below to ask deliberately.

    Replaces GET /shipr/connections/{id}/repositories.

    Args:
        id (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1ShiprConnectionsByIdRepositoriesResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            expand=expand,
        )
    ).parsed
