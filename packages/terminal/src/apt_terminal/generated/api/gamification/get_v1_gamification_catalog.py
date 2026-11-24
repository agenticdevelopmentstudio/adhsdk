from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.get_v1_gamification_catalog_response_200 import GetV1GamificationCatalogResponse200
from ...models.stripe_error import StripeError
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    ecosystem: str,
    expand: list[str] | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["ecosystem"] = ecosystem

    json_expand: list[str] | Unset = UNSET
    if not isinstance(expand, Unset):
        json_expand = expand

    params["expand[]"] = json_expand

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/v1/gamification/catalog",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> GetV1GamificationCatalogResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = GetV1GamificationCatalogResponse200.from_dict(response.json())

        return response_200

    if response.status_code == 400:
        response_400 = StripeError.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = StripeError.from_dict(response.json())

        return response_401

    if response.status_code == 403:
        response_403 = StripeError.from_dict(response.json())

        return response_403

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[GetV1GamificationCatalogResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    ecosystem: str,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1GamificationCatalogResponse200 | StripeError]:
    """A realm’s effective catalog (admin) — defaults + realm overrides, source-tagged

     Replaces GET /gamification/realms/{ecosystemId}/catalog.

    Args:
        ecosystem (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1GamificationCatalogResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        ecosystem=ecosystem,
        expand=expand,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    ecosystem: str,
    expand: list[str] | Unset = UNSET,
) -> GetV1GamificationCatalogResponse200 | StripeError | None:
    """A realm’s effective catalog (admin) — defaults + realm overrides, source-tagged

     Replaces GET /gamification/realms/{ecosystemId}/catalog.

    Args:
        ecosystem (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1GamificationCatalogResponse200 | StripeError
    """

    return sync_detailed(
        client=client,
        ecosystem=ecosystem,
        expand=expand,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    ecosystem: str,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1GamificationCatalogResponse200 | StripeError]:
    """A realm’s effective catalog (admin) — defaults + realm overrides, source-tagged

     Replaces GET /gamification/realms/{ecosystemId}/catalog.

    Args:
        ecosystem (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1GamificationCatalogResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        ecosystem=ecosystem,
        expand=expand,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    ecosystem: str,
    expand: list[str] | Unset = UNSET,
) -> GetV1GamificationCatalogResponse200 | StripeError | None:
    """A realm’s effective catalog (admin) — defaults + realm overrides, source-tagged

     Replaces GET /gamification/realms/{ecosystemId}/catalog.

    Args:
        ecosystem (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1GamificationCatalogResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            client=client,
            ecosystem=ecosystem,
            expand=expand,
        )
    ).parsed
