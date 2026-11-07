from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.patch_integrations_me_connections_id_settings_body import (
    PatchIntegrationsMeConnectionsIdSettingsBody,
)
from ...models.patch_integrations_me_connections_id_settings_response_200 import (
    PatchIntegrationsMeConnectionsIdSettingsResponse200,
)
from ...models.problem_details import ProblemDetails
from ...types import UNSET, Response, Unset


def _get_kwargs(
    id: str,
    *,
    body: PatchIntegrationsMeConnectionsIdSettingsBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "patch",
        "url": "/integrations/me/connections/{id}/settings".format(
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
) -> PatchIntegrationsMeConnectionsIdSettingsResponse200 | ProblemDetails | None:
    if response.status_code == 200:
        response_200 = PatchIntegrationsMeConnectionsIdSettingsResponse200.from_dict(
            response.json()
        )

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
) -> Response[PatchIntegrationsMeConnectionsIdSettingsResponse200 | ProblemDetails]:
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
    body: PatchIntegrationsMeConnectionsIdSettingsBody | Unset = UNSET,
) -> Response[PatchIntegrationsMeConnectionsIdSettingsResponse200 | ProblemDetails]:
    """Update sync settings on one of the caller's connections

     Same settings and validation as PATCH /integrations/{connectionId}/settings. 400 on an invalid body.

    Args:
        id (str):
        body (PatchIntegrationsMeConnectionsIdSettingsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PatchIntegrationsMeConnectionsIdSettingsResponse200 | ProblemDetails]
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
    body: PatchIntegrationsMeConnectionsIdSettingsBody | Unset = UNSET,
) -> PatchIntegrationsMeConnectionsIdSettingsResponse200 | ProblemDetails | None:
    """Update sync settings on one of the caller's connections

     Same settings and validation as PATCH /integrations/{connectionId}/settings. 400 on an invalid body.

    Args:
        id (str):
        body (PatchIntegrationsMeConnectionsIdSettingsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PatchIntegrationsMeConnectionsIdSettingsResponse200 | ProblemDetails
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
    body: PatchIntegrationsMeConnectionsIdSettingsBody | Unset = UNSET,
) -> Response[PatchIntegrationsMeConnectionsIdSettingsResponse200 | ProblemDetails]:
    """Update sync settings on one of the caller's connections

     Same settings and validation as PATCH /integrations/{connectionId}/settings. 400 on an invalid body.

    Args:
        id (str):
        body (PatchIntegrationsMeConnectionsIdSettingsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PatchIntegrationsMeConnectionsIdSettingsResponse200 | ProblemDetails]
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
    body: PatchIntegrationsMeConnectionsIdSettingsBody | Unset = UNSET,
) -> PatchIntegrationsMeConnectionsIdSettingsResponse200 | ProblemDetails | None:
    """Update sync settings on one of the caller's connections

     Same settings and validation as PATCH /integrations/{connectionId}/settings. 400 on an invalid body.

    Args:
        id (str):
        body (PatchIntegrationsMeConnectionsIdSettingsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PatchIntegrationsMeConnectionsIdSettingsResponse200 | ProblemDetails
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            body=body,
        )
    ).parsed
