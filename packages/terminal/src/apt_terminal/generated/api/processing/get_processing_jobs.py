from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.get_processing_jobs_response_200 import GetProcessingJobsResponse200
from ...models.get_processing_jobs_status import GetProcessingJobsStatus
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    status: GetProcessingJobsStatus | Unset = UNSET,
    limit: int | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    json_status: str | Unset = UNSET
    if not isinstance(status, Unset):
        json_status = status.value

    params["status"] = json_status

    params["limit"] = limit

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/processing/jobs",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | GetProcessingJobsResponse200 | None:
    if response.status_code == 200:
        response_200 = GetProcessingJobsResponse200.from_dict(response.json())

        return response_200

    if response.status_code == 400:
        response_400 = Error.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = Error.from_dict(response.json())

        return response_401

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | GetProcessingJobsResponse200]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    status: GetProcessingJobsStatus | Unset = UNSET,
    limit: int | Unset = UNSET,
) -> Response[Error | GetProcessingJobsResponse200]:
    """List ecosystem jobs (management)

     List the caller's ecosystem jobs, newest first. Requires a user JWT. Optional ?status= filter and
    ?limit= cap (default 50, max 200).

    Args:
        status (GetProcessingJobsStatus | Unset):
        limit (int | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GetProcessingJobsResponse200]
    """

    kwargs = _get_kwargs(
        status=status,
        limit=limit,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    status: GetProcessingJobsStatus | Unset = UNSET,
    limit: int | Unset = UNSET,
) -> Error | GetProcessingJobsResponse200 | None:
    """List ecosystem jobs (management)

     List the caller's ecosystem jobs, newest first. Requires a user JWT. Optional ?status= filter and
    ?limit= cap (default 50, max 200).

    Args:
        status (GetProcessingJobsStatus | Unset):
        limit (int | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GetProcessingJobsResponse200
    """

    return sync_detailed(
        client=client,
        status=status,
        limit=limit,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    status: GetProcessingJobsStatus | Unset = UNSET,
    limit: int | Unset = UNSET,
) -> Response[Error | GetProcessingJobsResponse200]:
    """List ecosystem jobs (management)

     List the caller's ecosystem jobs, newest first. Requires a user JWT. Optional ?status= filter and
    ?limit= cap (default 50, max 200).

    Args:
        status (GetProcessingJobsStatus | Unset):
        limit (int | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GetProcessingJobsResponse200]
    """

    kwargs = _get_kwargs(
        status=status,
        limit=limit,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    status: GetProcessingJobsStatus | Unset = UNSET,
    limit: int | Unset = UNSET,
) -> Error | GetProcessingJobsResponse200 | None:
    """List ecosystem jobs (management)

     List the caller's ecosystem jobs, newest first. Requires a user JWT. Optional ?status= filter and
    ?limit= cap (default 50, max 200).

    Args:
        status (GetProcessingJobsStatus | Unset):
        limit (int | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GetProcessingJobsResponse200
    """

    return (
        await asyncio_detailed(
            client=client,
            status=status,
            limit=limit,
        )
    ).parsed
