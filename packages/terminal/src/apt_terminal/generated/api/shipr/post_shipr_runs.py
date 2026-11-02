from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.post_shipr_runs_body import PostShiprRunsBody
from ...models.post_shipr_runs_response_202 import PostShiprRunsResponse202
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    body: PostShiprRunsBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    params: dict[str, Any] = {}

    params["workspace"] = workspace

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/shipr/runs",
        "params": params,
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | PostShiprRunsResponse202 | None:
    if response.status_code == 202:
        response_202 = PostShiprRunsResponse202.from_dict(response.json())

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
) -> Response[Error | PostShiprRunsResponse202]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    body: PostShiprRunsBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> Response[Error | PostShiprRunsResponse202]:
    """Queue any operation over any scope — the toolbar, as one route

     A group scope walks the folder and everything nested under it, depth-first in tree order, one
    repository at a time. The caller must hold the operation’s verb over EVERY repository the scope
    expands to.

    Args:
        workspace (str | Unset):
        body (PostShiprRunsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PostShiprRunsResponse202]
    """

    kwargs = _get_kwargs(
        body=body,
        workspace=workspace,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    body: PostShiprRunsBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> Error | PostShiprRunsResponse202 | None:
    """Queue any operation over any scope — the toolbar, as one route

     A group scope walks the folder and everything nested under it, depth-first in tree order, one
    repository at a time. The caller must hold the operation’s verb over EVERY repository the scope
    expands to.

    Args:
        workspace (str | Unset):
        body (PostShiprRunsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PostShiprRunsResponse202
    """

    return sync_detailed(
        client=client,
        body=body,
        workspace=workspace,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    body: PostShiprRunsBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> Response[Error | PostShiprRunsResponse202]:
    """Queue any operation over any scope — the toolbar, as one route

     A group scope walks the folder and everything nested under it, depth-first in tree order, one
    repository at a time. The caller must hold the operation’s verb over EVERY repository the scope
    expands to.

    Args:
        workspace (str | Unset):
        body (PostShiprRunsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PostShiprRunsResponse202]
    """

    kwargs = _get_kwargs(
        body=body,
        workspace=workspace,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    body: PostShiprRunsBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> Error | PostShiprRunsResponse202 | None:
    """Queue any operation over any scope — the toolbar, as one route

     A group scope walks the folder and everything nested under it, depth-first in tree order, one
    repository at a time. The caller must hold the operation’s verb over EVERY repository the scope
    expands to.

    Args:
        workspace (str | Unset):
        body (PostShiprRunsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PostShiprRunsResponse202
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
            workspace=workspace,
        )
    ).parsed
