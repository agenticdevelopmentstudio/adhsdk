from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.get_project_triage_response_200 import GetProjectTriageResponse200
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    workspace: str | Unset = UNSET,
    limit: int | Unset = 50,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["workspace"] = workspace

    params["limit"] = limit

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/project/triage",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | GetProjectTriageResponse200 | None:
    if response.status_code == 200:
        response_200 = GetProjectTriageResponse200.from_dict(response.json())

        return response_200

    if response.status_code == 401:
        response_401 = Error.from_dict(response.json())

        return response_401

    if response.status_code == 404:
        response_404 = Error.from_dict(response.json())

        return response_404

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | GetProjectTriageResponse200]:
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
    limit: int | Unset = 50,
) -> Response[Error | GetProjectTriageResponse200]:
    """Every reachable board's untriaged cards, oldest first

     The surface someone clearing a queue actually wants, because an intake that spans boards is the case
    an inbox is for. Built on the same reachable-projects join the cross-project search uses, and
    carrying the same property: the bound IS the authorization, so there is no version of this query
    that reads a board the caller cannot open. Rows are thinner than a WorkItem — see TriageHit.

    Args:
        workspace (str | Unset):
        limit (int | Unset):  Default: 50.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GetProjectTriageResponse200]
    """

    kwargs = _get_kwargs(
        workspace=workspace,
        limit=limit,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    workspace: str | Unset = UNSET,
    limit: int | Unset = 50,
) -> Error | GetProjectTriageResponse200 | None:
    """Every reachable board's untriaged cards, oldest first

     The surface someone clearing a queue actually wants, because an intake that spans boards is the case
    an inbox is for. Built on the same reachable-projects join the cross-project search uses, and
    carrying the same property: the bound IS the authorization, so there is no version of this query
    that reads a board the caller cannot open. Rows are thinner than a WorkItem — see TriageHit.

    Args:
        workspace (str | Unset):
        limit (int | Unset):  Default: 50.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GetProjectTriageResponse200
    """

    return sync_detailed(
        client=client,
        workspace=workspace,
        limit=limit,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    workspace: str | Unset = UNSET,
    limit: int | Unset = 50,
) -> Response[Error | GetProjectTriageResponse200]:
    """Every reachable board's untriaged cards, oldest first

     The surface someone clearing a queue actually wants, because an intake that spans boards is the case
    an inbox is for. Built on the same reachable-projects join the cross-project search uses, and
    carrying the same property: the bound IS the authorization, so there is no version of this query
    that reads a board the caller cannot open. Rows are thinner than a WorkItem — see TriageHit.

    Args:
        workspace (str | Unset):
        limit (int | Unset):  Default: 50.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GetProjectTriageResponse200]
    """

    kwargs = _get_kwargs(
        workspace=workspace,
        limit=limit,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    workspace: str | Unset = UNSET,
    limit: int | Unset = 50,
) -> Error | GetProjectTriageResponse200 | None:
    """Every reachable board's untriaged cards, oldest first

     The surface someone clearing a queue actually wants, because an intake that spans boards is the case
    an inbox is for. Built on the same reachable-projects join the cross-project search uses, and
    carrying the same property: the bound IS the authorization, so there is no version of this query
    that reads a board the caller cannot open. Rows are thinner than a WorkItem — see TriageHit.

    Args:
        workspace (str | Unset):
        limit (int | Unset):  Default: 50.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GetProjectTriageResponse200
    """

    return (
        await asyncio_detailed(
            client=client,
            workspace=workspace,
            limit=limit,
        )
    ).parsed
