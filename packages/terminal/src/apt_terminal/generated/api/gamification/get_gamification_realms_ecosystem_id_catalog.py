from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.gamification_catalog import GamificationCatalog
from ...types import Response


def _get_kwargs(
    ecosystem_id: str,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/gamification/realms/{ecosystem_id}/catalog".format(
            ecosystem_id=quote(str(ecosystem_id), safe=""),
        ),
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | GamificationCatalog | None:
    if response.status_code == 200:
        response_200 = GamificationCatalog.from_dict(response.json())

        return response_200

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
) -> Response[Error | GamificationCatalog]:
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
) -> Response[Error | GamificationCatalog]:
    """A realm’s effective catalog (admin) — defaults + realm overrides, source-tagged

    Args:
        ecosystem_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GamificationCatalog]
    """

    kwargs = _get_kwargs(
        ecosystem_id=ecosystem_id,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    ecosystem_id: str,
    *,
    client: AuthenticatedClient,
) -> Error | GamificationCatalog | None:
    """A realm’s effective catalog (admin) — defaults + realm overrides, source-tagged

    Args:
        ecosystem_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GamificationCatalog
    """

    return sync_detailed(
        ecosystem_id=ecosystem_id,
        client=client,
    ).parsed


async def asyncio_detailed(
    ecosystem_id: str,
    *,
    client: AuthenticatedClient,
) -> Response[Error | GamificationCatalog]:
    """A realm’s effective catalog (admin) — defaults + realm overrides, source-tagged

    Args:
        ecosystem_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GamificationCatalog]
    """

    kwargs = _get_kwargs(
        ecosystem_id=ecosystem_id,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    ecosystem_id: str,
    *,
    client: AuthenticatedClient,
) -> Error | GamificationCatalog | None:
    """A realm’s effective catalog (admin) — defaults + realm overrides, source-tagged

    Args:
        ecosystem_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GamificationCatalog
    """

    return (
        await asyncio_detailed(
            ecosystem_id=ecosystem_id,
            client=client,
        )
    ).parsed
