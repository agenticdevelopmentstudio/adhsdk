from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.ai_processing_log_level import AiProcessingLogLevel
from ...models.ai_processing_node_log_page import AiProcessingNodeLogPage
from ...models.error import Error
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    level: AiProcessingLogLevel | Unset = UNSET,
    job_id: str | Unset = UNSET,
    before: int | Unset = UNSET,
    limit: int | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    json_level: str | Unset = UNSET
    if not isinstance(level, Unset):
        json_level = level.value

    params["level"] = json_level

    params["jobId"] = job_id

    params["before"] = before

    params["limit"] = limit

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/processing/admin/logs",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> AiProcessingNodeLogPage | Error | None:
    if response.status_code == 200:
        response_200 = AiProcessingNodeLogPage.from_dict(response.json())

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

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[AiProcessingNodeLogPage | Error]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    level: AiProcessingLogLevel | Unset = UNSET,
    job_id: str | Unset = UNSET,
    before: int | Unset = UNSET,
    limit: int | Unset = UNSET,
) -> Response[AiProcessingNodeLogPage | Error]:
    """List logs across all nodes, newest first (admin)

    Args:
        level (AiProcessingLogLevel | Unset):
        job_id (str | Unset):
        before (int | Unset):
        limit (int | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[AiProcessingNodeLogPage | Error]
    """

    kwargs = _get_kwargs(
        level=level,
        job_id=job_id,
        before=before,
        limit=limit,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    level: AiProcessingLogLevel | Unset = UNSET,
    job_id: str | Unset = UNSET,
    before: int | Unset = UNSET,
    limit: int | Unset = UNSET,
) -> AiProcessingNodeLogPage | Error | None:
    """List logs across all nodes, newest first (admin)

    Args:
        level (AiProcessingLogLevel | Unset):
        job_id (str | Unset):
        before (int | Unset):
        limit (int | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        AiProcessingNodeLogPage | Error
    """

    return sync_detailed(
        client=client,
        level=level,
        job_id=job_id,
        before=before,
        limit=limit,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    level: AiProcessingLogLevel | Unset = UNSET,
    job_id: str | Unset = UNSET,
    before: int | Unset = UNSET,
    limit: int | Unset = UNSET,
) -> Response[AiProcessingNodeLogPage | Error]:
    """List logs across all nodes, newest first (admin)

    Args:
        level (AiProcessingLogLevel | Unset):
        job_id (str | Unset):
        before (int | Unset):
        limit (int | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[AiProcessingNodeLogPage | Error]
    """

    kwargs = _get_kwargs(
        level=level,
        job_id=job_id,
        before=before,
        limit=limit,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    level: AiProcessingLogLevel | Unset = UNSET,
    job_id: str | Unset = UNSET,
    before: int | Unset = UNSET,
    limit: int | Unset = UNSET,
) -> AiProcessingNodeLogPage | Error | None:
    """List logs across all nodes, newest first (admin)

    Args:
        level (AiProcessingLogLevel | Unset):
        job_id (str | Unset):
        before (int | Unset):
        limit (int | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        AiProcessingNodeLogPage | Error
    """

    return (
        await asyncio_detailed(
            client=client,
            level=level,
            job_id=job_id,
            before=before,
            limit=limit,
        )
    ).parsed
