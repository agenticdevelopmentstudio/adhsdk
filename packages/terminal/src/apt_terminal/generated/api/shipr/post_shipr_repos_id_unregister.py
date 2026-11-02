from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.post_shipr_repos_id_unregister_body import PostShiprReposIdUnregisterBody
from ...models.post_shipr_repos_id_unregister_response_202 import (
    PostShiprReposIdUnregisterResponse202,
)
from ...types import UNSET, Response, Unset


def _get_kwargs(
    id: str,
    *,
    body: PostShiprReposIdUnregisterBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/shipr/repos/{id}/unregister".format(
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
) -> Error | PostShiprReposIdUnregisterResponse202 | None:
    if response.status_code == 202:
        response_202 = PostShiprReposIdUnregisterResponse202.from_dict(response.json())

        return response_202

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

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | PostShiprReposIdUnregisterResponse202]:
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
    body: PostShiprReposIdUnregisterBody | Unset = UNSET,
) -> Response[Error | PostShiprReposIdUnregisterResponse202]:
    """Queue a unregister for this repository

     Sugar over POST /shipr/runs with scopeKind=deploy_repo. Returns immediately with a run id — watch it
    on /shipr/stream/runs/{id}.

    Args:
        id (str):
        body (PostShiprReposIdUnregisterBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PostShiprReposIdUnregisterResponse202]
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
    body: PostShiprReposIdUnregisterBody | Unset = UNSET,
) -> Error | PostShiprReposIdUnregisterResponse202 | None:
    """Queue a unregister for this repository

     Sugar over POST /shipr/runs with scopeKind=deploy_repo. Returns immediately with a run id — watch it
    on /shipr/stream/runs/{id}.

    Args:
        id (str):
        body (PostShiprReposIdUnregisterBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PostShiprReposIdUnregisterResponse202
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
    body: PostShiprReposIdUnregisterBody | Unset = UNSET,
) -> Response[Error | PostShiprReposIdUnregisterResponse202]:
    """Queue a unregister for this repository

     Sugar over POST /shipr/runs with scopeKind=deploy_repo. Returns immediately with a run id — watch it
    on /shipr/stream/runs/{id}.

    Args:
        id (str):
        body (PostShiprReposIdUnregisterBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PostShiprReposIdUnregisterResponse202]
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
    body: PostShiprReposIdUnregisterBody | Unset = UNSET,
) -> Error | PostShiprReposIdUnregisterResponse202 | None:
    """Queue a unregister for this repository

     Sugar over POST /shipr/runs with scopeKind=deploy_repo. Returns immediately with a run id — watch it
    on /shipr/stream/runs/{id}.

    Args:
        id (str):
        body (PostShiprReposIdUnregisterBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PostShiprReposIdUnregisterResponse202
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            body=body,
        )
    ).parsed
