from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.ecosystem_server_bag_entry import EcosystemServerBagEntry
from ...models.error import Error
from ...models.post_ecosystem_server_bag_id_body import PostEcosystemServerBagIdBody
from ...types import UNSET, Response, Unset


def _get_kwargs(
    id: str,
    *,
    body: PostEcosystemServerBagIdBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/ecosystem/server-bag/{id}".format(
            id=quote(str(id), safe=""),
        ),
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> EcosystemServerBagEntry | Error | None:
    if response.status_code == 201:
        response_201 = EcosystemServerBagEntry.from_dict(response.json())

        return response_201

    if response.status_code == 400:
        response_400 = Error.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = Error.from_dict(response.json())

        return response_401

    if response.status_code == 403:
        response_403 = Error.from_dict(response.json())

        return response_403

    if response.status_code == 404:
        response_404 = Error.from_dict(response.json())

        return response_404

    if response.status_code == 409:
        response_409 = Error.from_dict(response.json())

        return response_409

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[EcosystemServerBagEntry | Error]:
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
    body: PostEcosystemServerBagIdBody | Unset = UNSET,
) -> Response[EcosystemServerBagEntry | Error]:
    """Create one bag entry on the ecosystem (409 if the key exists)

    Args:
        id (str):
        body (PostEcosystemServerBagIdBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[EcosystemServerBagEntry | Error]
    """

    kwargs = _get_kwargs(
        id=id,
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    *,
    client: AuthenticatedClient,
    body: PostEcosystemServerBagIdBody | Unset = UNSET,
) -> EcosystemServerBagEntry | Error | None:
    """Create one bag entry on the ecosystem (409 if the key exists)

    Args:
        id (str):
        body (PostEcosystemServerBagIdBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        EcosystemServerBagEntry | Error
    """

    return sync_detailed(
        id=id,
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
    body: PostEcosystemServerBagIdBody | Unset = UNSET,
) -> Response[EcosystemServerBagEntry | Error]:
    """Create one bag entry on the ecosystem (409 if the key exists)

    Args:
        id (str):
        body (PostEcosystemServerBagIdBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[EcosystemServerBagEntry | Error]
    """

    kwargs = _get_kwargs(
        id=id,
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    *,
    client: AuthenticatedClient,
    body: PostEcosystemServerBagIdBody | Unset = UNSET,
) -> EcosystemServerBagEntry | Error | None:
    """Create one bag entry on the ecosystem (409 if the key exists)

    Args:
        id (str):
        body (PostEcosystemServerBagIdBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        EcosystemServerBagEntry | Error
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            body=body,
        )
    ).parsed
