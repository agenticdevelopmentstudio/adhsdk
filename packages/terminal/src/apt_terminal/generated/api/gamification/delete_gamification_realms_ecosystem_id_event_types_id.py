from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.delete_gamification_realms_ecosystem_id_event_types_id_response_200 import (
    DeleteGamificationRealmsEcosystemIdEventTypesIdResponse200,
)
from ...models.error import Error
from ...types import Response


def _get_kwargs(
    ecosystem_id: str,
    id: str,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "delete",
        "url": "/gamification/realms/{ecosystem_id}/event-types/{id}".format(
            ecosystem_id=quote(str(ecosystem_id), safe=""),
            id=quote(str(id), safe=""),
        ),
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> DeleteGamificationRealmsEcosystemIdEventTypesIdResponse200 | Error | None:
    if response.status_code == 200:
        response_200 = DeleteGamificationRealmsEcosystemIdEventTypesIdResponse200.from_dict(
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
) -> Response[DeleteGamificationRealmsEcosystemIdEventTypesIdResponse200 | Error]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    ecosystem_id: str,
    id: str,
    *,
    client: AuthenticatedClient,
) -> Response[DeleteGamificationRealmsEcosystemIdEventTypesIdResponse200 | Error]:
    """Delete a realm-owned custom event type (owner or admin)

    Args:
        ecosystem_id (str):
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[DeleteGamificationRealmsEcosystemIdEventTypesIdResponse200 | Error]
    """

    kwargs = _get_kwargs(
        ecosystem_id=ecosystem_id,
        id=id,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    ecosystem_id: str,
    id: str,
    *,
    client: AuthenticatedClient,
) -> DeleteGamificationRealmsEcosystemIdEventTypesIdResponse200 | Error | None:
    """Delete a realm-owned custom event type (owner or admin)

    Args:
        ecosystem_id (str):
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        DeleteGamificationRealmsEcosystemIdEventTypesIdResponse200 | Error
    """

    return sync_detailed(
        ecosystem_id=ecosystem_id,
        id=id,
        client=client,
    ).parsed


async def asyncio_detailed(
    ecosystem_id: str,
    id: str,
    *,
    client: AuthenticatedClient,
) -> Response[DeleteGamificationRealmsEcosystemIdEventTypesIdResponse200 | Error]:
    """Delete a realm-owned custom event type (owner or admin)

    Args:
        ecosystem_id (str):
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[DeleteGamificationRealmsEcosystemIdEventTypesIdResponse200 | Error]
    """

    kwargs = _get_kwargs(
        ecosystem_id=ecosystem_id,
        id=id,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    ecosystem_id: str,
    id: str,
    *,
    client: AuthenticatedClient,
) -> DeleteGamificationRealmsEcosystemIdEventTypesIdResponse200 | Error | None:
    """Delete a realm-owned custom event type (owner or admin)

    Args:
        ecosystem_id (str):
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        DeleteGamificationRealmsEcosystemIdEventTypesIdResponse200 | Error
    """

    return (
        await asyncio_detailed(
            ecosystem_id=ecosystem_id,
            id=id,
            client=client,
        )
    ).parsed
