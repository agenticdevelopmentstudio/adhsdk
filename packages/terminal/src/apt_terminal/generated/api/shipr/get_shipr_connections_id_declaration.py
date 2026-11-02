from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.get_shipr_connections_id_declaration_response_200 import (
    GetShiprConnectionsIdDeclarationResponse200,
)
from ...types import UNSET, Response, Unset


def _get_kwargs(
    id: str,
    *,
    slug: str,
    branch: str | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["slug"] = slug

    params["branch"] = branch

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/shipr/connections/{id}/declaration".format(
            id=quote(str(id), safe=""),
        ),
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | GetShiprConnectionsIdDeclarationResponse200 | None:
    if response.status_code == 200:
        response_200 = GetShiprConnectionsIdDeclarationResponse200.from_dict(response.json())

        return response_200

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

    if response.status_code == 502:
        response_502 = Error.from_dict(response.json())

        return response_502

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | GetShiprConnectionsIdDeclarationResponse200]:
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
    slug: str,
    branch: str | Unset = UNSET,
) -> Response[Error | GetShiprConnectionsIdDeclarationResponse200]:
    """What a repository’s committed `.shipr` declares it deploys to

     The register form’s second question, and usually the answer that there is no second question: a
    declared `[deployments]` shard already names its slug, so the form must not offer an org and a name
    beside it. `deployments: null` is the fallback branch — no file, an unparseable one, or one
    declaring no shards — and is the only case in which `deploymentOwner`/`deploymentName` on `POST
    /shipr/register` are read. `note` carries the parser’s complaint when there was one. A forge that
    cannot be reached is a 502, never a null: a repository that could not be read is not a repository
    that declares nothing.

    Args:
        id (str):
        slug (str):
        branch (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GetShiprConnectionsIdDeclarationResponse200]
    """

    kwargs = _get_kwargs(
        id=id,
        slug=slug,
        branch=branch,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    *,
    client: AuthenticatedClient,
    slug: str,
    branch: str | Unset = UNSET,
) -> Error | GetShiprConnectionsIdDeclarationResponse200 | None:
    """What a repository’s committed `.shipr` declares it deploys to

     The register form’s second question, and usually the answer that there is no second question: a
    declared `[deployments]` shard already names its slug, so the form must not offer an org and a name
    beside it. `deployments: null` is the fallback branch — no file, an unparseable one, or one
    declaring no shards — and is the only case in which `deploymentOwner`/`deploymentName` on `POST
    /shipr/register` are read. `note` carries the parser’s complaint when there was one. A forge that
    cannot be reached is a 502, never a null: a repository that could not be read is not a repository
    that declares nothing.

    Args:
        id (str):
        slug (str):
        branch (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GetShiprConnectionsIdDeclarationResponse200
    """

    return sync_detailed(
        id=id,
        client=client,
        slug=slug,
        branch=branch,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
    slug: str,
    branch: str | Unset = UNSET,
) -> Response[Error | GetShiprConnectionsIdDeclarationResponse200]:
    """What a repository’s committed `.shipr` declares it deploys to

     The register form’s second question, and usually the answer that there is no second question: a
    declared `[deployments]` shard already names its slug, so the form must not offer an org and a name
    beside it. `deployments: null` is the fallback branch — no file, an unparseable one, or one
    declaring no shards — and is the only case in which `deploymentOwner`/`deploymentName` on `POST
    /shipr/register` are read. `note` carries the parser’s complaint when there was one. A forge that
    cannot be reached is a 502, never a null: a repository that could not be read is not a repository
    that declares nothing.

    Args:
        id (str):
        slug (str):
        branch (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GetShiprConnectionsIdDeclarationResponse200]
    """

    kwargs = _get_kwargs(
        id=id,
        slug=slug,
        branch=branch,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    *,
    client: AuthenticatedClient,
    slug: str,
    branch: str | Unset = UNSET,
) -> Error | GetShiprConnectionsIdDeclarationResponse200 | None:
    """What a repository’s committed `.shipr` declares it deploys to

     The register form’s second question, and usually the answer that there is no second question: a
    declared `[deployments]` shard already names its slug, so the form must not offer an org and a name
    beside it. `deployments: null` is the fallback branch — no file, an unparseable one, or one
    declaring no shards — and is the only case in which `deploymentOwner`/`deploymentName` on `POST
    /shipr/register` are read. `note` carries the parser’s complaint when there was one. A forge that
    cannot be reached is a 502, never a null: a repository that could not be read is not a repository
    that declares nothing.

    Args:
        id (str):
        slug (str):
        branch (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GetShiprConnectionsIdDeclarationResponse200
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            slug=slug,
            branch=branch,
        )
    ).parsed
