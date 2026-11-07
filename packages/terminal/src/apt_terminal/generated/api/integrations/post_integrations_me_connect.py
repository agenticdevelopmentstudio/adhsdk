from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.integration_connection import IntegrationConnection
from ...models.integration_me_connect_request import IntegrationMeConnectRequest
from ...models.problem_details import ProblemDetails
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    body: IntegrationMeConnectRequest | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/integrations/me/connect",
    }

    if not isinstance(body, Unset):
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

    if response.status_code == 503:
        response_503 = ProblemDetails.from_dict(response.json())

        return response_503

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
    body: IntegrationMeConnectRequest | Unset = UNSET,
) -> Response[IntegrationConnection | ProblemDetails]:
    """Connect an integration (end user)

     Finishes the connect flow for the caller. Returns the redacted connection. 404 when the provider is
    not connectable in the caller's ecosystem. `serviceType` must be one the provider offers (400
    otherwise).

    Args:
        body (IntegrationMeConnectRequest | Unset): Same variants as IntegrationConnectRequest
            (matched on `type`), minus `ecosystemId`. `providerConfigId` is refused with 400.

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
    body: IntegrationMeConnectRequest | Unset = UNSET,
) -> IntegrationConnection | ProblemDetails | None:
    """Connect an integration (end user)

     Finishes the connect flow for the caller. Returns the redacted connection. 404 when the provider is
    not connectable in the caller's ecosystem. `serviceType` must be one the provider offers (400
    otherwise).

    Args:
        body (IntegrationMeConnectRequest | Unset): Same variants as IntegrationConnectRequest
            (matched on `type`), minus `ecosystemId`. `providerConfigId` is refused with 400.

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
    body: IntegrationMeConnectRequest | Unset = UNSET,
) -> Response[IntegrationConnection | ProblemDetails]:
    """Connect an integration (end user)

     Finishes the connect flow for the caller. Returns the redacted connection. 404 when the provider is
    not connectable in the caller's ecosystem. `serviceType` must be one the provider offers (400
    otherwise).

    Args:
        body (IntegrationMeConnectRequest | Unset): Same variants as IntegrationConnectRequest
            (matched on `type`), minus `ecosystemId`. `providerConfigId` is refused with 400.

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
    body: IntegrationMeConnectRequest | Unset = UNSET,
) -> IntegrationConnection | ProblemDetails | None:
    """Connect an integration (end user)

     Finishes the connect flow for the caller. Returns the redacted connection. 404 when the provider is
    not connectable in the caller's ecosystem. `serviceType` must be one the provider offers (400
    otherwise).

    Args:
        body (IntegrationMeConnectRequest | Unset): Same variants as IntegrationConnectRequest
            (matched on `type`), minus `ecosystemId`. `providerConfigId` is refused with 400.

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
