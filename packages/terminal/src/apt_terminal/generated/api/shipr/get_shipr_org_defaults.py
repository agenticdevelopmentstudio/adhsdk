from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.get_shipr_org_defaults_response_200 import GetShiprOrgDefaultsResponse200
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
        "url": "/shipr/org-defaults",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | GetShiprOrgDefaultsResponse200 | None:
    if response.status_code == 200:
        response_200 = GetShiprOrgDefaultsResponse200.from_dict(response.json())

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
) -> Response[Error | GetShiprOrgDefaultsResponse200]:
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
) -> Response[Error | GetShiprOrgDefaultsResponse200]:
    """The per-org defaults, all of them

     A LIST AND NOT A LOOKUP: the menu that opens the Settings dialog already shows every org the
    caller’s installations reach, so one request fills every gear icon and an org nobody has configured
    is simply absent rather than a 404 the client has to read as “unset”.

    Args:
        workspace (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GetShiprOrgDefaultsResponse200]
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
) -> Error | GetShiprOrgDefaultsResponse200 | None:
    """The per-org defaults, all of them

     A LIST AND NOT A LOOKUP: the menu that opens the Settings dialog already shows every org the
    caller’s installations reach, so one request fills every gear icon and an org nobody has configured
    is simply absent rather than a 404 the client has to read as “unset”.

    Args:
        workspace (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GetShiprOrgDefaultsResponse200
    """

    return sync_detailed(
        client=client,
        workspace=workspace,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    workspace: str | Unset = UNSET,
) -> Response[Error | GetShiprOrgDefaultsResponse200]:
    """The per-org defaults, all of them

     A LIST AND NOT A LOOKUP: the menu that opens the Settings dialog already shows every org the
    caller’s installations reach, so one request fills every gear icon and an org nobody has configured
    is simply absent rather than a 404 the client has to read as “unset”.

    Args:
        workspace (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GetShiprOrgDefaultsResponse200]
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
) -> Error | GetShiprOrgDefaultsResponse200 | None:
    """The per-org defaults, all of them

     A LIST AND NOT A LOOKUP: the menu that opens the Settings dialog already shows every org the
    caller’s installations reach, so one request fills every gear icon and an org nobody has configured
    is simply absent rather than a 404 the client has to read as “unset”.

    Args:
        workspace (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GetShiprOrgDefaultsResponse200
    """

    return (
        await asyncio_detailed(
            client=client,
            workspace=workspace,
        )
    ).parsed
