from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.feature_flag import FeatureFlag
from ...models.get_system_feature_flags_scope import GetSystemFeatureFlagsScope
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    scope: GetSystemFeatureFlagsScope | Unset = UNSET,
    key: str | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    json_scope: str | Unset = UNSET
    if not isinstance(scope, Unset):
        json_scope = scope.value

    params["scope"] = json_scope

    params["key"] = key

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/system/feature-flags",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> list[FeatureFlag] | None:
    if response.status_code == 200:
        response_200 = []
        _response_200 = response.json()
        for response_200_item_data in _response_200:
            response_200_item = FeatureFlag.from_dict(response_200_item_data)

            response_200.append(response_200_item)

        return response_200

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[list[FeatureFlag]]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient | Client,
    scope: GetSystemFeatureFlagsScope | Unset = UNSET,
    key: str | Unset = UNSET,
) -> Response[list[FeatureFlag]]:
    """List feature flags (public; optional ?scope=system and ?key= exact-match filter)

    Args:
        scope (GetSystemFeatureFlagsScope | Unset):
        key (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[list[FeatureFlag]]
    """

    kwargs = _get_kwargs(
        scope=scope,
        key=key,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient | Client,
    scope: GetSystemFeatureFlagsScope | Unset = UNSET,
    key: str | Unset = UNSET,
) -> list[FeatureFlag] | None:
    """List feature flags (public; optional ?scope=system and ?key= exact-match filter)

    Args:
        scope (GetSystemFeatureFlagsScope | Unset):
        key (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        list[FeatureFlag]
    """

    return sync_detailed(
        client=client,
        scope=scope,
        key=key,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient | Client,
    scope: GetSystemFeatureFlagsScope | Unset = UNSET,
    key: str | Unset = UNSET,
) -> Response[list[FeatureFlag]]:
    """List feature flags (public; optional ?scope=system and ?key= exact-match filter)

    Args:
        scope (GetSystemFeatureFlagsScope | Unset):
        key (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[list[FeatureFlag]]
    """

    kwargs = _get_kwargs(
        scope=scope,
        key=key,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient | Client,
    scope: GetSystemFeatureFlagsScope | Unset = UNSET,
    key: str | Unset = UNSET,
) -> list[FeatureFlag] | None:
    """List feature flags (public; optional ?scope=system and ?key= exact-match filter)

    Args:
        scope (GetSystemFeatureFlagsScope | Unset):
        key (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        list[FeatureFlag]
    """

    return (
        await asyncio_detailed(
            client=client,
            scope=scope,
            key=key,
        )
    ).parsed
