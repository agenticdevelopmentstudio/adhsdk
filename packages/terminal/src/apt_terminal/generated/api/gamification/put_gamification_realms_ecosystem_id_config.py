from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.gamification_realm_config_update import GamificationRealmConfigUpdate
from ...models.put_gamification_realms_ecosystem_id_config_body import (
    PutGamificationRealmsEcosystemIdConfigBody,
)
from ...types import UNSET, Response, Unset


def _get_kwargs(
    ecosystem_id: str,
    *,
    body: PutGamificationRealmsEcosystemIdConfigBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "put",
        "url": "/gamification/realms/{ecosystem_id}/config".format(
            ecosystem_id=quote(str(ecosystem_id), safe=""),
        ),
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | GamificationRealmConfigUpdate | None:
    if response.status_code == 200:
        response_200 = GamificationRealmConfigUpdate.from_dict(response.json())

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

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | GamificationRealmConfigUpdate]:
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
    body: PutGamificationRealmsEcosystemIdConfigBody | Unset = UNSET,
) -> Response[Error | GamificationRealmConfigUpdate]:
    """Update a realm’s gamification config (admin, partial) — moving mode out of `none` triggers a
    retroactive replay, and entering `game` mode provisions the ecosystem’s game

    Args:
        ecosystem_id (str):
        body (PutGamificationRealmsEcosystemIdConfigBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GamificationRealmConfigUpdate]
    """

    kwargs = _get_kwargs(
        ecosystem_id=ecosystem_id,
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    ecosystem_id: str,
    *,
    client: AuthenticatedClient,
    body: PutGamificationRealmsEcosystemIdConfigBody | Unset = UNSET,
) -> Error | GamificationRealmConfigUpdate | None:
    """Update a realm’s gamification config (admin, partial) — moving mode out of `none` triggers a
    retroactive replay, and entering `game` mode provisions the ecosystem’s game

    Args:
        ecosystem_id (str):
        body (PutGamificationRealmsEcosystemIdConfigBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GamificationRealmConfigUpdate
    """

    return sync_detailed(
        ecosystem_id=ecosystem_id,
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    ecosystem_id: str,
    *,
    client: AuthenticatedClient,
    body: PutGamificationRealmsEcosystemIdConfigBody | Unset = UNSET,
) -> Response[Error | GamificationRealmConfigUpdate]:
    """Update a realm’s gamification config (admin, partial) — moving mode out of `none` triggers a
    retroactive replay, and entering `game` mode provisions the ecosystem’s game

    Args:
        ecosystem_id (str):
        body (PutGamificationRealmsEcosystemIdConfigBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GamificationRealmConfigUpdate]
    """

    kwargs = _get_kwargs(
        ecosystem_id=ecosystem_id,
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    ecosystem_id: str,
    *,
    client: AuthenticatedClient,
    body: PutGamificationRealmsEcosystemIdConfigBody | Unset = UNSET,
) -> Error | GamificationRealmConfigUpdate | None:
    """Update a realm’s gamification config (admin, partial) — moving mode out of `none` triggers a
    retroactive replay, and entering `game` mode provisions the ecosystem’s game

    Args:
        ecosystem_id (str):
        body (PutGamificationRealmsEcosystemIdConfigBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GamificationRealmConfigUpdate
    """

    return (
        await asyncio_detailed(
            ecosystem_id=ecosystem_id,
            client=client,
            body=body,
        )
    ).parsed
