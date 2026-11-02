from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.ecosystem_signin_app import EcosystemSigninApp
from ...models.ecosystem_signin_app_update import EcosystemSigninAppUpdate
from ...models.error import Error
from ...types import UNSET, Response, Unset


def _get_kwargs(
    id: str,
    client_id: str,
    *,
    body: EcosystemSigninAppUpdate | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "patch",
        "url": "/ecosystem/signin-apps/{id}/{client_id}".format(
            id=quote(str(id), safe=""),
            client_id=quote(str(client_id), safe=""),
        ),
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> EcosystemSigninApp | Error | None:
    if response.status_code == 200:
        response_200 = EcosystemSigninApp.from_dict(response.json())

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
) -> Response[EcosystemSigninApp | Error]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    id: str,
    client_id: str,
    *,
    client: AuthenticatedClient,
    body: EcosystemSigninAppUpdate | Unset = UNSET,
) -> Response[EcosystemSigninApp | Error]:
    """Update a sign-in app

     A client belonging to another ecosystem is a 404, not a 403 — the two are indistinguishable from
    outside. An internal client exists but is a 403.

    Args:
        id (str):
        client_id (str):
        body (EcosystemSigninAppUpdate | Unset): A partial update — supply at least one field.
            `slug` and the owning ecosystem are deliberately not patchable: both are identity, not
            configuration.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[EcosystemSigninApp | Error]
    """

    kwargs = _get_kwargs(
        id=id,
        client_id=client_id,
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    client_id: str,
    *,
    client: AuthenticatedClient,
    body: EcosystemSigninAppUpdate | Unset = UNSET,
) -> EcosystemSigninApp | Error | None:
    """Update a sign-in app

     A client belonging to another ecosystem is a 404, not a 403 — the two are indistinguishable from
    outside. An internal client exists but is a 403.

    Args:
        id (str):
        client_id (str):
        body (EcosystemSigninAppUpdate | Unset): A partial update — supply at least one field.
            `slug` and the owning ecosystem are deliberately not patchable: both are identity, not
            configuration.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        EcosystemSigninApp | Error
    """

    return sync_detailed(
        id=id,
        client_id=client_id,
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    id: str,
    client_id: str,
    *,
    client: AuthenticatedClient,
    body: EcosystemSigninAppUpdate | Unset = UNSET,
) -> Response[EcosystemSigninApp | Error]:
    """Update a sign-in app

     A client belonging to another ecosystem is a 404, not a 403 — the two are indistinguishable from
    outside. An internal client exists but is a 403.

    Args:
        id (str):
        client_id (str):
        body (EcosystemSigninAppUpdate | Unset): A partial update — supply at least one field.
            `slug` and the owning ecosystem are deliberately not patchable: both are identity, not
            configuration.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[EcosystemSigninApp | Error]
    """

    kwargs = _get_kwargs(
        id=id,
        client_id=client_id,
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    client_id: str,
    *,
    client: AuthenticatedClient,
    body: EcosystemSigninAppUpdate | Unset = UNSET,
) -> EcosystemSigninApp | Error | None:
    """Update a sign-in app

     A client belonging to another ecosystem is a 404, not a 403 — the two are indistinguishable from
    outside. An internal client exists but is a 403.

    Args:
        id (str):
        client_id (str):
        body (EcosystemSigninAppUpdate | Unset): A partial update — supply at least one field.
            `slug` and the owning ecosystem are deliberately not patchable: both are identity, not
            configuration.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        EcosystemSigninApp | Error
    """

    return (
        await asyncio_detailed(
            id=id,
            client_id=client_id,
            client=client,
            body=body,
        )
    ).parsed
