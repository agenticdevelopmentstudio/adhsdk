from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.appearance_settings import AppearanceSettings
from ...models.error import Error
from ...types import Response


def _get_kwargs() -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/me/appearance",
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> AppearanceSettings | Error | None:
    if response.status_code == 200:
        response_200 = AppearanceSettings.from_dict(response.json())

        return response_200

    if response.status_code == 401:
        response_401 = Error.from_dict(response.json())

        return response_401

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[AppearanceSettings | Error]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
) -> Response[AppearanceSettings | Error]:
    """The caller's appearance preferences (empty object when never saved)

     Every adh site reads this on sign-in so a user's colour mode and accessibility settings follow them
    across the family (the sites span many registrable domains, so a browser-local copy cannot). A
    signed-out visitor follows their OS setting instead.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[AppearanceSettings | Error]
    """

    kwargs = _get_kwargs()

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
) -> AppearanceSettings | Error | None:
    """The caller's appearance preferences (empty object when never saved)

     Every adh site reads this on sign-in so a user's colour mode and accessibility settings follow them
    across the family (the sites span many registrable domains, so a browser-local copy cannot). A
    signed-out visitor follows their OS setting instead.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        AppearanceSettings | Error
    """

    return sync_detailed(
        client=client,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
) -> Response[AppearanceSettings | Error]:
    """The caller's appearance preferences (empty object when never saved)

     Every adh site reads this on sign-in so a user's colour mode and accessibility settings follow them
    across the family (the sites span many registrable domains, so a browser-local copy cannot). A
    signed-out visitor follows their OS setting instead.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[AppearanceSettings | Error]
    """

    kwargs = _get_kwargs()

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
) -> AppearanceSettings | Error | None:
    """The caller's appearance preferences (empty object when never saved)

     Every adh site reads this on sign-in so a user's colour mode and accessibility settings follow them
    across the family (the sites span many registrable domains, so a browser-local copy cannot). A
    signed-out visitor follows their OS setting instead.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        AppearanceSettings | Error
    """

    return (
        await asyncio_detailed(
            client=client,
        )
    ).parsed
