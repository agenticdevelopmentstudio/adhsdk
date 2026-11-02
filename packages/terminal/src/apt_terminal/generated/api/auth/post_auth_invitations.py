from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.invitation import Invitation
from ...models.send_invites_body import SendInvitesBody
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    body: SendInvitesBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/auth/invitations",
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | list[Invitation] | None:
    if response.status_code == 201:
        response_201 = []
        _response_201 = response.json()
        for response_201_item_data in _response_201:
            response_201_item = Invitation.from_dict(response_201_item_data)

            response_201.append(response_201_item)

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

    if response.status_code == 500:
        response_500 = Error.from_dict(response.json())

        return response_500

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | list[Invitation]]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    body: SendInvitesBody | Unset = UNSET,
) -> Response[Error | list[Invitation]]:
    """Send invitations to pending users

     One invitation per person per requested channel that they have a destination for — so naming three
    people with both `email` and `sms` returns up to six rows. Every id is checked before anything is
    sent: one unknown id fails the whole call with 404.

    Args:
        body (SendInvitesBody | Unset): Names the people to invite and the channels to reach them
            on. At least one channel is required.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | list[Invitation]]
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
    body: SendInvitesBody | Unset = UNSET,
) -> Error | list[Invitation] | None:
    """Send invitations to pending users

     One invitation per person per requested channel that they have a destination for — so naming three
    people with both `email` and `sms` returns up to six rows. Every id is checked before anything is
    sent: one unknown id fails the whole call with 404.

    Args:
        body (SendInvitesBody | Unset): Names the people to invite and the channels to reach them
            on. At least one channel is required.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | list[Invitation]
    """

    return sync_detailed(
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    body: SendInvitesBody | Unset = UNSET,
) -> Response[Error | list[Invitation]]:
    """Send invitations to pending users

     One invitation per person per requested channel that they have a destination for — so naming three
    people with both `email` and `sms` returns up to six rows. Every id is checked before anything is
    sent: one unknown id fails the whole call with 404.

    Args:
        body (SendInvitesBody | Unset): Names the people to invite and the channels to reach them
            on. At least one channel is required.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | list[Invitation]]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    body: SendInvitesBody | Unset = UNSET,
) -> Error | list[Invitation] | None:
    """Send invitations to pending users

     One invitation per person per requested channel that they have a destination for — so naming three
    people with both `email` and `sms` returns up to six rows. Every id is checked before anything is
    sent: one unknown id fails the whole call with 404.

    Args:
        body (SendInvitesBody | Unset): Names the people to invite and the channels to reach them
            on. At least one channel is required.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | list[Invitation]
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
        )
    ).parsed
