from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.delete_audience_lists_list_id_members_contact_id_response_200 import (
    DeleteAudienceListsListIdMembersContactIdResponse200,
)
from ...models.error import Error
from ...types import Response


def _get_kwargs(
    list_id: str,
    contact_id: str,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "delete",
        "url": "/audience/lists/{list_id}/members/{contact_id}".format(
            list_id=quote(str(list_id), safe=""),
            contact_id=quote(str(contact_id), safe=""),
        ),
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> DeleteAudienceListsListIdMembersContactIdResponse200 | Error | None:
    if response.status_code == 200:
        response_200 = DeleteAudienceListsListIdMembersContactIdResponse200.from_dict(
            response.json()
        )

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
) -> Response[DeleteAudienceListsListIdMembersContactIdResponse200 | Error]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    list_id: str,
    contact_id: str,
    *,
    client: AuthenticatedClient,
) -> Response[DeleteAudienceListsListIdMembersContactIdResponse200 | Error]:
    """Remove a contact from a list

    Args:
        list_id (str):
        contact_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[DeleteAudienceListsListIdMembersContactIdResponse200 | Error]
    """

    kwargs = _get_kwargs(
        list_id=list_id,
        contact_id=contact_id,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    list_id: str,
    contact_id: str,
    *,
    client: AuthenticatedClient,
) -> DeleteAudienceListsListIdMembersContactIdResponse200 | Error | None:
    """Remove a contact from a list

    Args:
        list_id (str):
        contact_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        DeleteAudienceListsListIdMembersContactIdResponse200 | Error
    """

    return sync_detailed(
        list_id=list_id,
        contact_id=contact_id,
        client=client,
    ).parsed


async def asyncio_detailed(
    list_id: str,
    contact_id: str,
    *,
    client: AuthenticatedClient,
) -> Response[DeleteAudienceListsListIdMembersContactIdResponse200 | Error]:
    """Remove a contact from a list

    Args:
        list_id (str):
        contact_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[DeleteAudienceListsListIdMembersContactIdResponse200 | Error]
    """

    kwargs = _get_kwargs(
        list_id=list_id,
        contact_id=contact_id,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    list_id: str,
    contact_id: str,
    *,
    client: AuthenticatedClient,
) -> DeleteAudienceListsListIdMembersContactIdResponse200 | Error | None:
    """Remove a contact from a list

    Args:
        list_id (str):
        contact_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        DeleteAudienceListsListIdMembersContactIdResponse200 | Error
    """

    return (
        await asyncio_detailed(
            list_id=list_id,
            contact_id=contact_id,
            client=client,
        )
    ).parsed
