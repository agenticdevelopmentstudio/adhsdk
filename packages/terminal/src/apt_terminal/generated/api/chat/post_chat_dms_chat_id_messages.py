from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.dm_message import DmMessage
from ...models.dm_send_message import DmSendMessage
from ...models.error import Error
from ...types import UNSET, Response, Unset


def _get_kwargs(
    chat_id: str,
    *,
    body: DmSendMessage | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/chat/dms/{chat_id}/messages".format(
            chat_id=quote(str(chat_id), safe=""),
        ),
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> DmMessage | Error | None:
    if response.status_code == 200:
        response_200 = DmMessage.from_dict(response.json())

        return response_200

    if response.status_code == 201:
        response_201 = DmMessage.from_dict(response.json())

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

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[DmMessage | Error]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    chat_id: str,
    *,
    client: AuthenticatedClient,
    body: DmSendMessage | Unset = UNSET,
) -> Response[DmMessage | Error]:
    """Send a DM

     Send a message into a DM chat. Supplying `clientMessageId` makes the send idempotent: a replay
    returns 200 with the already-stored message instead of 201.

    Args:
        chat_id (str):
        body (DmSendMessage | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[DmMessage | Error]
    """

    kwargs = _get_kwargs(
        chat_id=chat_id,
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    chat_id: str,
    *,
    client: AuthenticatedClient,
    body: DmSendMessage | Unset = UNSET,
) -> DmMessage | Error | None:
    """Send a DM

     Send a message into a DM chat. Supplying `clientMessageId` makes the send idempotent: a replay
    returns 200 with the already-stored message instead of 201.

    Args:
        chat_id (str):
        body (DmSendMessage | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        DmMessage | Error
    """

    return sync_detailed(
        chat_id=chat_id,
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    chat_id: str,
    *,
    client: AuthenticatedClient,
    body: DmSendMessage | Unset = UNSET,
) -> Response[DmMessage | Error]:
    """Send a DM

     Send a message into a DM chat. Supplying `clientMessageId` makes the send idempotent: a replay
    returns 200 with the already-stored message instead of 201.

    Args:
        chat_id (str):
        body (DmSendMessage | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[DmMessage | Error]
    """

    kwargs = _get_kwargs(
        chat_id=chat_id,
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    chat_id: str,
    *,
    client: AuthenticatedClient,
    body: DmSendMessage | Unset = UNSET,
) -> DmMessage | Error | None:
    """Send a DM

     Send a message into a DM chat. Supplying `clientMessageId` makes the send idempotent: a replay
    returns 200 with the already-stored message instead of 201.

    Args:
        chat_id (str):
        body (DmSendMessage | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        DmMessage | Error
    """

    return (
        await asyncio_detailed(
            chat_id=chat_id,
            client=client,
            body=body,
        )
    ).parsed
