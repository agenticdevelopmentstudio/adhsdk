from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.integration_connect_api_key import IntegrationConnectApiKey
from ...models.integration_connect_app_password import IntegrationConnectAppPassword
from ...models.integration_connect_github_app import IntegrationConnectGithubApp
from ...models.integration_connect_o_auth import IntegrationConnectOAuth
from ...models.integration_connect_o_auth_instance import IntegrationConnectOAuthInstance
from ...models.integration_connect_plaid_link import IntegrationConnectPlaidLink
from ...models.integration_connection import IntegrationConnection
from ...models.problem_details import ProblemDetails
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    body: IntegrationConnectApiKey
    | IntegrationConnectAppPassword
    | IntegrationConnectGithubApp
    | IntegrationConnectOAuth
    | IntegrationConnectOAuthInstance
    | IntegrationConnectPlaidLink
    | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/integrations/connect",
    }

    if (
        isinstance(body, IntegrationConnectOAuth)
        or isinstance(body, IntegrationConnectApiKey)
        or isinstance(body, IntegrationConnectAppPassword)
        or isinstance(body, IntegrationConnectPlaidLink)
        or isinstance(body, IntegrationConnectOAuthInstance)
    ):
        _kwargs["json"] = body.to_dict()
    else:
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> IntegrationConnection | ProblemDetails | None:
    if response.status_code == 200:
        response_200 = IntegrationConnection.from_dict(response.json())

        return response_200

    if response.status_code == 400:
        response_400 = ProblemDetails.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = ProblemDetails.from_dict(response.json())

        return response_401

    if response.status_code == 403:
        response_403 = ProblemDetails.from_dict(response.json())

        return response_403

    if response.status_code == 404:
        response_404 = ProblemDetails.from_dict(response.json())

        return response_404

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[IntegrationConnection | ProblemDetails]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    body: IntegrationConnectApiKey
    | IntegrationConnectAppPassword
    | IntegrationConnectGithubApp
    | IntegrationConnectOAuth
    | IntegrationConnectOAuthInstance
    | IntegrationConnectPlaidLink
    | Unset = UNSET,
) -> Response[IntegrationConnection | ProblemDetails]:
    """Connect an integration (polymorphic by auth method)

     Finishes any auth method's connect flow and persists the connection under the target ecosystem
    `ecosystemId` the client names; the caller must manage it (404/403 otherwise). Returns the redacted
    connection (tokens never echoed).

    Args:
        body (IntegrationConnectApiKey | IntegrationConnectAppPassword |
            IntegrationConnectGithubApp | IntegrationConnectOAuth | IntegrationConnectOAuthInstance |
            IntegrationConnectPlaidLink | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[IntegrationConnection | ProblemDetails]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    body: IntegrationConnectApiKey
    | IntegrationConnectAppPassword
    | IntegrationConnectGithubApp
    | IntegrationConnectOAuth
    | IntegrationConnectOAuthInstance
    | IntegrationConnectPlaidLink
    | Unset = UNSET,
) -> IntegrationConnection | ProblemDetails | None:
    """Connect an integration (polymorphic by auth method)

     Finishes any auth method's connect flow and persists the connection under the target ecosystem
    `ecosystemId` the client names; the caller must manage it (404/403 otherwise). Returns the redacted
    connection (tokens never echoed).

    Args:
        body (IntegrationConnectApiKey | IntegrationConnectAppPassword |
            IntegrationConnectGithubApp | IntegrationConnectOAuth | IntegrationConnectOAuthInstance |
            IntegrationConnectPlaidLink | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        IntegrationConnection | ProblemDetails
    """

    return sync_detailed(
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    body: IntegrationConnectApiKey
    | IntegrationConnectAppPassword
    | IntegrationConnectGithubApp
    | IntegrationConnectOAuth
    | IntegrationConnectOAuthInstance
    | IntegrationConnectPlaidLink
    | Unset = UNSET,
) -> Response[IntegrationConnection | ProblemDetails]:
    """Connect an integration (polymorphic by auth method)

     Finishes any auth method's connect flow and persists the connection under the target ecosystem
    `ecosystemId` the client names; the caller must manage it (404/403 otherwise). Returns the redacted
    connection (tokens never echoed).

    Args:
        body (IntegrationConnectApiKey | IntegrationConnectAppPassword |
            IntegrationConnectGithubApp | IntegrationConnectOAuth | IntegrationConnectOAuthInstance |
            IntegrationConnectPlaidLink | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[IntegrationConnection | ProblemDetails]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    body: IntegrationConnectApiKey
    | IntegrationConnectAppPassword
    | IntegrationConnectGithubApp
    | IntegrationConnectOAuth
    | IntegrationConnectOAuthInstance
    | IntegrationConnectPlaidLink
    | Unset = UNSET,
) -> IntegrationConnection | ProblemDetails | None:
    """Connect an integration (polymorphic by auth method)

     Finishes any auth method's connect flow and persists the connection under the target ecosystem
    `ecosystemId` the client names; the caller must manage it (404/403 otherwise). Returns the redacted
    connection (tokens never echoed).

    Args:
        body (IntegrationConnectApiKey | IntegrationConnectAppPassword |
            IntegrationConnectGithubApp | IntegrationConnectOAuth | IntegrationConnectOAuthInstance |
            IntegrationConnectPlaidLink | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        IntegrationConnection | ProblemDetails
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
        )
    ).parsed
