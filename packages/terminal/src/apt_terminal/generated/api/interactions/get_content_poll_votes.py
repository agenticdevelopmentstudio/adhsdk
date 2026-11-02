from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.poll_tally import PollTally
from ...types import UNSET, Response


def _get_kwargs(
    *,
    poll_id: str,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["pollId"] = poll_id

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/content/poll-votes",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | PollTally | None:
    if response.status_code == 200:
        response_200 = PollTally.from_dict(response.json())

        return response_200

    if response.status_code == 400:
        response_400 = Error.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = Error.from_dict(response.json())

        return response_401

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | PollTally]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    poll_id: str,
) -> Response[Error | PollTally]:
    """Tally a poll — per-option counts + the caller’s chosen options

    Args:
        poll_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PollTally]
    """

    kwargs = _get_kwargs(
        poll_id=poll_id,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    poll_id: str,
) -> Error | PollTally | None:
    """Tally a poll — per-option counts + the caller’s chosen options

    Args:
        poll_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PollTally
    """

    return sync_detailed(
        client=client,
        poll_id=poll_id,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    poll_id: str,
) -> Response[Error | PollTally]:
    """Tally a poll — per-option counts + the caller’s chosen options

    Args:
        poll_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PollTally]
    """

    kwargs = _get_kwargs(
        poll_id=poll_id,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    poll_id: str,
) -> Error | PollTally | None:
    """Tally a poll — per-option counts + the caller’s chosen options

    Args:
        poll_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PollTally
    """

    return (
        await asyncio_detailed(
            client=client,
            poll_id=poll_id,
        )
    ).parsed
