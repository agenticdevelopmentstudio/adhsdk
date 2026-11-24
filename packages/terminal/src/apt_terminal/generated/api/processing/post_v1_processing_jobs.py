from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.post_v1_processing_jobs_body import PostV1ProcessingJobsBody
from ...models.post_v1_processing_jobs_response_201 import PostV1ProcessingJobsResponse201
from ...models.stripe_error import StripeError
from ...types import Response


def _get_kwargs(
    *,
    body: PostV1ProcessingJobsBody,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/processing/jobs",
    }

    _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostV1ProcessingJobsResponse201 | StripeError | None:
    if response.status_code == 201:
        response_201 = PostV1ProcessingJobsResponse201.from_dict(response.json())

        return response_201

    if response.status_code == 400:
        response_400 = StripeError.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = StripeError.from_dict(response.json())

        return response_401

    if response.status_code == 403:
        response_403 = StripeError.from_dict(response.json())

        return response_403

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[PostV1ProcessingJobsResponse201 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    body: PostV1ProcessingJobsBody,
) -> Response[PostV1ProcessingJobsResponse201 | StripeError]:
    """Enqueue an ad-hoc job (management)

     Ad-hoc / explicit enqueue path (task family 3). Requires a user JWT. The caller's ecosystemId
    becomes the owning ecosystem. Returns { id, deduped }.

    Replaces POST /processing/jobs.

    Args:
        body (PostV1ProcessingJobsBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1ProcessingJobsResponse201 | StripeError]
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
    body: PostV1ProcessingJobsBody,
) -> PostV1ProcessingJobsResponse201 | StripeError | None:
    """Enqueue an ad-hoc job (management)

     Ad-hoc / explicit enqueue path (task family 3). Requires a user JWT. The caller's ecosystemId
    becomes the owning ecosystem. Returns { id, deduped }.

    Replaces POST /processing/jobs.

    Args:
        body (PostV1ProcessingJobsBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1ProcessingJobsResponse201 | StripeError
    """

    return sync_detailed(
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    body: PostV1ProcessingJobsBody,
) -> Response[PostV1ProcessingJobsResponse201 | StripeError]:
    """Enqueue an ad-hoc job (management)

     Ad-hoc / explicit enqueue path (task family 3). Requires a user JWT. The caller's ecosystemId
    becomes the owning ecosystem. Returns { id, deduped }.

    Replaces POST /processing/jobs.

    Args:
        body (PostV1ProcessingJobsBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1ProcessingJobsResponse201 | StripeError]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    body: PostV1ProcessingJobsBody,
) -> PostV1ProcessingJobsResponse201 | StripeError | None:
    """Enqueue an ad-hoc job (management)

     Ad-hoc / explicit enqueue path (task family 3). Requires a user JWT. The caller's ecosystemId
    becomes the owning ecosystem. Returns { id, deduped }.

    Replaces POST /processing/jobs.

    Args:
        body (PostV1ProcessingJobsBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1ProcessingJobsResponse201 | StripeError
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
        )
    ).parsed
