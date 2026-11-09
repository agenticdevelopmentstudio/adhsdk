from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.chat_participants_add_request import ChatParticipantsAddRequest
from ...models.post_v1_chats_by_id_participants_response_200 import (
    PostV1ChatsByIdParticipantsResponse200,
)
from ...models.stripe_error import StripeError
from ...types import Response


def _get_kwargs(
    id: str,
    *,
    body: ChatParticipantsAddRequest,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/chats/{id}/participants".format(
            id=quote(str(id), safe=""),
        ),
    }

    _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostV1ChatsByIdParticipantsResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = PostV1ChatsByIdParticipantsResponse200.from_dict(response.json())

        return response_200

    if response.status_code == 400:
        response_400 = StripeError.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = StripeError.from_dict(response.json())

        return response_401

    if response.status_code == 403:
        response_403 = StripeError.from_dict(response.json())

        return response_403

    if response.status_code == 404:
        response_404 = StripeError.from_dict(response.json())

        return response_404

    if response.status_code == 409:
        response_409 = StripeError.from_dict(response.json())

        return response_409

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[PostV1ChatsByIdParticipantsResponse200 | StripeError]:
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
    body: ChatParticipantsAddRequest,
) -> Response[PostV1ChatsByIdParticipantsResponse200 | StripeError]:
    """Invite users and personas into a chat

     Governed by the definition's `allowInvites`, `invitePolicy` and `allowAddedPersonas` (403), and its
    participant ceiling (409). Someone already seated is not added twice. A user blocked either way with
    anyone already in the chat, or with another invitee, is refused (403); an added persona the caller
    cannot use is 404. A definition persona that was deleted is skipped — its id comes back in
    `skippedPersonaIds`, as at create. Published as `participants_changed`, and `chats_changed` to each
    added user.

    Replaces POST /chat/chats/{id}/participants.

    Args:
        id (str):
        body (ChatParticipantsAddRequest):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1ChatsByIdParticipantsResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    *,
    client: AuthenticatedClient,
    body: ChatParticipantsAddRequest,
) -> PostV1ChatsByIdParticipantsResponse200 | StripeError | None:
    """Invite users and personas into a chat

     Governed by the definition's `allowInvites`, `invitePolicy` and `allowAddedPersonas` (403), and its
    participant ceiling (409). Someone already seated is not added twice. A user blocked either way with
    anyone already in the chat, or with another invitee, is refused (403); an added persona the caller
    cannot use is 404. A definition persona that was deleted is skipped — its id comes back in
    `skippedPersonaIds`, as at create. Published as `participants_changed`, and `chats_changed` to each
    added user.

    Replaces POST /chat/chats/{id}/participants.

    Args:
        id (str):
        body (ChatParticipantsAddRequest):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1ChatsByIdParticipantsResponse200 | StripeError
    """

    return sync_detailed(
        id=id,
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
    body: ChatParticipantsAddRequest,
) -> Response[PostV1ChatsByIdParticipantsResponse200 | StripeError]:
    """Invite users and personas into a chat

     Governed by the definition's `allowInvites`, `invitePolicy` and `allowAddedPersonas` (403), and its
    participant ceiling (409). Someone already seated is not added twice. A user blocked either way with
    anyone already in the chat, or with another invitee, is refused (403); an added persona the caller
    cannot use is 404. A definition persona that was deleted is skipped — its id comes back in
    `skippedPersonaIds`, as at create. Published as `participants_changed`, and `chats_changed` to each
    added user.

    Replaces POST /chat/chats/{id}/participants.

    Args:
        id (str):
        body (ChatParticipantsAddRequest):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1ChatsByIdParticipantsResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    *,
    client: AuthenticatedClient,
    body: ChatParticipantsAddRequest,
) -> PostV1ChatsByIdParticipantsResponse200 | StripeError | None:
    """Invite users and personas into a chat

     Governed by the definition's `allowInvites`, `invitePolicy` and `allowAddedPersonas` (403), and its
    participant ceiling (409). Someone already seated is not added twice. A user blocked either way with
    anyone already in the chat, or with another invitee, is refused (403); an added persona the caller
    cannot use is 404. A definition persona that was deleted is skipped — its id comes back in
    `skippedPersonaIds`, as at create. Published as `participants_changed`, and `chats_changed` to each
    added user.

    Replaces POST /chat/chats/{id}/participants.

    Args:
        id (str):
        body (ChatParticipantsAddRequest):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1ChatsByIdParticipantsResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            body=body,
        )
    ).parsed
