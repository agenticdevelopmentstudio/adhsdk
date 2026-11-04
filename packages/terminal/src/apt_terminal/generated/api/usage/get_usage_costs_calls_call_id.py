from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.usage_call_report import UsageCallReport
from ...types import Response


def _get_kwargs(
    call_id: str,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/usage/costs/calls/{call_id}".format(
            call_id=quote(str(call_id), safe=""),
        ),
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | UsageCallReport | None:
    if response.status_code == 200:
        response_200 = UsageCallReport.from_dict(response.json())

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
) -> Response[Error | UsageCallReport]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    call_id: str,
    *,
    client: AuthenticatedClient,
) -> Response[Error | UsageCallReport]:
    """One call's cost ledger and its child calls' (admin)

    Args:
        call_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | UsageCallReport]
    """

    kwargs = _get_kwargs(
        call_id=call_id,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    call_id: str,
    *,
    client: AuthenticatedClient,
) -> Error | UsageCallReport | None:
    """One call's cost ledger and its child calls' (admin)

    Args:
        call_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | UsageCallReport
    """

    return sync_detailed(
        call_id=call_id,
        client=client,
    ).parsed


async def asyncio_detailed(
    call_id: str,
    *,
    client: AuthenticatedClient,
) -> Response[Error | UsageCallReport]:
    """One call's cost ledger and its child calls' (admin)

    Args:
        call_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | UsageCallReport]
    """

    kwargs = _get_kwargs(
        call_id=call_id,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    call_id: str,
    *,
    client: AuthenticatedClient,
) -> Error | UsageCallReport | None:
    """One call's cost ledger and its child calls' (admin)

    Args:
        call_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | UsageCallReport
    """

    return (
        await asyncio_detailed(
            call_id=call_id,
            client=client,
        )
    ).parsed
