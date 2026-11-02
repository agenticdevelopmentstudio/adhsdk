from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.api_token_created import ApiTokenCreated
from ...models.error import Error
from ...models.post_ecosystem_applications_app_id_tokens_body import (
    PostEcosystemApplicationsAppIdTokensBody,
)
from ...types import UNSET, Response, Unset


def _get_kwargs(
    app_id: str,
    *,
    body: PostEcosystemApplicationsAppIdTokensBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/ecosystem/applications/{app_id}/tokens".format(
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
) -> ApiTokenCreated | Error | None:
    if response.status_code == 201:
        response_201 = ApiTokenCreated.from_dict(response.json())

        return response_201

    if response.status_code == 400:
        response_400 = Error.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = Error.from_dict(response.json())

        return response_401

    if response.status_code == 404:
        response_404 = Error.from_dict(response.json())

        return response_404

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[ApiTokenCreated | Error]:
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
    body: PostEcosystemApplicationsAppIdTokensBody | Unset = UNSET,
) -> Response[ApiTokenCreated | Error]:
    """Mint an API token for the application (raw value shown once)

     The application must belong to the caller’s ecosystem (404 otherwise). Minting also grants the app
    CRUD on its ecosystem’s default bucket so the token works immediately.

    Args:
        app_id (str):
        body (PostEcosystemApplicationsAppIdTokensBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[ApiTokenCreated | Error]
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
    body: PostEcosystemApplicationsAppIdTokensBody | Unset = UNSET,
) -> ApiTokenCreated | Error | None:
    """Mint an API token for the application (raw value shown once)

     The application must belong to the caller’s ecosystem (404 otherwise). Minting also grants the app
    CRUD on its ecosystem’s default bucket so the token works immediately.

    Args:
        app_id (str):
        body (PostEcosystemApplicationsAppIdTokensBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        ApiTokenCreated | Error
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
    body: PostEcosystemApplicationsAppIdTokensBody | Unset = UNSET,
) -> Response[ApiTokenCreated | Error]:
    """Mint an API token for the application (raw value shown once)

     The application must belong to the caller’s ecosystem (404 otherwise). Minting also grants the app
    CRUD on its ecosystem’s default bucket so the token works immediately.

    Args:
        app_id (str):
        body (PostEcosystemApplicationsAppIdTokensBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[ApiTokenCreated | Error]
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
    body: PostEcosystemApplicationsAppIdTokensBody | Unset = UNSET,
) -> ApiTokenCreated | Error | None:
    """Mint an API token for the application (raw value shown once)

     The application must belong to the caller’s ecosystem (404 otherwise). Minting also grants the app
    CRUD on its ecosystem’s default bucket so the token works immediately.

    Args:
        app_id (str):
        body (PostEcosystemApplicationsAppIdTokensBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        ApiTokenCreated | Error
    """

    return (
        await asyncio_detailed(
            app_id=app_id,
            client=client,
            body=body,
        )
    ).parsed
