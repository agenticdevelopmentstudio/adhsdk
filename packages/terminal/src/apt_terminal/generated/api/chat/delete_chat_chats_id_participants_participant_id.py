from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.chat_participant_remove_result import ChatParticipantRemoveResult
from ...models.error import Error
from ...types import Response


def _get_kwargs(
    id: str,
    participant_id: str,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "delete",
        "url": "/chat/chats/{id}/participants/{participant_id}".format(
            id=quote(str(id), safe=""),
            participant_id=quote(str(participant_id), safe=""),
        ),
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> ChatParticipantRemoveResult | Error | None:
    if response.status_code == 200:
        response_200 = ChatParticipantRemoveResult.from_dict(response.json())

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
) -> Response[ChatParticipantRemoveResult | Error]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    id: str,
    participant_id: str,
    *,
    client: AuthenticatedClient,
) -> Response[ChatParticipantRemoveResult | Error]:
    """Remove a participant from a chat, or leave it

     Removing yourself is leaving; removing someone else is governed by the chat’s rules (403). When the
    owner leaves, the longest-standing user becomes owner (`newOwner`). A DM cannot be left (403).
    Published as `participants_changed`, and `chats_changed` to a removed user.

    Args:
        id (str):
        participant_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[ChatParticipantRemoveResult | Error]
    """

    kwargs = _get_kwargs(
        id=id,
        participant_id=participant_id,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    participant_id: str,
    *,
    client: AuthenticatedClient,
) -> ChatParticipantRemoveResult | Error | None:
    """Remove a participant from a chat, or leave it

     Removing yourself is leaving; removing someone else is governed by the chat’s rules (403). When the
    owner leaves, the longest-standing user becomes owner (`newOwner`). A DM cannot be left (403).
    Published as `participants_changed`, and `chats_changed` to a removed user.

    Args:
        id (str):
        participant_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        ChatParticipantRemoveResult | Error
    """

    return sync_detailed(
        id=id,
        participant_id=participant_id,
        client=client,
    ).parsed


async def asyncio_detailed(
    id: str,
    participant_id: str,
    *,
    client: AuthenticatedClient,
) -> Response[ChatParticipantRemoveResult | Error]:
    """Remove a participant from a chat, or leave it

     Removing yourself is leaving; removing someone else is governed by the chat’s rules (403). When the
    owner leaves, the longest-standing user becomes owner (`newOwner`). A DM cannot be left (403).
    Published as `participants_changed`, and `chats_changed` to a removed user.

    Args:
        id (str):
        participant_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[ChatParticipantRemoveResult | Error]
    """

    kwargs = _get_kwargs(
        id=id,
        participant_id=participant_id,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    participant_id: str,
    *,
    client: AuthenticatedClient,
) -> ChatParticipantRemoveResult | Error | None:
    """Remove a participant from a chat, or leave it

     Removing yourself is leaving; removing someone else is governed by the chat’s rules (403). When the
    owner leaves, the longest-standing user becomes owner (`newOwner`). A DM cannot be left (403).
    Published as `participants_changed`, and `chats_changed` to a removed user.

    Args:
        id (str):
        participant_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        ChatParticipantRemoveResult | Error
    """

    return (
        await asyncio_detailed(
            id=id,
            participant_id=participant_id,
            client=client,
        )
    ).parsed
