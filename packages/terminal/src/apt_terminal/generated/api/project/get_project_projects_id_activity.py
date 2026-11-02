from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.project_activity import ProjectActivity
from ...types import UNSET, Response, Unset


def _get_kwargs(
    id: str,
    *,
    limit: str | Unset = UNSET,
    before: str | Unset = UNSET,
    before_id: str | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["limit"] = limit

    params["before"] = before

    params["beforeId"] = before_id

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/project/projects/{id}/activity".format(
            id=quote(str(id), safe=""),
        ),
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | list[ProjectActivity] | None:
    if response.status_code == 200:
        response_200 = []
        _response_200 = response.json()
        for response_200_item_data in _response_200:
            response_200_item = ProjectActivity.from_dict(response_200_item_data)

            response_200.append(response_200_item)

        return response_200

    if response.status_code == 401:
        response_401 = Error.from_dict(response.json())

        return response_401

    if response.status_code == 404:
        response_404 = Error.from_dict(response.json())

        return response_404

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | list[ProjectActivity]]:
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
    limit: str | Unset = UNSET,
    before: str | Unset = UNSET,
    before_id: str | Unset = UNSET,
) -> Response[Error | list[ProjectActivity]]:
    """A project's activity trail (newest first, keyset-paginated)

    Args:
        id (str):
        limit (str | Unset):
        before (str | Unset):
        before_id (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | list[ProjectActivity]]
    """

    kwargs = _get_kwargs(
        id=id,
        limit=limit,
        before=before,
        before_id=before_id,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    *,
    client: AuthenticatedClient,
    limit: str | Unset = UNSET,
    before: str | Unset = UNSET,
    before_id: str | Unset = UNSET,
) -> Error | list[ProjectActivity] | None:
    """A project's activity trail (newest first, keyset-paginated)

    Args:
        id (str):
        limit (str | Unset):
        before (str | Unset):
        before_id (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | list[ProjectActivity]
    """

    return sync_detailed(
        id=id,
        client=client,
        limit=limit,
        before=before,
        before_id=before_id,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
    limit: str | Unset = UNSET,
    before: str | Unset = UNSET,
    before_id: str | Unset = UNSET,
) -> Response[Error | list[ProjectActivity]]:
    """A project's activity trail (newest first, keyset-paginated)

    Args:
        id (str):
        limit (str | Unset):
        before (str | Unset):
        before_id (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | list[ProjectActivity]]
    """

    kwargs = _get_kwargs(
        id=id,
        limit=limit,
        before=before,
        before_id=before_id,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    *,
    client: AuthenticatedClient,
    limit: str | Unset = UNSET,
    before: str | Unset = UNSET,
    before_id: str | Unset = UNSET,
) -> Error | list[ProjectActivity] | None:
    """A project's activity trail (newest first, keyset-paginated)

    Args:
        id (str):
        limit (str | Unset):
        before (str | Unset):
        before_id (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | list[ProjectActivity]
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            limit=limit,
            before=before,
            before_id=before_id,
        )
    ).parsed
