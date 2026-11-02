from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.organization_list_row import OrganizationListRow
from ...types import UNSET, Response


def _get_kwargs(
    *,
    workspace: str,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["workspace"] = workspace

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/organization/organizations",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | list[OrganizationListRow] | None:
    if response.status_code == 200:
        response_200 = []
        _response_200 = response.json()
        for response_200_item_data in _response_200:
            response_200_item = OrganizationListRow.from_dict(response_200_item_data)

            response_200.append(response_200_item)

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

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | list[OrganizationListRow]]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    workspace: str,
) -> Response[Error | list[OrganizationListRow]]:
    """List the organizations a workspace owns (personal workspaces also include the ones you belong to)

     Scoped by `workspace`, which is REQUIRED — an unscoped organizations list is the same answer in
    every workspace, which is the bug this replaced. A PERSONAL workspace answers with the orgs you own
    UNION the orgs you belong to; an ORGANIZATION workspace answers with the orgs that org owns, never
    including itself. A workspace slug the caller neither owns nor reaches is a 404, the same answer as
    one that does not exist. Ordered by name (case-insensitively, ties broken by id) and capped at 500
    rows.

    Args:
        workspace (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | list[OrganizationListRow]]
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
    workspace: str,
) -> Error | list[OrganizationListRow] | None:
    """List the organizations a workspace owns (personal workspaces also include the ones you belong to)

     Scoped by `workspace`, which is REQUIRED — an unscoped organizations list is the same answer in
    every workspace, which is the bug this replaced. A PERSONAL workspace answers with the orgs you own
    UNION the orgs you belong to; an ORGANIZATION workspace answers with the orgs that org owns, never
    including itself. A workspace slug the caller neither owns nor reaches is a 404, the same answer as
    one that does not exist. Ordered by name (case-insensitively, ties broken by id) and capped at 500
    rows.

    Args:
        workspace (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | list[OrganizationListRow]
    """

    return sync_detailed(
        client=client,
        workspace=workspace,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    workspace: str,
) -> Response[Error | list[OrganizationListRow]]:
    """List the organizations a workspace owns (personal workspaces also include the ones you belong to)

     Scoped by `workspace`, which is REQUIRED — an unscoped organizations list is the same answer in
    every workspace, which is the bug this replaced. A PERSONAL workspace answers with the orgs you own
    UNION the orgs you belong to; an ORGANIZATION workspace answers with the orgs that org owns, never
    including itself. A workspace slug the caller neither owns nor reaches is a 404, the same answer as
    one that does not exist. Ordered by name (case-insensitively, ties broken by id) and capped at 500
    rows.

    Args:
        workspace (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | list[OrganizationListRow]]
    """

    kwargs = _get_kwargs(
        workspace=workspace,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    workspace: str,
) -> Error | list[OrganizationListRow] | None:
    """List the organizations a workspace owns (personal workspaces also include the ones you belong to)

     Scoped by `workspace`, which is REQUIRED — an unscoped organizations list is the same answer in
    every workspace, which is the bug this replaced. A PERSONAL workspace answers with the orgs you own
    UNION the orgs you belong to; an ORGANIZATION workspace answers with the orgs that org owns, never
    including itself. A workspace slug the caller neither owns nor reaches is a 404, the same answer as
    one that does not exist. Ordered by name (case-insensitively, ties broken by id) and capped at 500
    rows.

    Args:
        workspace (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | list[OrganizationListRow]
    """

    return (
        await asyncio_detailed(
            client=client,
            workspace=workspace,
        )
    ).parsed
