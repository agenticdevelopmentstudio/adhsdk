from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.get_game_artifacts_response_200 import GetGameArtifactsResponse200
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    game_id: str | Unset = UNSET,
    slug: str | Unset = UNSET,
    kind: str | Unset = UNSET,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["game_id"] = game_id

    params["slug"] = slug

    params["kind"] = kind

    params["page"] = page

    params["page_size"] = page_size

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/game/artifacts",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | GetGameArtifactsResponse200 | None:
    if response.status_code == 200:
        response_200 = GetGameArtifactsResponse200.from_dict(response.json())

        return response_200

    if response.status_code == 400:
        response_400 = Error.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = Error.from_dict(response.json())

        return response_401

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
) -> Response[Error | GetGameArtifactsResponse200]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    game_id: str | Unset = UNSET,
    slug: str | Unset = UNSET,
    kind: str | Unset = UNSET,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
) -> Response[Error | GetGameArtifactsResponse200]:
    """The caller’s own artifacts for one game

    Args:
        game_id (str | Unset):
        slug (str | Unset):
        kind (str | Unset):
        page (str | Unset):
        page_size (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GetGameArtifactsResponse200]
    """

    kwargs = _get_kwargs(
        game_id=game_id,
        slug=slug,
        kind=kind,
        page=page,
        page_size=page_size,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    game_id: str | Unset = UNSET,
    slug: str | Unset = UNSET,
    kind: str | Unset = UNSET,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
) -> Error | GetGameArtifactsResponse200 | None:
    """The caller’s own artifacts for one game

    Args:
        game_id (str | Unset):
        slug (str | Unset):
        kind (str | Unset):
        page (str | Unset):
        page_size (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GetGameArtifactsResponse200
    """

    return sync_detailed(
        client=client,
        game_id=game_id,
        slug=slug,
        kind=kind,
        page=page,
        page_size=page_size,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    game_id: str | Unset = UNSET,
    slug: str | Unset = UNSET,
    kind: str | Unset = UNSET,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
) -> Response[Error | GetGameArtifactsResponse200]:
    """The caller’s own artifacts for one game

    Args:
        game_id (str | Unset):
        slug (str | Unset):
        kind (str | Unset):
        page (str | Unset):
        page_size (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GetGameArtifactsResponse200]
    """

    kwargs = _get_kwargs(
        game_id=game_id,
        slug=slug,
        kind=kind,
        page=page,
        page_size=page_size,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    game_id: str | Unset = UNSET,
    slug: str | Unset = UNSET,
    kind: str | Unset = UNSET,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
) -> Error | GetGameArtifactsResponse200 | None:
    """The caller’s own artifacts for one game

    Args:
        game_id (str | Unset):
        slug (str | Unset):
        kind (str | Unset):
        page (str | Unset):
        page_size (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GetGameArtifactsResponse200
    """

    return (
        await asyncio_detailed(
            client=client,
            game_id=game_id,
            slug=slug,
            kind=kind,
            page=page,
            page_size=page_size,
        )
    ).parsed
