from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.get_shipr_repos_response_200 import GetShiprReposResponse200
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    workspace: str | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["workspace"] = workspace

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/shipr/repos",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | GetShiprReposResponse200 | None:
    if response.status_code == 200:
        response_200 = GetShiprReposResponse200.from_dict(response.json())

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
) -> Response[Error | GetShiprReposResponse200]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    workspace: str | Unset = UNSET,
) -> Response[Error | GetShiprReposResponse200]:
    """The whole tree: every folder and repository the caller reaches

     One request, because the tree is one component. A repository the caller has no grant on is ABSENT,
    not greyed out; a folder with nothing reachable in it is absent too, unless the caller holds
    workspace-level R.

    Args:
        workspace (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GetShiprReposResponse200]
    """

    kwargs = _get_kwargs(
        workspace=workspace,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    workspace: str | Unset = UNSET,
) -> Error | GetShiprReposResponse200 | None:
    """The whole tree: every folder and repository the caller reaches

     One request, because the tree is one component. A repository the caller has no grant on is ABSENT,
    not greyed out; a folder with nothing reachable in it is absent too, unless the caller holds
    workspace-level R.

    Args:
        workspace (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GetShiprReposResponse200
    """

    return sync_detailed(
        client=client,
        workspace=workspace,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    workspace: str | Unset = UNSET,
) -> Response[Error | GetShiprReposResponse200]:
    """The whole tree: every folder and repository the caller reaches

     One request, because the tree is one component. A repository the caller has no grant on is ABSENT,
    not greyed out; a folder with nothing reachable in it is absent too, unless the caller holds
    workspace-level R.

    Args:
        workspace (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GetShiprReposResponse200]
    """

    kwargs = _get_kwargs(
        workspace=workspace,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    workspace: str | Unset = UNSET,
) -> Error | GetShiprReposResponse200 | None:
    """The whole tree: every folder and repository the caller reaches

     One request, because the tree is one component. A repository the caller has no grant on is ABSENT,
    not greyed out; a folder with nothing reachable in it is absent too, unless the caller holds
    workspace-level R.

    Args:
        workspace (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GetShiprReposResponse200
    """

    return (
        await asyncio_detailed(
            client=client,
            workspace=workspace,
        )
    ).parsed
