from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.get_v1_account_include_item import GetV1AccountIncludeItem
from ...models.get_v1_account_response_200 import GetV1AccountResponse200
from ...models.stripe_error import StripeError
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    expand: list[str] | Unset = UNSET,
    include: list[GetV1AccountIncludeItem] | Unset = UNSET,
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
        "url": "/v1/account",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> GetV1AccountResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = GetV1AccountResponse200.from_dict(response.json())

        return response_200

    if response.status_code == 400:
        response_400 = StripeError.from_dict(response.json())

        return response_400

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
) -> Response[GetV1AccountResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    expand: list[str] | Unset = UNSET,
    include: list[GetV1AccountIncludeItem] | Unset = UNSET,
) -> Response[GetV1AccountResponse200 | StripeError]:
    """Current user

     A platform token answers the hub user (User). An end-customer token (client-auth) answers its
    customer record in the customer realm instead — the CustomerMe schema, linked from the 200
    response's `x-customer-realm`. For a customer token, a customer row that is gone (or an ecosystem
    that is deleted, archived or has login disabled) is 401, never 404; 404 is the platform user-not-
    found case only.

    Replaces GET /auth/me, GET /account/privacy (include privacy), GET /me/appearance (include
    appearance), GET /me/communication-settings (include communication_settings), GET /me/workspace-
    prefs (include workspace_prefs).

    Args:
        expand (list[str] | Unset):
        include (list[GetV1AccountIncludeItem] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1AccountResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        expand=expand,
        include=include,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    expand: list[str] | Unset = UNSET,
    include: list[GetV1AccountIncludeItem] | Unset = UNSET,
) -> GetV1AccountResponse200 | StripeError | None:
    """Current user

     A platform token answers the hub user (User). An end-customer token (client-auth) answers its
    customer record in the customer realm instead — the CustomerMe schema, linked from the 200
    response's `x-customer-realm`. For a customer token, a customer row that is gone (or an ecosystem
    that is deleted, archived or has login disabled) is 401, never 404; 404 is the platform user-not-
    found case only.

    Replaces GET /auth/me, GET /account/privacy (include privacy), GET /me/appearance (include
    appearance), GET /me/communication-settings (include communication_settings), GET /me/workspace-
    prefs (include workspace_prefs).

    Args:
        expand (list[str] | Unset):
        include (list[GetV1AccountIncludeItem] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1AccountResponse200 | StripeError
    """

    return sync_detailed(
        client=client,
        expand=expand,
        include=include,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    expand: list[str] | Unset = UNSET,
    include: list[GetV1AccountIncludeItem] | Unset = UNSET,
) -> Response[GetV1AccountResponse200 | StripeError]:
    """Current user

     A platform token answers the hub user (User). An end-customer token (client-auth) answers its
    customer record in the customer realm instead — the CustomerMe schema, linked from the 200
    response's `x-customer-realm`. For a customer token, a customer row that is gone (or an ecosystem
    that is deleted, archived or has login disabled) is 401, never 404; 404 is the platform user-not-
    found case only.

    Replaces GET /auth/me, GET /account/privacy (include privacy), GET /me/appearance (include
    appearance), GET /me/communication-settings (include communication_settings), GET /me/workspace-
    prefs (include workspace_prefs).

    Args:
        expand (list[str] | Unset):
        include (list[GetV1AccountIncludeItem] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1AccountResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        expand=expand,
        include=include,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    expand: list[str] | Unset = UNSET,
    include: list[GetV1AccountIncludeItem] | Unset = UNSET,
) -> GetV1AccountResponse200 | StripeError | None:
    """Current user

     A platform token answers the hub user (User). An end-customer token (client-auth) answers its
    customer record in the customer realm instead — the CustomerMe schema, linked from the 200
    response's `x-customer-realm`. For a customer token, a customer row that is gone (or an ecosystem
    that is deleted, archived or has login disabled) is 401, never 404; 404 is the platform user-not-
    found case only.

    Replaces GET /auth/me, GET /account/privacy (include privacy), GET /me/appearance (include
    appearance), GET /me/communication-settings (include communication_settings), GET /me/workspace-
    prefs (include workspace_prefs).

    Args:
        expand (list[str] | Unset):
        include (list[GetV1AccountIncludeItem] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1AccountResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            client=client,
            expand=expand,
            include=include,
        )
    ).parsed
