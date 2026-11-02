from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.usage_summary import UsageSummary
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
        "url": "/usage/summary",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | UsageSummary | None:
    if response.status_code == 200:
        response_200 = UsageSummary.from_dict(response.json())

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
) -> Response[Error | UsageSummary]:
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
) -> Response[Error | UsageSummary]:
    """Current-period usage per principal (self, or a workspace)

     Without `workspace`: the caller (self + API tokens + owned personas). With `workspace`: that
    workspace's principals — a personal workspace resolves only for its owner; an organization returns
    its member roster plus org-owned personas and requires workspace admin. The ecosystem's billing row
    is appended for platform admins only.

    Args:
        workspace (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | UsageSummary]
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
) -> Error | UsageSummary | None:
    """Current-period usage per principal (self, or a workspace)

     Without `workspace`: the caller (self + API tokens + owned personas). With `workspace`: that
    workspace's principals — a personal workspace resolves only for its owner; an organization returns
    its member roster plus org-owned personas and requires workspace admin. The ecosystem's billing row
    is appended for platform admins only.

    Args:
        workspace (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | UsageSummary
    """

    return sync_detailed(
        client=client,
        workspace=workspace,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    workspace: str | Unset = UNSET,
) -> Response[Error | UsageSummary]:
    """Current-period usage per principal (self, or a workspace)

     Without `workspace`: the caller (self + API tokens + owned personas). With `workspace`: that
    workspace's principals — a personal workspace resolves only for its owner; an organization returns
    its member roster plus org-owned personas and requires workspace admin. The ecosystem's billing row
    is appended for platform admins only.

    Args:
        workspace (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | UsageSummary]
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
) -> Error | UsageSummary | None:
    """Current-period usage per principal (self, or a workspace)

     Without `workspace`: the caller (self + API tokens + owned personas). With `workspace`: that
    workspace's principals — a personal workspace resolves only for its owner; an organization returns
    its member roster plus org-owned personas and requires workspace admin. The ecosystem's billing row
    is appended for platform admins only.

    Args:
        workspace (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | UsageSummary
    """

    return (
        await asyncio_detailed(
            client=client,
            workspace=workspace,
        )
    ).parsed
