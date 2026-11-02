from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.get_integrations_ecosystems_ecosystem_id_provider_configs_response_200 import (
    GetIntegrationsEcosystemsEcosystemIdProviderConfigsResponse200,
)
from ...models.problem_details import ProblemDetails
from ...types import Response


def _get_kwargs(
    ecosystem_id: str,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/integrations/ecosystems/{ecosystem_id}/provider-configs".format(
            ecosystem_id=quote(str(ecosystem_id), safe=""),
        ),
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> GetIntegrationsEcosystemsEcosystemIdProviderConfigsResponse200 | ProblemDetails | None:
    if response.status_code == 200:
        response_200 = GetIntegrationsEcosystemsEcosystemIdProviderConfigsResponse200.from_dict(
            response.json()
        )

        return response_200

    if response.status_code == 401:
        response_401 = ProblemDetails.from_dict(response.json())

        return response_401

    if response.status_code == 403:
        response_403 = ProblemDetails.from_dict(response.json())

        return response_403

    if response.status_code == 503:
        response_503 = ProblemDetails.from_dict(response.json())

        return response_503

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[GetIntegrationsEcosystemsEcosystemIdProviderConfigsResponse200 | ProblemDetails]:
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
) -> Response[GetIntegrationsEcosystemsEcosystemIdProviderConfigsResponse200 | ProblemDetails]:
    """List an ecosystem's provider configs (secrets masked)

     Every stored provider config for the ecosystem, secrets masked to `hasSecret` (each carries its
    `name` + `rdid`). The ecosystemId must be the caller's own ecosystem (403 otherwise).

    Args:
        ecosystem_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetIntegrationsEcosystemsEcosystemIdProviderConfigsResponse200 | ProblemDetails]
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
) -> GetIntegrationsEcosystemsEcosystemIdProviderConfigsResponse200 | ProblemDetails | None:
    """List an ecosystem's provider configs (secrets masked)

     Every stored provider config for the ecosystem, secrets masked to `hasSecret` (each carries its
    `name` + `rdid`). The ecosystemId must be the caller's own ecosystem (403 otherwise).

    Args:
        ecosystem_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetIntegrationsEcosystemsEcosystemIdProviderConfigsResponse200 | ProblemDetails
    """

    return sync_detailed(
        ecosystem_id=ecosystem_id,
        client=client,
    ).parsed


async def asyncio_detailed(
    ecosystem_id: str,
    *,
    client: AuthenticatedClient,
) -> Response[GetIntegrationsEcosystemsEcosystemIdProviderConfigsResponse200 | ProblemDetails]:
    """List an ecosystem's provider configs (secrets masked)

     Every stored provider config for the ecosystem, secrets masked to `hasSecret` (each carries its
    `name` + `rdid`). The ecosystemId must be the caller's own ecosystem (403 otherwise).

    Args:
        ecosystem_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetIntegrationsEcosystemsEcosystemIdProviderConfigsResponse200 | ProblemDetails]
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
) -> GetIntegrationsEcosystemsEcosystemIdProviderConfigsResponse200 | ProblemDetails | None:
    """List an ecosystem's provider configs (secrets masked)

     Every stored provider config for the ecosystem, secrets masked to `hasSecret` (each carries its
    `name` + `rdid`). The ecosystemId must be the caller's own ecosystem (403 otherwise).

    Args:
        ecosystem_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetIntegrationsEcosystemsEcosystemIdProviderConfigsResponse200 | ProblemDetails
    """

    return (
        await asyncio_detailed(
            ecosystem_id=ecosystem_id,
            client=client,
        )
    ).parsed
