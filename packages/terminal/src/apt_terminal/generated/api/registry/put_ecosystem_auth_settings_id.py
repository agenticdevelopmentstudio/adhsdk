from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.ecosystem_auth_settings import EcosystemAuthSettings
from ...models.ecosystem_auth_settings_update import EcosystemAuthSettingsUpdate
from ...models.error import Error
from ...types import UNSET, Response, Unset


def _get_kwargs(
    id: str,
    *,
    body: EcosystemAuthSettingsUpdate | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "put",
        "url": "/ecosystem/auth-settings/{id}".format(
            id=quote(str(id), safe=""),
        ),
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> EcosystemAuthSettings | Error | None:
    if response.status_code == 200:
        response_200 = EcosystemAuthSettings.from_dict(response.json())

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
) -> Response[EcosystemAuthSettings | Error]:
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
    body: EcosystemAuthSettingsUpdate | Unset = UNSET,
) -> Response[EcosystemAuthSettings | Error]:
    """Update an ecosystem's sign-up/sign-in policy

    Args:
        id (str):
        body (EcosystemAuthSettingsUpdate | Unset): A partial update — supply at least one field.
            Anything omitted is left as it was.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[EcosystemAuthSettings | Error]
    """

    kwargs = _get_kwargs(
        id=id,
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    *,
    client: AuthenticatedClient,
    body: EcosystemAuthSettingsUpdate | Unset = UNSET,
) -> EcosystemAuthSettings | Error | None:
    """Update an ecosystem's sign-up/sign-in policy

    Args:
        id (str):
        body (EcosystemAuthSettingsUpdate | Unset): A partial update — supply at least one field.
            Anything omitted is left as it was.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        EcosystemAuthSettings | Error
    """

    return sync_detailed(
        id=id,
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
    body: EcosystemAuthSettingsUpdate | Unset = UNSET,
) -> Response[EcosystemAuthSettings | Error]:
    """Update an ecosystem's sign-up/sign-in policy

    Args:
        id (str):
        body (EcosystemAuthSettingsUpdate | Unset): A partial update — supply at least one field.
            Anything omitted is left as it was.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[EcosystemAuthSettings | Error]
    """

    kwargs = _get_kwargs(
        id=id,
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    *,
    client: AuthenticatedClient,
    body: EcosystemAuthSettingsUpdate | Unset = UNSET,
) -> EcosystemAuthSettings | Error | None:
    """Update an ecosystem's sign-up/sign-in policy

    Args:
        id (str):
        body (EcosystemAuthSettingsUpdate | Unset): A partial update — supply at least one field.
            Anything omitted is left as it was.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        EcosystemAuthSettings | Error
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            body=body,
        )
    ).parsed
