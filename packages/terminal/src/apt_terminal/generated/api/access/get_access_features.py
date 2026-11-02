from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.access_feature_list import AccessFeatureList
from ...models.error import Error
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
        "url": "/access/features",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> AccessFeatureList | Error | None:
    if response.status_code == 200:
        response_200 = AccessFeatureList.from_dict(response.json())

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
) -> Response[AccessFeatureList | Error]:
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
) -> Response[AccessFeatureList | Error]:
    """List the feature areas this deployment enforces (key + display label)

     The server-side registry (src/lib/feature-areas.ts) grants are recorded against. The shared roles
    editor renders one row per entry rather than a hardcoded list, so an area can be granted AND
    withheld on a custom role. Members only; non-members get 404.

    Args:
        workspace (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[AccessFeatureList | Error]
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
) -> AccessFeatureList | Error | None:
    """List the feature areas this deployment enforces (key + display label)

     The server-side registry (src/lib/feature-areas.ts) grants are recorded against. The shared roles
    editor renders one row per entry rather than a hardcoded list, so an area can be granted AND
    withheld on a custom role. Members only; non-members get 404.

    Args:
        workspace (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        AccessFeatureList | Error
    """

    return sync_detailed(
        client=client,
        workspace=workspace,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    workspace: str,
) -> Response[AccessFeatureList | Error]:
    """List the feature areas this deployment enforces (key + display label)

     The server-side registry (src/lib/feature-areas.ts) grants are recorded against. The shared roles
    editor renders one row per entry rather than a hardcoded list, so an area can be granted AND
    withheld on a custom role. Members only; non-members get 404.

    Args:
        workspace (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[AccessFeatureList | Error]
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
) -> AccessFeatureList | Error | None:
    """List the feature areas this deployment enforces (key + display label)

     The server-side registry (src/lib/feature-areas.ts) grants are recorded against. The shared roles
    editor renders one row per entry rather than a hardcoded list, so an area can be granted AND
    withheld on a custom role. Members only; non-members get 404.

    Args:
        workspace (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        AccessFeatureList | Error
    """

    return (
        await asyncio_detailed(
            client=client,
            workspace=workspace,
        )
    ).parsed
