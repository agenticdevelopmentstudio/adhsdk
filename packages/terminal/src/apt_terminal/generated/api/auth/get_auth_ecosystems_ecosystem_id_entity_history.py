from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.entity_history_entry import EntityHistoryEntry
from ...models.error import Error
from ...types import UNSET, Response


def _get_kwargs(
    ecosystem_id: str,
    *,
    subject_table: str,
    subject_id: str,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["subjectTable"] = subject_table

    params["subjectId"] = subject_id

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/auth/ecosystems/{ecosystem_id}/entity-history".format(
            ecosystem_id=quote(str(ecosystem_id), safe=""),
        ),
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | list[EntityHistoryEntry] | None:
    if response.status_code == 200:
        response_200 = []
        _response_200 = response.json()
        for response_200_item_data in _response_200:
            response_200_item = EntityHistoryEntry.from_dict(response_200_item_data)

            response_200.append(response_200_item)

        return response_200

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
) -> Response[Error | list[EntityHistoryEntry]]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    ecosystem_id: str,
    *,
    client: AuthenticatedClient,
    subject_table: str,
    subject_id: str,
) -> Response[Error | list[EntityHistoryEntry]]:
    """List a subject’s entity history within an ecosystem (owner-scoped)

    Args:
        ecosystem_id (str):
        subject_table (str):
        subject_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | list[EntityHistoryEntry]]
    """

    kwargs = _get_kwargs(
        ecosystem_id=ecosystem_id,
        subject_table=subject_table,
        subject_id=subject_id,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    ecosystem_id: str,
    *,
    client: AuthenticatedClient,
    subject_table: str,
    subject_id: str,
) -> Error | list[EntityHistoryEntry] | None:
    """List a subject’s entity history within an ecosystem (owner-scoped)

    Args:
        ecosystem_id (str):
        subject_table (str):
        subject_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | list[EntityHistoryEntry]
    """

    return sync_detailed(
        ecosystem_id=ecosystem_id,
        client=client,
        subject_table=subject_table,
        subject_id=subject_id,
    ).parsed


async def asyncio_detailed(
    ecosystem_id: str,
    *,
    client: AuthenticatedClient,
    subject_table: str,
    subject_id: str,
) -> Response[Error | list[EntityHistoryEntry]]:
    """List a subject’s entity history within an ecosystem (owner-scoped)

    Args:
        ecosystem_id (str):
        subject_table (str):
        subject_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | list[EntityHistoryEntry]]
    """

    kwargs = _get_kwargs(
        ecosystem_id=ecosystem_id,
        subject_table=subject_table,
        subject_id=subject_id,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    ecosystem_id: str,
    *,
    client: AuthenticatedClient,
    subject_table: str,
    subject_id: str,
) -> Error | list[EntityHistoryEntry] | None:
    """List a subject’s entity history within an ecosystem (owner-scoped)

    Args:
        ecosystem_id (str):
        subject_table (str):
        subject_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | list[EntityHistoryEntry]
    """

    return (
        await asyncio_detailed(
            ecosystem_id=ecosystem_id,
            client=client,
            subject_table=subject_table,
            subject_id=subject_id,
        )
    ).parsed
