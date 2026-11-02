from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.messaging_log_page import MessagingLogPage
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
    channel: str | Unset = UNSET,
    status: str | Unset = UNSET,
    user_id: str | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["page"] = page

    params["pageSize"] = page_size

    params["channel"] = channel

    params["status"] = status

    params["userId"] = user_id

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/messaging/log",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | MessagingLogPage | None:
    if response.status_code == 200:
        response_200 = MessagingLogPage.from_dict(response.json())

        return response_200

    if response.status_code == 401:
        response_401 = Error.from_dict(response.json())

        return response_401

    if response.status_code == 403:
        response_403 = Error.from_dict(response.json())

        return response_403

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | MessagingLogPage]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
    channel: str | Unset = UNSET,
    status: str | Unset = UNSET,
    user_id: str | Unset = UNSET,
) -> Response[Error | MessagingLogPage]:
    """List the message log (admin), newest first, with optional filters

    Args:
        page (str | Unset):
        page_size (str | Unset):
        channel (str | Unset):
        status (str | Unset):
        user_id (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | MessagingLogPage]
    """

    kwargs = _get_kwargs(
        page=page,
        page_size=page_size,
        channel=channel,
        status=status,
        user_id=user_id,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
    channel: str | Unset = UNSET,
    status: str | Unset = UNSET,
    user_id: str | Unset = UNSET,
) -> Error | MessagingLogPage | None:
    """List the message log (admin), newest first, with optional filters

    Args:
        page (str | Unset):
        page_size (str | Unset):
        channel (str | Unset):
        status (str | Unset):
        user_id (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | MessagingLogPage
    """

    return sync_detailed(
        client=client,
        page=page,
        page_size=page_size,
        channel=channel,
        status=status,
        user_id=user_id,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
    channel: str | Unset = UNSET,
    status: str | Unset = UNSET,
    user_id: str | Unset = UNSET,
) -> Response[Error | MessagingLogPage]:
    """List the message log (admin), newest first, with optional filters

    Args:
        page (str | Unset):
        page_size (str | Unset):
        channel (str | Unset):
        status (str | Unset):
        user_id (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | MessagingLogPage]
    """

    kwargs = _get_kwargs(
        page=page,
        page_size=page_size,
        channel=channel,
        status=status,
        user_id=user_id,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
    channel: str | Unset = UNSET,
    status: str | Unset = UNSET,
    user_id: str | Unset = UNSET,
) -> Error | MessagingLogPage | None:
    """List the message log (admin), newest first, with optional filters

    Args:
        page (str | Unset):
        page_size (str | Unset):
        channel (str | Unset):
        status (str | Unset):
        user_id (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | MessagingLogPage
    """

    return (
        await asyncio_detailed(
            client=client,
            page=page,
            page_size=page_size,
            channel=channel,
            status=status,
            user_id=user_id,
        )
    ).parsed
