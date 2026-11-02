from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.announcement_accepted import AnnouncementAccepted
from ...models.announcement_create import AnnouncementCreate
from ...models.error import Error
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    body: AnnouncementCreate | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/announcements",
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> AnnouncementAccepted | Error | None:
    if response.status_code == 202:
        response_202 = AnnouncementAccepted.from_dict(response.json())

        return response_202

    if response.status_code == 400:
        response_400 = Error.from_dict(response.json())

        return response_400

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
) -> Response[AnnouncementAccepted | Error]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    body: AnnouncementCreate | Unset = UNSET,
) -> Response[AnnouncementAccepted | Error]:
    """Compose and send an announcement

     Accepted, not completed: the response is 202 and delivery runs in the background. Poll the
    announcement to watch `sentCount` climb and `sentAt` appear. A delivery failure therefore never
    surfaces here.

    Args:
        body (AnnouncementCreate | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[AnnouncementAccepted | Error]
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
    body: AnnouncementCreate | Unset = UNSET,
) -> AnnouncementAccepted | Error | None:
    """Compose and send an announcement

     Accepted, not completed: the response is 202 and delivery runs in the background. Poll the
    announcement to watch `sentCount` climb and `sentAt` appear. A delivery failure therefore never
    surfaces here.

    Args:
        body (AnnouncementCreate | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        AnnouncementAccepted | Error
    """

    return sync_detailed(
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    body: AnnouncementCreate | Unset = UNSET,
) -> Response[AnnouncementAccepted | Error]:
    """Compose and send an announcement

     Accepted, not completed: the response is 202 and delivery runs in the background. Poll the
    announcement to watch `sentCount` climb and `sentAt` appear. A delivery failure therefore never
    surfaces here.

    Args:
        body (AnnouncementCreate | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[AnnouncementAccepted | Error]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    body: AnnouncementCreate | Unset = UNSET,
) -> AnnouncementAccepted | Error | None:
    """Compose and send an announcement

     Accepted, not completed: the response is 202 and delivery runs in the background. Poll the
    announcement to watch `sentCount` climb and `sentAt` appear. A delivery failure therefore never
    surfaces here.

    Args:
        body (AnnouncementCreate | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        AnnouncementAccepted | Error
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
        )
    ).parsed
