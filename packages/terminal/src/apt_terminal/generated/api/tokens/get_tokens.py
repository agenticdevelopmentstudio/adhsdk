from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.token_principal import TokenPrincipal
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    ecosystem_id: str | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["ecosystemId"] = ecosystem_id

    params["workspace"] = workspace

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/tokens",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | list[TokenPrincipal] | None:
    if response.status_code == 200:
        response_200 = []
        _response_200 = response.json()
        for response_200_item_data in _response_200:
            response_200_item = TokenPrincipal.from_dict(response_200_item_data)

            response_200.append(response_200_item)

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
) -> Response[Error | list[TokenPrincipal]]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    ecosystem_id: str | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> Response[Error | list[TokenPrincipal]]:
    """List the caller’s token principals (metadata only; secret never returned)

    Args:
        ecosystem_id (str | Unset):
        workspace (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | list[TokenPrincipal]]
    """

    kwargs = _get_kwargs(
        ecosystem_id=ecosystem_id,
        workspace=workspace,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    ecosystem_id: str | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> Error | list[TokenPrincipal] | None:
    """List the caller’s token principals (metadata only; secret never returned)

    Args:
        ecosystem_id (str | Unset):
        workspace (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | list[TokenPrincipal]
    """

    return sync_detailed(
        client=client,
        ecosystem_id=ecosystem_id,
        workspace=workspace,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    ecosystem_id: str | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> Response[Error | list[TokenPrincipal]]:
    """List the caller’s token principals (metadata only; secret never returned)

    Args:
        ecosystem_id (str | Unset):
        workspace (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | list[TokenPrincipal]]
    """

    kwargs = _get_kwargs(
        ecosystem_id=ecosystem_id,
        workspace=workspace,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    ecosystem_id: str | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> Error | list[TokenPrincipal] | None:
    """List the caller’s token principals (metadata only; secret never returned)

    Args:
        ecosystem_id (str | Unset):
        workspace (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | list[TokenPrincipal]
    """

    return (
        await asyncio_detailed(
            client=client,
            ecosystem_id=ecosystem_id,
            workspace=workspace,
        )
    ).parsed
