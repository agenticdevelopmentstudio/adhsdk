from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.presence_list import PresenceList
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    user_ids: str | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["userIds"] = user_ids

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/presence",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | PresenceList | None:
    if response.status_code == 200:
        response_200 = PresenceList.from_dict(response.json())

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
) -> Response[Error | PresenceList]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    user_ids: str | Unset = UNSET,
) -> Response[Error | PresenceList]:
    """Look up the presence of specific users

     Returns one entry per requested id. The caller always sees their own true state; every other id is
    visibility-gated, and one the caller may not see reports `online: false, lastSeenAt: null` —
    indistinguishable from genuinely offline.

    Args:
        user_ids (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PresenceList]
    """

    kwargs = _get_kwargs(
        user_ids=user_ids,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    user_ids: str | Unset = UNSET,
) -> Error | PresenceList | None:
    """Look up the presence of specific users

     Returns one entry per requested id. The caller always sees their own true state; every other id is
    visibility-gated, and one the caller may not see reports `online: false, lastSeenAt: null` —
    indistinguishable from genuinely offline.

    Args:
        user_ids (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PresenceList
    """

    return sync_detailed(
        client=client,
        user_ids=user_ids,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    user_ids: str | Unset = UNSET,
) -> Response[Error | PresenceList]:
    """Look up the presence of specific users

     Returns one entry per requested id. The caller always sees their own true state; every other id is
    visibility-gated, and one the caller may not see reports `online: false, lastSeenAt: null` —
    indistinguishable from genuinely offline.

    Args:
        user_ids (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PresenceList]
    """

    kwargs = _get_kwargs(
        user_ids=user_ids,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    user_ids: str | Unset = UNSET,
) -> Error | PresenceList | None:
    """Look up the presence of specific users

     Returns one entry per requested id. The caller always sees their own true state; every other id is
    visibility-gated, and one the caller may not see reports `online: false, lastSeenAt: null` —
    indistinguishable from genuinely offline.

    Args:
        user_ids (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PresenceList
    """

    return (
        await asyncio_detailed(
            client=client,
            user_ids=user_ids,
        )
    ).parsed
