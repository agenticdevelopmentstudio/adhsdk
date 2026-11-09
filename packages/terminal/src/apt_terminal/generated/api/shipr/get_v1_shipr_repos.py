from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.get_v1_shipr_repos_response_200 import GetV1ShiprReposResponse200
from ...models.stripe_error import StripeError
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    workspace: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["workspace"] = workspace

    json_expand: list[str] | Unset = UNSET
    if not isinstance(expand, Unset):
        json_expand = expand

    params["expand[]"] = json_expand

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/v1/shipr/repos",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> GetV1ShiprReposResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = GetV1ShiprReposResponse200.from_dict(response.json())

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

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[GetV1ShiprReposResponse200 | StripeError]:
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
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1ShiprReposResponse200 | StripeError]:
    """The whole tree: every folder and repository the caller reaches

     One request, because the tree is one component. A repository the caller has no grant on is ABSENT,
    not greyed out; a folder with nothing reachable in it is absent too, unless the caller holds
    workspace-level R.

    Replaces GET /shipr/repos.

    Args:
        workspace (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1ShiprReposResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        workspace=workspace,
        expand=expand,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    workspace: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> GetV1ShiprReposResponse200 | StripeError | None:
    """The whole tree: every folder and repository the caller reaches

     One request, because the tree is one component. A repository the caller has no grant on is ABSENT,
    not greyed out; a folder with nothing reachable in it is absent too, unless the caller holds
    workspace-level R.

    Replaces GET /shipr/repos.

    Args:
        workspace (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1ShiprReposResponse200 | StripeError
    """

    return sync_detailed(
        client=client,
        workspace=workspace,
        expand=expand,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    workspace: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1ShiprReposResponse200 | StripeError]:
    """The whole tree: every folder and repository the caller reaches

     One request, because the tree is one component. A repository the caller has no grant on is ABSENT,
    not greyed out; a folder with nothing reachable in it is absent too, unless the caller holds
    workspace-level R.

    Replaces GET /shipr/repos.

    Args:
        workspace (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1ShiprReposResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        workspace=workspace,
        expand=expand,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    workspace: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> GetV1ShiprReposResponse200 | StripeError | None:
    """The whole tree: every folder and repository the caller reaches

     One request, because the tree is one component. A repository the caller has no grant on is ABSENT,
    not greyed out; a folder with nothing reachable in it is absent too, unless the caller holds
    workspace-level R.

    Replaces GET /shipr/repos.

    Args:
        workspace (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1ShiprReposResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            client=client,
            workspace=workspace,
            expand=expand,
        )
    ).parsed
