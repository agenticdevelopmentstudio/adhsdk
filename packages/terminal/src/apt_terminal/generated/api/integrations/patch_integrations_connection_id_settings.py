from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.patch_integrations_connection_id_settings_body import (
    PatchIntegrationsConnectionIdSettingsBody,
)
from ...models.patch_integrations_connection_id_settings_response_200 import (
    PatchIntegrationsConnectionIdSettingsResponse200,
)
from ...models.problem_details import ProblemDetails
from ...types import UNSET, Response, Unset


def _get_kwargs(
    connection_id: str,
    *,
    body: PatchIntegrationsConnectionIdSettingsBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "patch",
        "url": "/integrations/{connection_id}/settings".format(
            connection_id=quote(str(connection_id), safe=""),
        ),
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PatchIntegrationsConnectionIdSettingsResponse200 | ProblemDetails | None:
    if response.status_code == 200:
        response_200 = PatchIntegrationsConnectionIdSettingsResponse200.from_dict(response.json())

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
) -> Response[PatchIntegrationsConnectionIdSettingsResponse200 | ProblemDetails]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    connection_id: str,
    *,
    client: AuthenticatedClient,
    body: PatchIntegrationsConnectionIdSettingsBody | Unset = UNSET,
) -> Response[PatchIntegrationsConnectionIdSettingsResponse200 | ProblemDetails]:
    """Update per-connection sync settings

     Ecosystem-authorized, validated write of the caller-tunable sync settings the sync worker reads
    (e.g. gmailLabelIds / gmailWindowDays / redditSubreddits / redditKeywords). The owning ecosystem is
    derived from the connection; the caller must manage it. 404 when absent/deleted; 403 when the caller
    cannot manage its ecosystem; 400 on an invalid body.

    Args:
        connection_id (str):
        body (PatchIntegrationsConnectionIdSettingsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PatchIntegrationsConnectionIdSettingsResponse200 | ProblemDetails]
    """

    kwargs = _get_kwargs(
        connection_id=connection_id,
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    connection_id: str,
    *,
    client: AuthenticatedClient,
    body: PatchIntegrationsConnectionIdSettingsBody | Unset = UNSET,
) -> PatchIntegrationsConnectionIdSettingsResponse200 | ProblemDetails | None:
    """Update per-connection sync settings

     Ecosystem-authorized, validated write of the caller-tunable sync settings the sync worker reads
    (e.g. gmailLabelIds / gmailWindowDays / redditSubreddits / redditKeywords). The owning ecosystem is
    derived from the connection; the caller must manage it. 404 when absent/deleted; 403 when the caller
    cannot manage its ecosystem; 400 on an invalid body.

    Args:
        connection_id (str):
        body (PatchIntegrationsConnectionIdSettingsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PatchIntegrationsConnectionIdSettingsResponse200 | ProblemDetails
    """

    return sync_detailed(
        connection_id=connection_id,
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    connection_id: str,
    *,
    client: AuthenticatedClient,
    body: PatchIntegrationsConnectionIdSettingsBody | Unset = UNSET,
) -> Response[PatchIntegrationsConnectionIdSettingsResponse200 | ProblemDetails]:
    """Update per-connection sync settings

     Ecosystem-authorized, validated write of the caller-tunable sync settings the sync worker reads
    (e.g. gmailLabelIds / gmailWindowDays / redditSubreddits / redditKeywords). The owning ecosystem is
    derived from the connection; the caller must manage it. 404 when absent/deleted; 403 when the caller
    cannot manage its ecosystem; 400 on an invalid body.

    Args:
        connection_id (str):
        body (PatchIntegrationsConnectionIdSettingsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PatchIntegrationsConnectionIdSettingsResponse200 | ProblemDetails]
    """

    kwargs = _get_kwargs(
        connection_id=connection_id,
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    connection_id: str,
    *,
    client: AuthenticatedClient,
    body: PatchIntegrationsConnectionIdSettingsBody | Unset = UNSET,
) -> PatchIntegrationsConnectionIdSettingsResponse200 | ProblemDetails | None:
    """Update per-connection sync settings

     Ecosystem-authorized, validated write of the caller-tunable sync settings the sync worker reads
    (e.g. gmailLabelIds / gmailWindowDays / redditSubreddits / redditKeywords). The owning ecosystem is
    derived from the connection; the caller must manage it. 404 when absent/deleted; 403 when the caller
    cannot manage its ecosystem; 400 on an invalid body.

    Args:
        connection_id (str):
        body (PatchIntegrationsConnectionIdSettingsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PatchIntegrationsConnectionIdSettingsResponse200 | ProblemDetails
    """

    return (
        await asyncio_detailed(
            connection_id=connection_id,
            client=client,
            body=body,
        )
    ).parsed
