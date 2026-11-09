from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.get_v1_usage_principal_tiers_by_scope_by_principal_id_response_200 import (
    GetV1UsagePrincipalTiersByScopeByPrincipalIdResponse200,
)
from ...models.stripe_error import StripeError
from ...types import UNSET, Response, Unset


def _get_kwargs(
    scope: str,
    principal_id: str,
    *,
    expand: list[str] | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    json_expand: list[str] | Unset = UNSET
    if not isinstance(expand, Unset):
        json_expand = expand

    params["expand[]"] = json_expand

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/v1/usage/principal_tiers/{scope}/{principal_id}".format(
            scope=quote(str(scope), safe=""),
            principal_id=quote(str(principal_id), safe=""),
        ),
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> GetV1UsagePrincipalTiersByScopeByPrincipalIdResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = GetV1UsagePrincipalTiersByScopeByPrincipalIdResponse200.from_dict(
            response.json()
        )

        return response_200

    if response.status_code == 401:
        response_401 = StripeError.from_dict(response.json())

        return response_401

    if response.status_code == 404:
        response_404 = StripeError.from_dict(response.json())

        return response_404

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[GetV1UsagePrincipalTiersByScopeByPrincipalIdResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    scope: str,
    principal_id: str,
    *,
    client: AuthenticatedClient,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1UsagePrincipalTiersByScopeByPrincipalIdResponse200 | StripeError]:
    """Get principal_tiers by id

     Replaces GET /usage/principal-tiers/{scope}/{principalId}.

    Args:
        scope (str):
        principal_id (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1UsagePrincipalTiersByScopeByPrincipalIdResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        scope=scope,
        principal_id=principal_id,
        expand=expand,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    scope: str,
    principal_id: str,
    *,
    client: AuthenticatedClient,
    expand: list[str] | Unset = UNSET,
) -> GetV1UsagePrincipalTiersByScopeByPrincipalIdResponse200 | StripeError | None:
    """Get principal_tiers by id

     Replaces GET /usage/principal-tiers/{scope}/{principalId}.

    Args:
        scope (str):
        principal_id (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1UsagePrincipalTiersByScopeByPrincipalIdResponse200 | StripeError
    """

    return sync_detailed(
        scope=scope,
        principal_id=principal_id,
        client=client,
        expand=expand,
    ).parsed


async def asyncio_detailed(
    scope: str,
    principal_id: str,
    *,
    client: AuthenticatedClient,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1UsagePrincipalTiersByScopeByPrincipalIdResponse200 | StripeError]:
    """Get principal_tiers by id

     Replaces GET /usage/principal-tiers/{scope}/{principalId}.

    Args:
        scope (str):
        principal_id (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1UsagePrincipalTiersByScopeByPrincipalIdResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        scope=scope,
        principal_id=principal_id,
        expand=expand,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    scope: str,
    principal_id: str,
    *,
    client: AuthenticatedClient,
    expand: list[str] | Unset = UNSET,
) -> GetV1UsagePrincipalTiersByScopeByPrincipalIdResponse200 | StripeError | None:
    """Get principal_tiers by id

     Replaces GET /usage/principal-tiers/{scope}/{principalId}.

    Args:
        scope (str):
        principal_id (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1UsagePrincipalTiersByScopeByPrincipalIdResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            scope=scope,
            principal_id=principal_id,
            client=client,
            expand=expand,
        )
    ).parsed
