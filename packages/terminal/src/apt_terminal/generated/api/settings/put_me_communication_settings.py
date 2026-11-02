from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.communication_settings import CommunicationSettings
from ...models.error import Error
from ...models.put_me_communication_settings_body import PutMeCommunicationSettingsBody
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    body: PutMeCommunicationSettingsBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "put",
        "url": "/me/communication-settings",
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> CommunicationSettings | Error | None:
    if response.status_code == 200:
        response_200 = CommunicationSettings.from_dict(response.json())

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
) -> Response[CommunicationSettings | Error]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    body: PutMeCommunicationSettingsBody | Unset = UNSET,
) -> Response[CommunicationSettings | Error]:
    """Replace the caller's communication/presence dial (upsert; full representation)

     Masks must combine only the known AUDIENCE bits (PUBLIC=1, HUB=2, TEAM=4, ORG=8, FRIEND=32); 0 means
    nobody. Blocks always override the dial, and appear_offline hides presence from everyone.

    Args:
        body (PutMeCommunicationSettingsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[CommunicationSettings | Error]
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
    body: PutMeCommunicationSettingsBody | Unset = UNSET,
) -> CommunicationSettings | Error | None:
    """Replace the caller's communication/presence dial (upsert; full representation)

     Masks must combine only the known AUDIENCE bits (PUBLIC=1, HUB=2, TEAM=4, ORG=8, FRIEND=32); 0 means
    nobody. Blocks always override the dial, and appear_offline hides presence from everyone.

    Args:
        body (PutMeCommunicationSettingsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        CommunicationSettings | Error
    """

    return sync_detailed(
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    body: PutMeCommunicationSettingsBody | Unset = UNSET,
) -> Response[CommunicationSettings | Error]:
    """Replace the caller's communication/presence dial (upsert; full representation)

     Masks must combine only the known AUDIENCE bits (PUBLIC=1, HUB=2, TEAM=4, ORG=8, FRIEND=32); 0 means
    nobody. Blocks always override the dial, and appear_offline hides presence from everyone.

    Args:
        body (PutMeCommunicationSettingsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[CommunicationSettings | Error]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    body: PutMeCommunicationSettingsBody | Unset = UNSET,
) -> CommunicationSettings | Error | None:
    """Replace the caller's communication/presence dial (upsert; full representation)

     Masks must combine only the known AUDIENCE bits (PUBLIC=1, HUB=2, TEAM=4, ORG=8, FRIEND=32); 0 means
    nobody. Blocks always override the dial, and appear_offline hides presence from everyone.

    Args:
        body (PutMeCommunicationSettingsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        CommunicationSettings | Error
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
        )
    ).parsed
