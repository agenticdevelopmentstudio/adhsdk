from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.get_v1_integrations_connections_owner import GetV1IntegrationsConnectionsOwner
from ...models.get_v1_integrations_connections_response_200 import (
    GetV1IntegrationsConnectionsResponse200,
)
from ...models.stripe_error import StripeError
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    owner: GetV1IntegrationsConnectionsOwner | Unset = UNSET,
    ecosystem_id: str,
    limit: int | Unset = 10,
    starting_after: str | Unset = UNSET,
    ending_before: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    json_owner: str | Unset = UNSET
    if not isinstance(owner, Unset):
        json_owner = owner.value

    params["owner"] = json_owner

    params["ecosystem_id"] = ecosystem_id

    params["limit"] = limit

    params["starting_after"] = starting_after

    params["ending_before"] = ending_before

    json_expand: list[str] | Unset = UNSET
    if not isinstance(expand, Unset):
        json_expand = expand

    params["expand[]"] = json_expand

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/v1/integrations/connections",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> GetV1IntegrationsConnectionsResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = GetV1IntegrationsConnectionsResponse200.from_dict(response.json())

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

    if response.status_code == 404:
        response_404 = StripeError.from_dict(response.json())

        return response_404

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[GetV1IntegrationsConnectionsResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    owner: GetV1IntegrationsConnectionsOwner | Unset = UNSET,
    ecosystem_id: str,
    limit: int | Unset = 10,
    starting_after: str | Unset = UNSET,
    ending_before: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1IntegrationsConnectionsResponse200 | StripeError]:
    """List a target ecosystem's connections (secrets redacted)

     Returns every integration connection OWNED by the target ecosystem `ecosystemId` (the caller must
    manage it). Secret columns are never included. 400 when `ecosystemId` is omitted; 404/403 when the
    ecosystem is unknown / not the caller's.

    Replaces GET /integrations, GET /integrations/me/connections, GET /integrations/end-user-
    connections.

    Args:
        owner (GetV1IntegrationsConnectionsOwner | Unset):
        ecosystem_id (str):
        limit (int | Unset):  Default: 10.
        starting_after (str | Unset):
        ending_before (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1IntegrationsConnectionsResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        owner=owner,
        ecosystem_id=ecosystem_id,
        limit=limit,
        starting_after=starting_after,
        ending_before=ending_before,
        expand=expand,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    owner: GetV1IntegrationsConnectionsOwner | Unset = UNSET,
    ecosystem_id: str,
    limit: int | Unset = 10,
    starting_after: str | Unset = UNSET,
    ending_before: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> GetV1IntegrationsConnectionsResponse200 | StripeError | None:
    """List a target ecosystem's connections (secrets redacted)

     Returns every integration connection OWNED by the target ecosystem `ecosystemId` (the caller must
    manage it). Secret columns are never included. 400 when `ecosystemId` is omitted; 404/403 when the
    ecosystem is unknown / not the caller's.

    Replaces GET /integrations, GET /integrations/me/connections, GET /integrations/end-user-
    connections.

    Args:
        owner (GetV1IntegrationsConnectionsOwner | Unset):
        ecosystem_id (str):
        limit (int | Unset):  Default: 10.
        starting_after (str | Unset):
        ending_before (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1IntegrationsConnectionsResponse200 | StripeError
    """

    return sync_detailed(
        client=client,
        owner=owner,
        ecosystem_id=ecosystem_id,
        limit=limit,
        starting_after=starting_after,
        ending_before=ending_before,
        expand=expand,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    owner: GetV1IntegrationsConnectionsOwner | Unset = UNSET,
    ecosystem_id: str,
    limit: int | Unset = 10,
    starting_after: str | Unset = UNSET,
    ending_before: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1IntegrationsConnectionsResponse200 | StripeError]:
    """List a target ecosystem's connections (secrets redacted)

     Returns every integration connection OWNED by the target ecosystem `ecosystemId` (the caller must
    manage it). Secret columns are never included. 400 when `ecosystemId` is omitted; 404/403 when the
    ecosystem is unknown / not the caller's.

    Replaces GET /integrations, GET /integrations/me/connections, GET /integrations/end-user-
    connections.

    Args:
        owner (GetV1IntegrationsConnectionsOwner | Unset):
        ecosystem_id (str):
        limit (int | Unset):  Default: 10.
        starting_after (str | Unset):
        ending_before (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1IntegrationsConnectionsResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        owner=owner,
        ecosystem_id=ecosystem_id,
        limit=limit,
        starting_after=starting_after,
        ending_before=ending_before,
        expand=expand,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    owner: GetV1IntegrationsConnectionsOwner | Unset = UNSET,
    ecosystem_id: str,
    limit: int | Unset = 10,
    starting_after: str | Unset = UNSET,
    ending_before: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> GetV1IntegrationsConnectionsResponse200 | StripeError | None:
    """List a target ecosystem's connections (secrets redacted)

     Returns every integration connection OWNED by the target ecosystem `ecosystemId` (the caller must
    manage it). Secret columns are never included. 400 when `ecosystemId` is omitted; 404/403 when the
    ecosystem is unknown / not the caller's.

    Replaces GET /integrations, GET /integrations/me/connections, GET /integrations/end-user-
    connections.

    Args:
        owner (GetV1IntegrationsConnectionsOwner | Unset):
        ecosystem_id (str):
        limit (int | Unset):  Default: 10.
        starting_after (str | Unset):
        ending_before (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1IntegrationsConnectionsResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            client=client,
            owner=owner,
            ecosystem_id=ecosystem_id,
            limit=limit,
            starting_after=starting_after,
            ending_before=ending_before,
            expand=expand,
        )
    ).parsed
