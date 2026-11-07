from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.integration_connection_data_page import IntegrationConnectionDataPage
from ...models.problem_details import ProblemDetails
from ...types import UNSET, Response, Unset


def _get_kwargs(
    connection_id: str,
    resource: str,
    *,
    cursor: str | Unset = UNSET,
    limit: str | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["cursor"] = cursor

    params["limit"] = limit

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/integrations/{connection_id}/data/{resource}".format(
            connection_id=quote(str(connection_id), safe=""),
            resource=quote(str(resource), safe=""),
        ),
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> IntegrationConnectionDataPage | ProblemDetails | None:
    if response.status_code == 200:
        response_200 = IntegrationConnectionDataPage.from_dict(response.json())

        return response_200

    if response.status_code == 400:
        response_400 = ProblemDetails.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = ProblemDetails.from_dict(response.json())

        return response_401

    if response.status_code == 404:
        response_404 = ProblemDetails.from_dict(response.json())

        return response_404

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[IntegrationConnectionDataPage | ProblemDetails]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    connection_id: str,
    resource: str,
    *,
    client: AuthenticatedClient,
    cursor: str | Unset = UNSET,
    limit: str | Unset = UNSET,
) -> Response[IntegrationConnectionDataPage | ProblemDetails]:
    """Read a connection's synced rows (Data tab)

     One page of live rows, ordered by `syncVersion`. Only the connection's own customer may read; any
    other caller, an end-user connection and a deleted connection all get the same 404. Unknown
    `resource` is 404; a bad `cursor` or `limit` is 400. `limit` defaults to 50 and is capped at 200.

    Args:
        connection_id (str):
        resource (str):
        cursor (str | Unset):
        limit (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[IntegrationConnectionDataPage | ProblemDetails]
    """

    kwargs = _get_kwargs(
        connection_id=connection_id,
        resource=resource,
        cursor=cursor,
        limit=limit,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    connection_id: str,
    resource: str,
    *,
    client: AuthenticatedClient,
    cursor: str | Unset = UNSET,
    limit: str | Unset = UNSET,
) -> IntegrationConnectionDataPage | ProblemDetails | None:
    """Read a connection's synced rows (Data tab)

     One page of live rows, ordered by `syncVersion`. Only the connection's own customer may read; any
    other caller, an end-user connection and a deleted connection all get the same 404. Unknown
    `resource` is 404; a bad `cursor` or `limit` is 400. `limit` defaults to 50 and is capped at 200.

    Args:
        connection_id (str):
        resource (str):
        cursor (str | Unset):
        limit (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        IntegrationConnectionDataPage | ProblemDetails
    """

    return sync_detailed(
        connection_id=connection_id,
        resource=resource,
        client=client,
        cursor=cursor,
        limit=limit,
    ).parsed


async def asyncio_detailed(
    connection_id: str,
    resource: str,
    *,
    client: AuthenticatedClient,
    cursor: str | Unset = UNSET,
    limit: str | Unset = UNSET,
) -> Response[IntegrationConnectionDataPage | ProblemDetails]:
    """Read a connection's synced rows (Data tab)

     One page of live rows, ordered by `syncVersion`. Only the connection's own customer may read; any
    other caller, an end-user connection and a deleted connection all get the same 404. Unknown
    `resource` is 404; a bad `cursor` or `limit` is 400. `limit` defaults to 50 and is capped at 200.

    Args:
        connection_id (str):
        resource (str):
        cursor (str | Unset):
        limit (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[IntegrationConnectionDataPage | ProblemDetails]
    """

    kwargs = _get_kwargs(
        connection_id=connection_id,
        resource=resource,
        cursor=cursor,
        limit=limit,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    connection_id: str,
    resource: str,
    *,
    client: AuthenticatedClient,
    cursor: str | Unset = UNSET,
    limit: str | Unset = UNSET,
) -> IntegrationConnectionDataPage | ProblemDetails | None:
    """Read a connection's synced rows (Data tab)

     One page of live rows, ordered by `syncVersion`. Only the connection's own customer may read; any
    other caller, an end-user connection and a deleted connection all get the same 404. Unknown
    `resource` is 404; a bad `cursor` or `limit` is 400. `limit` defaults to 50 and is capped at 200.

    Args:
        connection_id (str):
        resource (str):
        cursor (str | Unset):
        limit (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        IntegrationConnectionDataPage | ProblemDetails
    """

    return (
        await asyncio_detailed(
            connection_id=connection_id,
            resource=resource,
            client=client,
            cursor=cursor,
            limit=limit,
        )
    ).parsed
