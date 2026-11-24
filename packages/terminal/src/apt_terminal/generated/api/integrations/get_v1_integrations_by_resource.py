from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.get_v1_integrations_by_resource_response_200 import (
    GetV1IntegrationsByResourceResponse200,
)
from ...models.stripe_error import StripeError
from ...types import UNSET, Response, Unset


def _get_kwargs(
    resource: str,
    *,
    connection: str,
    cursor: str | Unset = UNSET,
    limit: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["connection"] = connection

    params["cursor"] = cursor

    params["limit"] = limit

    json_expand: list[str] | Unset = UNSET
    if not isinstance(expand, Unset):
        json_expand = expand

    params["expand[]"] = json_expand

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/v1/integrations/{resource}".format(
            resource=quote(str(resource), safe=""),
        ),
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> GetV1IntegrationsByResourceResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = GetV1IntegrationsByResourceResponse200.from_dict(response.json())

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
) -> Response[GetV1IntegrationsByResourceResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    resource: str,
    *,
    client: AuthenticatedClient,
    connection: str,
    cursor: str | Unset = UNSET,
    limit: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1IntegrationsByResourceResponse200 | StripeError]:
    """Read a connection's synced rows (Data tab)

     One page of live rows, ordered by `syncVersion`. Only the connection's own customer may read; any
    other caller, an end-user connection and a deleted connection all get the same 404. Unknown
    `resource` is 404; a bad `cursor` or `limit` is 400. `limit` defaults to 50 and is capped at 200.

    Replaces GET /integrations/{connectionId}/data/{resource}.

    Args:
        resource (str):
        connection (str):
        cursor (str | Unset):
        limit (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1IntegrationsByResourceResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        resource=resource,
        connection=connection,
        cursor=cursor,
        limit=limit,
        expand=expand,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    resource: str,
    *,
    client: AuthenticatedClient,
    connection: str,
    cursor: str | Unset = UNSET,
    limit: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> GetV1IntegrationsByResourceResponse200 | StripeError | None:
    """Read a connection's synced rows (Data tab)

     One page of live rows, ordered by `syncVersion`. Only the connection's own customer may read; any
    other caller, an end-user connection and a deleted connection all get the same 404. Unknown
    `resource` is 404; a bad `cursor` or `limit` is 400. `limit` defaults to 50 and is capped at 200.

    Replaces GET /integrations/{connectionId}/data/{resource}.

    Args:
        resource (str):
        connection (str):
        cursor (str | Unset):
        limit (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1IntegrationsByResourceResponse200 | StripeError
    """

    return sync_detailed(
        resource=resource,
        client=client,
        connection=connection,
        cursor=cursor,
        limit=limit,
        expand=expand,
    ).parsed


async def asyncio_detailed(
    resource: str,
    *,
    client: AuthenticatedClient,
    connection: str,
    cursor: str | Unset = UNSET,
    limit: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1IntegrationsByResourceResponse200 | StripeError]:
    """Read a connection's synced rows (Data tab)

     One page of live rows, ordered by `syncVersion`. Only the connection's own customer may read; any
    other caller, an end-user connection and a deleted connection all get the same 404. Unknown
    `resource` is 404; a bad `cursor` or `limit` is 400. `limit` defaults to 50 and is capped at 200.

    Replaces GET /integrations/{connectionId}/data/{resource}.

    Args:
        resource (str):
        connection (str):
        cursor (str | Unset):
        limit (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1IntegrationsByResourceResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        resource=resource,
        connection=connection,
        cursor=cursor,
        limit=limit,
        expand=expand,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    resource: str,
    *,
    client: AuthenticatedClient,
    connection: str,
    cursor: str | Unset = UNSET,
    limit: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> GetV1IntegrationsByResourceResponse200 | StripeError | None:
    """Read a connection's synced rows (Data tab)

     One page of live rows, ordered by `syncVersion`. Only the connection's own customer may read; any
    other caller, an end-user connection and a deleted connection all get the same 404. Unknown
    `resource` is 404; a bad `cursor` or `limit` is 400. `limit` defaults to 50 and is capped at 200.

    Replaces GET /integrations/{connectionId}/data/{resource}.

    Args:
        resource (str):
        connection (str):
        cursor (str | Unset):
        limit (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1IntegrationsByResourceResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            resource=resource,
            client=client,
            connection=connection,
            cursor=cursor,
            limit=limit,
            expand=expand,
        )
    ).parsed
