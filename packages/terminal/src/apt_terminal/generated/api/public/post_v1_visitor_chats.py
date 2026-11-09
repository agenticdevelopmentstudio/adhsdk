from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.post_v1_visitor_chats_response_201 import PostV1VisitorChatsResponse201
from ...models.stripe_error import StripeError
from ...models.visitor_conversation_create import VisitorConversationCreate
from ...types import Response


def _get_kwargs(
    *,
    body: VisitorConversationCreate,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/visitor_chats",
    }

    _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostV1VisitorChatsResponse201 | StripeError | None:
    if response.status_code == 201:
        response_201 = PostV1VisitorChatsResponse201.from_dict(response.json())

        return response_201

    if response.status_code == 400:
        response_400 = StripeError.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = StripeError.from_dict(response.json())

        return response_401

    if response.status_code == 402:
        response_402 = StripeError.from_dict(response.json())

        return response_402

    if response.status_code == 403:
        response_403 = StripeError.from_dict(response.json())

        return response_403

    if response.status_code == 429:
        response_429 = StripeError.from_dict(response.json())

        return response_429

    if response.status_code == 503:
        response_503 = StripeError.from_dict(response.json())

        return response_503

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[PostV1VisitorChatsResponse201 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    body: VisitorConversationCreate,
) -> Response[PostV1VisitorChatsResponse201 | StripeError]:
    """Start a visitor conversation

     Requires a visitor token (`tmp_…`) in the Authorization header — any other kind of token is a 403.
    The persona is taken from the token. Conversations expire on their own after a fixed window.

    Replaces POST /public/visitor-chat/conversations.

    Args:
        body (VisitorConversationCreate):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1VisitorChatsResponse201 | StripeError]
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
    body: VisitorConversationCreate,
) -> PostV1VisitorChatsResponse201 | StripeError | None:
    """Start a visitor conversation

     Requires a visitor token (`tmp_…`) in the Authorization header — any other kind of token is a 403.
    The persona is taken from the token. Conversations expire on their own after a fixed window.

    Replaces POST /public/visitor-chat/conversations.

    Args:
        body (VisitorConversationCreate):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1VisitorChatsResponse201 | StripeError
    """

    return sync_detailed(
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    body: VisitorConversationCreate,
) -> Response[PostV1VisitorChatsResponse201 | StripeError]:
    """Start a visitor conversation

     Requires a visitor token (`tmp_…`) in the Authorization header — any other kind of token is a 403.
    The persona is taken from the token. Conversations expire on their own after a fixed window.

    Replaces POST /public/visitor-chat/conversations.

    Args:
        body (VisitorConversationCreate):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1VisitorChatsResponse201 | StripeError]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    body: VisitorConversationCreate,
) -> PostV1VisitorChatsResponse201 | StripeError | None:
    """Start a visitor conversation

     Requires a visitor token (`tmp_…`) in the Authorization header — any other kind of token is a 403.
    The persona is taken from the token. Conversations expire on their own after a fixed window.

    Replaces POST /public/visitor-chat/conversations.

    Args:
        body (VisitorConversationCreate):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1VisitorChatsResponse201 | StripeError
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
        )
    ).parsed
