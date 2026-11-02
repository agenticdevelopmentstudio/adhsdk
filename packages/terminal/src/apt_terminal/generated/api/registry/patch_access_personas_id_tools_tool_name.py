from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.patch_access_personas_id_tools_tool_name_body import (
    PatchAccessPersonasIdToolsToolNameBody,
)
from ...models.patch_access_personas_id_tools_tool_name_response_200 import (
    PatchAccessPersonasIdToolsToolNameResponse200,
)
from ...types import UNSET, Response, Unset


def _get_kwargs(
    id: str,
    tool_name: str,
    *,
    body: PatchAccessPersonasIdToolsToolNameBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "patch",
        "url": "/access/personas/{id}/tools/{tool_name}".format(
            id=quote(str(id), safe=""),
            tool_name=quote(str(tool_name), safe=""),
        ),
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | PatchAccessPersonasIdToolsToolNameResponse200 | None:
    if response.status_code == 200:
        response_200 = PatchAccessPersonasIdToolsToolNameResponse200.from_dict(response.json())

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
) -> Response[Error | PatchAccessPersonasIdToolsToolNameResponse200]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    id: str,
    tool_name: str,
    *,
    client: AuthenticatedClient,
    body: PatchAccessPersonasIdToolsToolNameBody | Unset = UNSET,
) -> Response[Error | PatchAccessPersonasIdToolsToolNameResponse200]:
    """Set a tool grant's autonomy flag (404 if the tool isn't granted)

    Args:
        id (str):
        tool_name (str):
        body (PatchAccessPersonasIdToolsToolNameBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PatchAccessPersonasIdToolsToolNameResponse200]
    """

    kwargs = _get_kwargs(
        id=id,
        tool_name=tool_name,
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    tool_name: str,
    *,
    client: AuthenticatedClient,
    body: PatchAccessPersonasIdToolsToolNameBody | Unset = UNSET,
) -> Error | PatchAccessPersonasIdToolsToolNameResponse200 | None:
    """Set a tool grant's autonomy flag (404 if the tool isn't granted)

    Args:
        id (str):
        tool_name (str):
        body (PatchAccessPersonasIdToolsToolNameBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PatchAccessPersonasIdToolsToolNameResponse200
    """

    return sync_detailed(
        id=id,
        tool_name=tool_name,
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    id: str,
    tool_name: str,
    *,
    client: AuthenticatedClient,
    body: PatchAccessPersonasIdToolsToolNameBody | Unset = UNSET,
) -> Response[Error | PatchAccessPersonasIdToolsToolNameResponse200]:
    """Set a tool grant's autonomy flag (404 if the tool isn't granted)

    Args:
        id (str):
        tool_name (str):
        body (PatchAccessPersonasIdToolsToolNameBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PatchAccessPersonasIdToolsToolNameResponse200]
    """

    kwargs = _get_kwargs(
        id=id,
        tool_name=tool_name,
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    tool_name: str,
    *,
    client: AuthenticatedClient,
    body: PatchAccessPersonasIdToolsToolNameBody | Unset = UNSET,
) -> Error | PatchAccessPersonasIdToolsToolNameResponse200 | None:
    """Set a tool grant's autonomy flag (404 if the tool isn't granted)

    Args:
        id (str):
        tool_name (str):
        body (PatchAccessPersonasIdToolsToolNameBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PatchAccessPersonasIdToolsToolNameResponse200
    """

    return (
        await asyncio_detailed(
            id=id,
            tool_name=tool_name,
            client=client,
            body=body,
        )
    ).parsed
