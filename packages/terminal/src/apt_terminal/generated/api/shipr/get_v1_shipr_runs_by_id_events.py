from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.get_v1_shipr_runs_by_id_events_response_200 import (
    GetV1ShiprRunsByIdEventsResponse200,
)
from ...models.stripe_error import StripeError
from ...types import UNSET, Response, Unset


def _get_kwargs(
    id: str,
    *,
    after: str | Unset = UNSET,
    limit: str | Unset = UNSET,
    repo: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["after"] = after

    params["limit"] = limit

    params["repo"] = repo

    json_expand: list[str] | Unset = UNSET
    if not isinstance(expand, Unset):
        json_expand = expand

    params["expand[]"] = json_expand

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/v1/shipr/runs/{id}/events".format(
            id=quote(str(id), safe=""),
        ),
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> GetV1ShiprRunsByIdEventsResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = GetV1ShiprRunsByIdEventsResponse200.from_dict(response.json())

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
) -> Response[GetV1ShiprRunsByIdEventsResponse200 | StripeError]:
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
    after: str | Unset = UNSET,
    limit: str | Unset = UNSET,
    repo: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1ShiprRunsByIdEventsResponse200 | StripeError]:
    """A page of the run’s log

     The same `seq` cursor the stream uses, so a client can start here and switch to the stream — or poll
    this where EventSource is unavailable — with one notion of position.

    Replaces GET /shipr/runs/{id}/events.

    Args:
        id (str):
        after (str | Unset):
        limit (str | Unset):
        repo (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1ShiprRunsByIdEventsResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
        after=after,
        limit=limit,
        repo=repo,
        expand=expand,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    *,
    client: AuthenticatedClient,
    after: str | Unset = UNSET,
    limit: str | Unset = UNSET,
    repo: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> GetV1ShiprRunsByIdEventsResponse200 | StripeError | None:
    """A page of the run’s log

     The same `seq` cursor the stream uses, so a client can start here and switch to the stream — or poll
    this where EventSource is unavailable — with one notion of position.

    Replaces GET /shipr/runs/{id}/events.

    Args:
        id (str):
        after (str | Unset):
        limit (str | Unset):
        repo (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1ShiprRunsByIdEventsResponse200 | StripeError
    """

    return sync_detailed(
        id=id,
        client=client,
        after=after,
        limit=limit,
        repo=repo,
        expand=expand,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
    after: str | Unset = UNSET,
    limit: str | Unset = UNSET,
    repo: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1ShiprRunsByIdEventsResponse200 | StripeError]:
    """A page of the run’s log

     The same `seq` cursor the stream uses, so a client can start here and switch to the stream — or poll
    this where EventSource is unavailable — with one notion of position.

    Replaces GET /shipr/runs/{id}/events.

    Args:
        id (str):
        after (str | Unset):
        limit (str | Unset):
        repo (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1ShiprRunsByIdEventsResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
        after=after,
        limit=limit,
        repo=repo,
        expand=expand,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    *,
    client: AuthenticatedClient,
    after: str | Unset = UNSET,
    limit: str | Unset = UNSET,
    repo: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> GetV1ShiprRunsByIdEventsResponse200 | StripeError | None:
    """A page of the run’s log

     The same `seq` cursor the stream uses, so a client can start here and switch to the stream — or poll
    this where EventSource is unavailable — with one notion of position.

    Replaces GET /shipr/runs/{id}/events.

    Args:
        id (str):
        after (str | Unset):
        limit (str | Unset):
        repo (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1ShiprRunsByIdEventsResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            after=after,
            limit=limit,
            repo=repo,
            expand=expand,
        )
    ).parsed
