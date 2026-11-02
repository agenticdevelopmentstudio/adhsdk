from http import HTTPStatus
from typing import Any, cast
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...types import UNSET, Response, Unset


def _get_kwargs(
    registry_id: str,
    entry_id: str,
    *,
    workspace: str | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["workspace"] = workspace

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "delete",
        "url": "/registry/registries/{registry_id}/entries/{entry_id}".format(
            registry_id=quote(str(registry_id), safe=""),
            entry_id=quote(str(entry_id), safe=""),
        ),
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Any | Error | None:
    if response.status_code == 204:
        response_204 = cast(Any, None)
        return response_204

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
) -> Response[Any | Error]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    registry_id: str,
    entry_id: str,
    *,
    client: AuthenticatedClient,
    workspace: str | Unset = UNSET,
) -> Response[Any | Error]:
    """Soft-delete an entry (frees its slug and its one-per-registry owner slot)

    Args:
        registry_id (str):
        entry_id (str):
        workspace (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Any | Error]
    """

    kwargs = _get_kwargs(
        registry_id=registry_id,
        entry_id=entry_id,
        workspace=workspace,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    registry_id: str,
    entry_id: str,
    *,
    client: AuthenticatedClient,
    workspace: str | Unset = UNSET,
) -> Any | Error | None:
    """Soft-delete an entry (frees its slug and its one-per-registry owner slot)

    Args:
        registry_id (str):
        entry_id (str):
        workspace (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Any | Error
    """

    return sync_detailed(
        registry_id=registry_id,
        entry_id=entry_id,
        client=client,
        workspace=workspace,
    ).parsed


async def asyncio_detailed(
    registry_id: str,
    entry_id: str,
    *,
    client: AuthenticatedClient,
    workspace: str | Unset = UNSET,
) -> Response[Any | Error]:
    """Soft-delete an entry (frees its slug and its one-per-registry owner slot)

    Args:
        registry_id (str):
        entry_id (str):
        workspace (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Any | Error]
    """

    kwargs = _get_kwargs(
        registry_id=registry_id,
        entry_id=entry_id,
        workspace=workspace,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    registry_id: str,
    entry_id: str,
    *,
    client: AuthenticatedClient,
    workspace: str | Unset = UNSET,
) -> Any | Error | None:
    """Soft-delete an entry (frees its slug and its one-per-registry owner slot)

    Args:
        registry_id (str):
        entry_id (str):
        workspace (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Any | Error
    """

    return (
        await asyncio_detailed(
            registry_id=registry_id,
            entry_id=entry_id,
            client=client,
            workspace=workspace,
        )
    ).parsed
