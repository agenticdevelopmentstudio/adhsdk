from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.get_v1_shipr_connections_by_id_include_item import (
    GetV1ShiprConnectionsByIdIncludeItem,
)
from ...models.get_v1_shipr_connections_by_id_response_200 import (
    GetV1ShiprConnectionsByIdResponse200,
)
from ...models.stripe_error import StripeError
from ...types import UNSET, Response, Unset


def _get_kwargs(
    id: str,
    *,
    expand: list[str] | Unset = UNSET,
    include: list[GetV1ShiprConnectionsByIdIncludeItem] | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    json_expand: list[str] | Unset = UNSET
    if not isinstance(expand, Unset):
        json_expand = expand

    params["expand[]"] = json_expand

    json_include: list[str] | Unset = UNSET
    if not isinstance(include, Unset):
        json_include = []
        for include_item_data in include:
            include_item = include_item_data.value
            json_include.append(include_item)

    params["include[]"] = json_include

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/v1/shipr/connections/{id}".format(
            id=quote(str(id), safe=""),
        ),
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> GetV1ShiprConnectionsByIdResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = GetV1ShiprConnectionsByIdResponse200.from_dict(response.json())

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

    if response.status_code == 502:
        response_502 = StripeError.from_dict(response.json())

        return response_502

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[GetV1ShiprConnectionsByIdResponse200 | StripeError]:
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
    include: list[GetV1ShiprConnectionsByIdIncludeItem] | Unset = UNSET,
) -> Response[GetV1ShiprConnectionsByIdResponse200 | StripeError]:
    """What a repository’s committed `.shipr` declares it deploys to

     The register form’s second question, and usually the answer that there is no second question: a
    declared `[deployments]` shard already names its slug, so the form must not offer an org and a name
    beside it. `deployments: null` is the fallback branch — no file, an unparseable one, or one
    declaring no shards — and is the only case in which `deploymentOwner`/`deploymentName` on `POST
    /shipr/register` are read. `note` carries the parser’s complaint when there was one. A forge that
    cannot be reached is a 502, never a null: a repository that could not be read is not a repository
    that declares nothing.

    Replaces GET /shipr/connections/{id}/declaration (include declaration).

    Args:
        id (str):
        expand (list[str] | Unset):
        include (list[GetV1ShiprConnectionsByIdIncludeItem] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1ShiprConnectionsByIdResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
        expand=expand,
        include=include,
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
    include: list[GetV1ShiprConnectionsByIdIncludeItem] | Unset = UNSET,
) -> GetV1ShiprConnectionsByIdResponse200 | StripeError | None:
    """What a repository’s committed `.shipr` declares it deploys to

     The register form’s second question, and usually the answer that there is no second question: a
    declared `[deployments]` shard already names its slug, so the form must not offer an org and a name
    beside it. `deployments: null` is the fallback branch — no file, an unparseable one, or one
    declaring no shards — and is the only case in which `deploymentOwner`/`deploymentName` on `POST
    /shipr/register` are read. `note` carries the parser’s complaint when there was one. A forge that
    cannot be reached is a 502, never a null: a repository that could not be read is not a repository
    that declares nothing.

    Replaces GET /shipr/connections/{id}/declaration (include declaration).

    Args:
        id (str):
        expand (list[str] | Unset):
        include (list[GetV1ShiprConnectionsByIdIncludeItem] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1ShiprConnectionsByIdResponse200 | StripeError
    """

    return sync_detailed(
        id=id,
        client=client,
        expand=expand,
        include=include,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
    expand: list[str] | Unset = UNSET,
    include: list[GetV1ShiprConnectionsByIdIncludeItem] | Unset = UNSET,
) -> Response[GetV1ShiprConnectionsByIdResponse200 | StripeError]:
    """What a repository’s committed `.shipr` declares it deploys to

     The register form’s second question, and usually the answer that there is no second question: a
    declared `[deployments]` shard already names its slug, so the form must not offer an org and a name
    beside it. `deployments: null` is the fallback branch — no file, an unparseable one, or one
    declaring no shards — and is the only case in which `deploymentOwner`/`deploymentName` on `POST
    /shipr/register` are read. `note` carries the parser’s complaint when there was one. A forge that
    cannot be reached is a 502, never a null: a repository that could not be read is not a repository
    that declares nothing.

    Replaces GET /shipr/connections/{id}/declaration (include declaration).

    Args:
        id (str):
        expand (list[str] | Unset):
        include (list[GetV1ShiprConnectionsByIdIncludeItem] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1ShiprConnectionsByIdResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
        expand=expand,
        include=include,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    *,
    client: AuthenticatedClient,
    expand: list[str] | Unset = UNSET,
    include: list[GetV1ShiprConnectionsByIdIncludeItem] | Unset = UNSET,
) -> GetV1ShiprConnectionsByIdResponse200 | StripeError | None:
    """What a repository’s committed `.shipr` declares it deploys to

     The register form’s second question, and usually the answer that there is no second question: a
    declared `[deployments]` shard already names its slug, so the form must not offer an org and a name
    beside it. `deployments: null` is the fallback branch — no file, an unparseable one, or one
    declaring no shards — and is the only case in which `deploymentOwner`/`deploymentName` on `POST
    /shipr/register` are read. `note` carries the parser’s complaint when there was one. A forge that
    cannot be reached is a 502, never a null: a repository that could not be read is not a repository
    that declares nothing.

    Replaces GET /shipr/connections/{id}/declaration (include declaration).

    Args:
        id (str):
        expand (list[str] | Unset):
        include (list[GetV1ShiprConnectionsByIdIncludeItem] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1ShiprConnectionsByIdResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            expand=expand,
            include=include,
        )
    ).parsed
