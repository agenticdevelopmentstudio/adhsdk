from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.gamification_custom_event_result import GamificationCustomEventResult
from ...models.post_gamification_realms_ecosystem_id_events_body import (
    PostGamificationRealmsEcosystemIdEventsBody,
)
from ...types import UNSET, Response, Unset


def _get_kwargs(
    ecosystem_id: str,
    *,
    body: PostGamificationRealmsEcosystemIdEventsBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/gamification/realms/{ecosystem_id}/events".format(
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
) -> Error | GamificationCustomEventResult | None:
    if response.status_code == 200:
        response_200 = GamificationCustomEventResult.from_dict(response.json())

        return response_200

    if response.status_code == 201:
        response_201 = GamificationCustomEventResult.from_dict(response.json())

        return response_201

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
) -> Response[Error | GamificationCustomEventResult]:
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
    body: PostGamificationRealmsEcosystemIdEventsBody | Unset = UNSET,
) -> Response[Error | GamificationCustomEventResult]:
    """Ingest a realm custom event (owner or admin) — bumps the type’s stat and awards any newly-earned
    badges

    Args:
        ecosystem_id (str):
        body (PostGamificationRealmsEcosystemIdEventsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GamificationCustomEventResult]
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
    body: PostGamificationRealmsEcosystemIdEventsBody | Unset = UNSET,
) -> Error | GamificationCustomEventResult | None:
    """Ingest a realm custom event (owner or admin) — bumps the type’s stat and awards any newly-earned
    badges

    Args:
        ecosystem_id (str):
        body (PostGamificationRealmsEcosystemIdEventsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GamificationCustomEventResult
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
    body: PostGamificationRealmsEcosystemIdEventsBody | Unset = UNSET,
) -> Response[Error | GamificationCustomEventResult]:
    """Ingest a realm custom event (owner or admin) — bumps the type’s stat and awards any newly-earned
    badges

    Args:
        ecosystem_id (str):
        body (PostGamificationRealmsEcosystemIdEventsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GamificationCustomEventResult]
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
    body: PostGamificationRealmsEcosystemIdEventsBody | Unset = UNSET,
) -> Error | GamificationCustomEventResult | None:
    """Ingest a realm custom event (owner or admin) — bumps the type’s stat and awards any newly-earned
    badges

    Args:
        ecosystem_id (str):
        body (PostGamificationRealmsEcosystemIdEventsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GamificationCustomEventResult
    """

    return (
        await asyncio_detailed(
            ecosystem_id=ecosystem_id,
            client=client,
            body=body,
        )
    ).parsed
