from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.chat_definition_update import ChatDefinitionUpdate
from ...models.error import Error
from ...models.patch_ecosystem_chat_definitions_ecosystem_id_definition_id_response_200 import (
    PatchEcosystemChatDefinitionsEcosystemIdDefinitionIdResponse200,
)
from ...types import UNSET, Response, Unset


def _get_kwargs(
    ecosystem_id: str,
    definition_id: str,
    *,
    body: ChatDefinitionUpdate | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "patch",
        "url": "/ecosystem/chat-definitions/{ecosystem_id}/{definition_id}".format(
            ecosystem_id=quote(str(ecosystem_id), safe=""),
            definition_id=quote(str(definition_id), safe=""),
        ),
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | PatchEcosystemChatDefinitionsEcosystemIdDefinitionIdResponse200 | None:
    if response.status_code == 200:
        response_200 = PatchEcosystemChatDefinitionsEcosystemIdDefinitionIdResponse200.from_dict(
            response.json()
        )

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

    if response.status_code == 409:
        response_409 = Error.from_dict(response.json())

        return response_409

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | PatchEcosystemChatDefinitionsEcosystemIdDefinitionIdResponse200]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    ecosystem_id: str,
    definition_id: str,
    *,
    client: AuthenticatedClient,
    body: ChatDefinitionUpdate | Unset = UNSET,
) -> Response[Error | PatchEcosystemChatDefinitionsEcosystemIdDefinitionIdResponse200]:
    """Change a chat definition

     Partial update, validated as POST is. The built-in `direct` definition is read-only (400).

    Args:
        ecosystem_id (str):
        definition_id (str):
        body (ChatDefinitionUpdate | Unset): Partial. `personaIds`, when present, REPLACES the
            set.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PatchEcosystemChatDefinitionsEcosystemIdDefinitionIdResponse200]
    """

    kwargs = _get_kwargs(
        ecosystem_id=ecosystem_id,
        definition_id=definition_id,
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    ecosystem_id: str,
    definition_id: str,
    *,
    client: AuthenticatedClient,
    body: ChatDefinitionUpdate | Unset = UNSET,
) -> Error | PatchEcosystemChatDefinitionsEcosystemIdDefinitionIdResponse200 | None:
    """Change a chat definition

     Partial update, validated as POST is. The built-in `direct` definition is read-only (400).

    Args:
        ecosystem_id (str):
        definition_id (str):
        body (ChatDefinitionUpdate | Unset): Partial. `personaIds`, when present, REPLACES the
            set.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PatchEcosystemChatDefinitionsEcosystemIdDefinitionIdResponse200
    """

    return sync_detailed(
        ecosystem_id=ecosystem_id,
        definition_id=definition_id,
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    ecosystem_id: str,
    definition_id: str,
    *,
    client: AuthenticatedClient,
    body: ChatDefinitionUpdate | Unset = UNSET,
) -> Response[Error | PatchEcosystemChatDefinitionsEcosystemIdDefinitionIdResponse200]:
    """Change a chat definition

     Partial update, validated as POST is. The built-in `direct` definition is read-only (400).

    Args:
        ecosystem_id (str):
        definition_id (str):
        body (ChatDefinitionUpdate | Unset): Partial. `personaIds`, when present, REPLACES the
            set.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PatchEcosystemChatDefinitionsEcosystemIdDefinitionIdResponse200]
    """

    kwargs = _get_kwargs(
        ecosystem_id=ecosystem_id,
        definition_id=definition_id,
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    ecosystem_id: str,
    definition_id: str,
    *,
    client: AuthenticatedClient,
    body: ChatDefinitionUpdate | Unset = UNSET,
) -> Error | PatchEcosystemChatDefinitionsEcosystemIdDefinitionIdResponse200 | None:
    """Change a chat definition

     Partial update, validated as POST is. The built-in `direct` definition is read-only (400).

    Args:
        ecosystem_id (str):
        definition_id (str):
        body (ChatDefinitionUpdate | Unset): Partial. `personaIds`, when present, REPLACES the
            set.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PatchEcosystemChatDefinitionsEcosystemIdDefinitionIdResponse200
    """

    return (
        await asyncio_detailed(
            ecosystem_id=ecosystem_id,
            definition_id=definition_id,
            client=client,
            body=body,
        )
    ).parsed
