from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.application_client_auth import ApplicationClientAuth
from ...models.application_client_auth_update import ApplicationClientAuthUpdate
from ...models.error import Error
from ...types import UNSET, Response, Unset


def _get_kwargs(
    app_id: str,
    *,
    body: ApplicationClientAuthUpdate | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "put",
        "url": "/ecosystem/applications/{app_id}/client-auth".format(
            app_id=quote(str(app_id), safe=""),
        ),
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> ApplicationClientAuth | Error | None:
    if response.status_code == 200:
        response_200 = ApplicationClientAuth.from_dict(response.json())

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
) -> Response[ApplicationClientAuth | Error]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    app_id: str,
    *,
    client: AuthenticatedClient,
    body: ApplicationClientAuthUpdate | Unset = UNSET,
) -> Response[ApplicationClientAuth | Error]:
    """Update an application's client auth

     Requires managing the application's ecosystem. Every 400 is checked before anything is written; the
    registration Hydra client is written last.

    Args:
        app_id (str):
        body (ApplicationClientAuthUpdate | Unset): `registration: null` removes the application
            registration.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[ApplicationClientAuth | Error]
    """

    kwargs = _get_kwargs(
        app_id=app_id,
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    app_id: str,
    *,
    client: AuthenticatedClient,
    body: ApplicationClientAuthUpdate | Unset = UNSET,
) -> ApplicationClientAuth | Error | None:
    """Update an application's client auth

     Requires managing the application's ecosystem. Every 400 is checked before anything is written; the
    registration Hydra client is written last.

    Args:
        app_id (str):
        body (ApplicationClientAuthUpdate | Unset): `registration: null` removes the application
            registration.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        ApplicationClientAuth | Error
    """

    return sync_detailed(
        app_id=app_id,
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    app_id: str,
    *,
    client: AuthenticatedClient,
    body: ApplicationClientAuthUpdate | Unset = UNSET,
) -> Response[ApplicationClientAuth | Error]:
    """Update an application's client auth

     Requires managing the application's ecosystem. Every 400 is checked before anything is written; the
    registration Hydra client is written last.

    Args:
        app_id (str):
        body (ApplicationClientAuthUpdate | Unset): `registration: null` removes the application
            registration.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[ApplicationClientAuth | Error]
    """

    kwargs = _get_kwargs(
        app_id=app_id,
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    app_id: str,
    *,
    client: AuthenticatedClient,
    body: ApplicationClientAuthUpdate | Unset = UNSET,
) -> ApplicationClientAuth | Error | None:
    """Update an application's client auth

     Requires managing the application's ecosystem. Every 400 is checked before anything is written; the
    registration Hydra client is written last.

    Args:
        app_id (str):
        body (ApplicationClientAuthUpdate | Unset): `registration: null` removes the application
            registration.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        ApplicationClientAuth | Error
    """

    return (
        await asyncio_detailed(
            app_id=app_id,
            client=client,
            body=body,
        )
    ).parsed
