from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.get_shipr_repos_id_platforms_response_200 import GetShiprReposIdPlatformsResponse200
from ...types import Response


def _get_kwargs(
    id: str,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/shipr/repos/{id}/platforms".format(
            id=quote(str(id), safe=""),
        ),
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | GetShiprReposIdPlatformsResponse200 | None:
    if response.status_code == 200:
        response_200 = GetShiprReposIdPlatformsResponse200.from_dict(response.json())

        return response_200

    if response.status_code == 401:
        response_401 = Error.from_dict(response.json())

        return response_401

    if response.status_code == 403:
        response_403 = Error.from_dict(response.json())

        return response_403

    if response.status_code == 404:
        response_404 = Error.from_dict(response.json())

        return response_404

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | GetShiprReposIdPlatformsResponse200]:
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
) -> Response[Error | GetShiprReposIdPlatformsResponse200]:
    """Which platform credentials watch this repository

     Addressed through a mirror, stored against its dev repo: every mirror of a repository shares one
    credential per platform, because the platform watches the deployment repository they all push to.
    `label` is null when the connection behind a row has been deleted — that pipeline falls back to 'the
    push is the deployment' on its next deploy.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GetShiprReposIdPlatformsResponse200]
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
) -> Error | GetShiprReposIdPlatformsResponse200 | None:
    """Which platform credentials watch this repository

     Addressed through a mirror, stored against its dev repo: every mirror of a repository shares one
    credential per platform, because the platform watches the deployment repository they all push to.
    `label` is null when the connection behind a row has been deleted — that pipeline falls back to 'the
    push is the deployment' on its next deploy.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GetShiprReposIdPlatformsResponse200
    """

    return sync_detailed(
        id=id,
        client=client,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
) -> Response[Error | GetShiprReposIdPlatformsResponse200]:
    """Which platform credentials watch this repository

     Addressed through a mirror, stored against its dev repo: every mirror of a repository shares one
    credential per platform, because the platform watches the deployment repository they all push to.
    `label` is null when the connection behind a row has been deleted — that pipeline falls back to 'the
    push is the deployment' on its next deploy.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GetShiprReposIdPlatformsResponse200]
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
) -> Error | GetShiprReposIdPlatformsResponse200 | None:
    """Which platform credentials watch this repository

     Addressed through a mirror, stored against its dev repo: every mirror of a repository shares one
    credential per platform, because the platform watches the deployment repository they all push to.
    `label` is null when the connection behind a row has been deleted — that pipeline falls back to 'the
    push is the deployment' on its next deploy.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GetShiprReposIdPlatformsResponse200
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
        )
    ).parsed
