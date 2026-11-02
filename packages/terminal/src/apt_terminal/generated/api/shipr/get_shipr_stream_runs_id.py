from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...types import UNSET, Response, Unset


def _get_kwargs(
    id: str,
    *,
    after: str | Unset = UNSET,
    access_token: str | Unset = UNSET,
    repo: str | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["after"] = after

    params["access_token"] = access_token

    params["repo"] = repo

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/shipr/stream/runs/{id}".format(
            id=quote(str(id), safe=""),
        ),
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | str | None:
    if response.status_code == 200:
        response_200 = response.text
        return response_200

    if response.status_code == 401:
        response_401 = Error.from_dict(response.json())

        return response_401

    if response.status_code == 403:
        response_403 = Error.from_dict(response.json())

        return response_403

    if response.status_code == 404:
        response_404 = Error.from_dict(response.json())

        return response_404

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | str]:
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
    access_token: str | Unset = UNSET,
    repo: str | Unset = UNSET,
) -> Response[Error | str]:
    """A run’s log as server-sent events

     Events: `line` (one log line, `id:` is its seq), `state` (the run changed state), `end` (settled —
    the stream closes). Resume with `Last-Event-ID` or `?after=<seq>`. Because EventSource cannot set
    headers, the bearer token may be passed as `?access_token=`.

    Args:
        id (str):
        after (str | Unset):
        access_token (str | Unset):
        repo (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | str]
    """

    kwargs = _get_kwargs(
        id=id,
        after=after,
        access_token=access_token,
        repo=repo,
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
    access_token: str | Unset = UNSET,
    repo: str | Unset = UNSET,
) -> Error | str | None:
    """A run’s log as server-sent events

     Events: `line` (one log line, `id:` is its seq), `state` (the run changed state), `end` (settled —
    the stream closes). Resume with `Last-Event-ID` or `?after=<seq>`. Because EventSource cannot set
    headers, the bearer token may be passed as `?access_token=`.

    Args:
        id (str):
        after (str | Unset):
        access_token (str | Unset):
        repo (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | str
    """

    return sync_detailed(
        id=id,
        client=client,
        after=after,
        access_token=access_token,
        repo=repo,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
    after: str | Unset = UNSET,
    access_token: str | Unset = UNSET,
    repo: str | Unset = UNSET,
) -> Response[Error | str]:
    """A run’s log as server-sent events

     Events: `line` (one log line, `id:` is its seq), `state` (the run changed state), `end` (settled —
    the stream closes). Resume with `Last-Event-ID` or `?after=<seq>`. Because EventSource cannot set
    headers, the bearer token may be passed as `?access_token=`.

    Args:
        id (str):
        after (str | Unset):
        access_token (str | Unset):
        repo (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | str]
    """

    kwargs = _get_kwargs(
        id=id,
        after=after,
        access_token=access_token,
        repo=repo,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    *,
    client: AuthenticatedClient,
    after: str | Unset = UNSET,
    access_token: str | Unset = UNSET,
    repo: str | Unset = UNSET,
) -> Error | str | None:
    """A run’s log as server-sent events

     Events: `line` (one log line, `id:` is its seq), `state` (the run changed state), `end` (settled —
    the stream closes). Resume with `Last-Event-ID` or `?after=<seq>`. Because EventSource cannot set
    headers, the bearer token may be passed as `?access_token=`.

    Args:
        id (str):
        after (str | Unset):
        access_token (str | Unset):
        repo (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | str
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            after=after,
            access_token=access_token,
            repo=repo,
        )
    ).parsed
