from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.get_v1_provider_templates_by_id_include_item import (
    GetV1ProviderTemplatesByIdIncludeItem,
)
from ...models.get_v1_provider_templates_by_id_response_200 import (
    GetV1ProviderTemplatesByIdResponse200,
)
from ...models.stripe_error import StripeError
from ...types import UNSET, Response, Unset


def _get_kwargs(
    id: str,
    *,
    expand: list[str] | Unset = UNSET,
    include: list[GetV1ProviderTemplatesByIdIncludeItem] | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    json_expand: list[str] | Unset = UNSET
    if not isinstance(expand, Unset):
        json_expand = expand

    params["expand[]"] = json_expand

    json_include: list[str] | Unset = UNSET
    if not isinstance(include, Unset):
        json_include = []
        for include_item_data in include:
            include_item = include_item_data.value
            json_include.append(include_item)

    params["include[]"] = json_include

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/v1/provider_templates/{id}".format(
            id=quote(str(id), safe=""),
        ),
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> GetV1ProviderTemplatesByIdResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = GetV1ProviderTemplatesByIdResponse200.from_dict(response.json())

        return response_200

    if response.status_code == 401:
        response_401 = StripeError.from_dict(response.json())

        return response_401

    if response.status_code == 403:
        response_403 = StripeError.from_dict(response.json())

        return response_403

    if response.status_code == 404:
        response_404 = StripeError.from_dict(response.json())

        return response_404

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[GetV1ProviderTemplatesByIdResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
    expand: list[str] | Unset = UNSET,
    include: list[GetV1ProviderTemplatesByIdIncludeItem] | Unset = UNSET,
) -> Response[GetV1ProviderTemplatesByIdResponse200 | StripeError]:
    """One provider template with its models (public)

     Replaces GET /persona/provider-templates/{id}, GET /persona/provider-templates/{id}/sync-keys
    (include sync_keys).

    Args:
        id (str):
        expand (list[str] | Unset):
        include (list[GetV1ProviderTemplatesByIdIncludeItem] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1ProviderTemplatesByIdResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
        expand=expand,
        include=include,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    *,
    client: AuthenticatedClient,
    expand: list[str] | Unset = UNSET,
    include: list[GetV1ProviderTemplatesByIdIncludeItem] | Unset = UNSET,
) -> GetV1ProviderTemplatesByIdResponse200 | StripeError | None:
    """One provider template with its models (public)

     Replaces GET /persona/provider-templates/{id}, GET /persona/provider-templates/{id}/sync-keys
    (include sync_keys).

    Args:
        id (str):
        expand (list[str] | Unset):
        include (list[GetV1ProviderTemplatesByIdIncludeItem] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1ProviderTemplatesByIdResponse200 | StripeError
    """

    return sync_detailed(
        id=id,
        client=client,
        expand=expand,
        include=include,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
    expand: list[str] | Unset = UNSET,
    include: list[GetV1ProviderTemplatesByIdIncludeItem] | Unset = UNSET,
) -> Response[GetV1ProviderTemplatesByIdResponse200 | StripeError]:
    """One provider template with its models (public)

     Replaces GET /persona/provider-templates/{id}, GET /persona/provider-templates/{id}/sync-keys
    (include sync_keys).

    Args:
        id (str):
        expand (list[str] | Unset):
        include (list[GetV1ProviderTemplatesByIdIncludeItem] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1ProviderTemplatesByIdResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
        expand=expand,
        include=include,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    *,
    client: AuthenticatedClient,
    expand: list[str] | Unset = UNSET,
    include: list[GetV1ProviderTemplatesByIdIncludeItem] | Unset = UNSET,
) -> GetV1ProviderTemplatesByIdResponse200 | StripeError | None:
    """One provider template with its models (public)

     Replaces GET /persona/provider-templates/{id}, GET /persona/provider-templates/{id}/sync-keys
    (include sync_keys).

    Args:
        id (str):
        expand (list[str] | Unset):
        include (list[GetV1ProviderTemplatesByIdIncludeItem] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1ProviderTemplatesByIdResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            expand=expand,
            include=include,
        )
    ).parsed
