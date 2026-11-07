from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.integration_picker_session_state import IntegrationPickerSessionState
from ...models.problem_details import ProblemDetails
from ...types import Response


def _get_kwargs(
    id: str,
    session_id: str,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/integrations/me/connections/{id}/google-photos/picker-sessions/{session_id}".format(
            id=quote(str(id), safe=""),
            session_id=quote(str(session_id), safe=""),
        ),
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> IntegrationPickerSessionState | ProblemDetails | None:
    if response.status_code == 200:
        response_200 = IntegrationPickerSessionState.from_dict(response.json())

        return response_200

    if response.status_code == 401:
        response_401 = ProblemDetails.from_dict(response.json())

        return response_401

    if response.status_code == 403:
        response_403 = ProblemDetails.from_dict(response.json())

        return response_403

    if response.status_code == 404:
        response_404 = ProblemDetails.from_dict(response.json())

        return response_404

    if response.status_code == 502:
        response_502 = ProblemDetails.from_dict(response.json())

        return response_502

    if response.status_code == 503:
        response_503 = ProblemDetails.from_dict(response.json())

        return response_503

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[IntegrationPickerSessionState | ProblemDetails]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    id: str,
    session_id: str,
    *,
    client: AuthenticatedClient,
) -> Response[IntegrationPickerSessionState | ProblemDetails]:
    """Check whether the user has finished picking

    Args:
        id (str):
        session_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[IntegrationPickerSessionState | ProblemDetails]
    """

    kwargs = _get_kwargs(
        id=id,
        session_id=session_id,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    session_id: str,
    *,
    client: AuthenticatedClient,
) -> IntegrationPickerSessionState | ProblemDetails | None:
    """Check whether the user has finished picking

    Args:
        id (str):
        session_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        IntegrationPickerSessionState | ProblemDetails
    """

    return sync_detailed(
        id=id,
        session_id=session_id,
        client=client,
    ).parsed


async def asyncio_detailed(
    id: str,
    session_id: str,
    *,
    client: AuthenticatedClient,
) -> Response[IntegrationPickerSessionState | ProblemDetails]:
    """Check whether the user has finished picking

    Args:
        id (str):
        session_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[IntegrationPickerSessionState | ProblemDetails]
    """

    kwargs = _get_kwargs(
        id=id,
        session_id=session_id,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    session_id: str,
    *,
    client: AuthenticatedClient,
) -> IntegrationPickerSessionState | ProblemDetails | None:
    """Check whether the user has finished picking

    Args:
        id (str):
        session_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        IntegrationPickerSessionState | ProblemDetails
    """

    return (
        await asyncio_detailed(
            id=id,
            session_id=session_id,
            client=client,
        )
    ).parsed
