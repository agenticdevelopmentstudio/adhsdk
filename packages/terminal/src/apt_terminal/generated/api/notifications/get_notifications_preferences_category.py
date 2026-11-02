from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.notification_preference import NotificationPreference
from ...types import Response


def _get_kwargs(
    category: str,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/notifications/preferences/{category}".format(
            category=quote(str(category), safe=""),
        ),
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | NotificationPreference | None:
    if response.status_code == 200:
        response_200 = NotificationPreference.from_dict(response.json())

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
) -> Response[Error | NotificationPreference]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    category: str,
    *,
    client: AuthenticatedClient,
) -> Response[Error | NotificationPreference]:
    """Get the caller's preference for one category (defaults if unset)

    Args:
        category (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | NotificationPreference]
    """

    kwargs = _get_kwargs(
        category=category,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    category: str,
    *,
    client: AuthenticatedClient,
) -> Error | NotificationPreference | None:
    """Get the caller's preference for one category (defaults if unset)

    Args:
        category (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | NotificationPreference
    """

    return sync_detailed(
        category=category,
        client=client,
    ).parsed


async def asyncio_detailed(
    category: str,
    *,
    client: AuthenticatedClient,
) -> Response[Error | NotificationPreference]:
    """Get the caller's preference for one category (defaults if unset)

    Args:
        category (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | NotificationPreference]
    """

    kwargs = _get_kwargs(
        category=category,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    category: str,
    *,
    client: AuthenticatedClient,
) -> Error | NotificationPreference | None:
    """Get the caller's preference for one category (defaults if unset)

    Args:
        category (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | NotificationPreference
    """

    return (
        await asyncio_detailed(
            category=category,
            client=client,
        )
    ).parsed
