from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.post_registry_registries_body import PostRegistryRegistriesBody
from ...models.registry import Registry
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    body: PostRegistryRegistriesBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    params: dict[str, Any] = {}

    params["workspace"] = workspace

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/registry/registries",
        "params": params,
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | Registry | None:
    if response.status_code == 201:
        response_201 = Registry.from_dict(response.json())

        return response_201

    if response.status_code == 400:
        response_400 = Error.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = Error.from_dict(response.json())

        return response_401

    if response.status_code == 404:
        response_404 = Error.from_dict(response.json())

        return response_404

    if response.status_code == 409:
        response_409 = Error.from_dict(response.json())

        return response_409

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | Registry]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    body: PostRegistryRegistriesBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> Response[Error | Registry]:
    """Create a registry

    Args:
        workspace (str | Unset):
        body (PostRegistryRegistriesBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | Registry]
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
    body: PostRegistryRegistriesBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> Error | Registry | None:
    """Create a registry

    Args:
        workspace (str | Unset):
        body (PostRegistryRegistriesBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | Registry
    """

    return sync_detailed(
        client=client,
        body=body,
        workspace=workspace,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    body: PostRegistryRegistriesBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> Response[Error | Registry]:
    """Create a registry

    Args:
        workspace (str | Unset):
        body (PostRegistryRegistriesBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | Registry]
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
    body: PostRegistryRegistriesBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> Error | Registry | None:
    """Create a registry

    Args:
        workspace (str | Unset):
        body (PostRegistryRegistriesBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | Registry
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
            workspace=workspace,
        )
    ).parsed
