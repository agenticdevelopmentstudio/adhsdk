from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.chat_create_request import ChatCreateRequest
from ...models.chat_create_result import ChatCreateResult
from ...models.error import Error
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    body: ChatCreateRequest | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/chat/chats",
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> ChatCreateResult | Error | None:
    if response.status_code == 201:
        response_201 = ChatCreateResult.from_dict(response.json())

        return response_201

    if response.status_code == 400:
        response_400 = Error.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = Error.from_dict(response.json())

        return response_401

    if response.status_code == 403:
        response_403 = Error.from_dict(response.json())

        return response_403

    if response.status_code == 404:
        response_404 = Error.from_dict(response.json())

        return response_404

    if response.status_code == 409:
        response_409 = Error.from_dict(response.json())

        return response_409

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[ChatCreateResult | Error]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    body: ChatCreateRequest | Unset = UNSET,
) -> Response[ChatCreateResult | Error]:
    """Create a chat from a definition

     Seats the caller as owner, the definition's own personas, and the named users and personas. A
    definition persona that has since been deleted is skipped rather than refused — its id comes back in
    `skippedPersonaIds`. Refused: the `direct` definition (400 — use `/chat/dms`), an unknown or deleted
    definition, an unknown user, or an added persona the caller cannot use (404), an archived definition
    (409), a user blocked either way with the caller or another invited user (403), a `name` on a
    definition that is not user-configurable (403), more participants than the definition allows (400).

    Args:
        body (ChatCreateRequest | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[ChatCreateResult | Error]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    body: ChatCreateRequest | Unset = UNSET,
) -> ChatCreateResult | Error | None:
    """Create a chat from a definition

     Seats the caller as owner, the definition's own personas, and the named users and personas. A
    definition persona that has since been deleted is skipped rather than refused — its id comes back in
    `skippedPersonaIds`. Refused: the `direct` definition (400 — use `/chat/dms`), an unknown or deleted
    definition, an unknown user, or an added persona the caller cannot use (404), an archived definition
    (409), a user blocked either way with the caller or another invited user (403), a `name` on a
    definition that is not user-configurable (403), more participants than the definition allows (400).

    Args:
        body (ChatCreateRequest | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        ChatCreateResult | Error
    """

    return sync_detailed(
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    body: ChatCreateRequest | Unset = UNSET,
) -> Response[ChatCreateResult | Error]:
    """Create a chat from a definition

     Seats the caller as owner, the definition's own personas, and the named users and personas. A
    definition persona that has since been deleted is skipped rather than refused — its id comes back in
    `skippedPersonaIds`. Refused: the `direct` definition (400 — use `/chat/dms`), an unknown or deleted
    definition, an unknown user, or an added persona the caller cannot use (404), an archived definition
    (409), a user blocked either way with the caller or another invited user (403), a `name` on a
    definition that is not user-configurable (403), more participants than the definition allows (400).

    Args:
        body (ChatCreateRequest | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[ChatCreateResult | Error]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    body: ChatCreateRequest | Unset = UNSET,
) -> ChatCreateResult | Error | None:
    """Create a chat from a definition

     Seats the caller as owner, the definition's own personas, and the named users and personas. A
    definition persona that has since been deleted is skipped rather than refused — its id comes back in
    `skippedPersonaIds`. Refused: the `direct` definition (400 — use `/chat/dms`), an unknown or deleted
    definition, an unknown user, or an added persona the caller cannot use (404), an archived definition
    (409), a user blocked either way with the caller or another invited user (403), a `name` on a
    definition that is not user-configurable (403), more participants than the definition allows (400).

    Args:
        body (ChatCreateRequest | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        ChatCreateResult | Error
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
        )
    ).parsed
