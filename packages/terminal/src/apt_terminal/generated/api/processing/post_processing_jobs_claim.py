from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.post_processing_jobs_claim_body import PostProcessingJobsClaimBody
from ...models.post_processing_jobs_claim_response_200 import PostProcessingJobsClaimResponse200
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    body: PostProcessingJobsClaimBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/processing/jobs/claim",
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | PostProcessingJobsClaimResponse200 | None:
    if response.status_code == 200:
        response_200 = PostProcessingJobsClaimResponse200.from_dict(response.json())

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
) -> Response[Error | PostProcessingJobsClaimResponse200]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    body: PostProcessingJobsClaimBody | Unset = UNSET,
) -> Response[Error | PostProcessingJobsClaimResponse200]:
    """Claim queued jobs (worker pull)

     Atomically claim up to `batch` queued jobs for this worker. Returns an empty array when no jobs are
    available — never blocks. Ecosystem-scoped via RLS to the caller's api-token.

    Args:
        body (PostProcessingJobsClaimBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PostProcessingJobsClaimResponse200]
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
    body: PostProcessingJobsClaimBody | Unset = UNSET,
) -> Error | PostProcessingJobsClaimResponse200 | None:
    """Claim queued jobs (worker pull)

     Atomically claim up to `batch` queued jobs for this worker. Returns an empty array when no jobs are
    available — never blocks. Ecosystem-scoped via RLS to the caller's api-token.

    Args:
        body (PostProcessingJobsClaimBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PostProcessingJobsClaimResponse200
    """

    return sync_detailed(
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    body: PostProcessingJobsClaimBody | Unset = UNSET,
) -> Response[Error | PostProcessingJobsClaimResponse200]:
    """Claim queued jobs (worker pull)

     Atomically claim up to `batch` queued jobs for this worker. Returns an empty array when no jobs are
    available — never blocks. Ecosystem-scoped via RLS to the caller's api-token.

    Args:
        body (PostProcessingJobsClaimBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PostProcessingJobsClaimResponse200]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    body: PostProcessingJobsClaimBody | Unset = UNSET,
) -> Error | PostProcessingJobsClaimResponse200 | None:
    """Claim queued jobs (worker pull)

     Atomically claim up to `batch` queued jobs for this worker. Returns an empty array when no jobs are
    available — never blocks. Ecosystem-scoped via RLS to the caller's api-token.

    Args:
        body (PostProcessingJobsClaimBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PostProcessingJobsClaimResponse200
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
        )
    ).parsed
