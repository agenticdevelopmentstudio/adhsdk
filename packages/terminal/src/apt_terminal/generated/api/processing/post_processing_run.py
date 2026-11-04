from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.post_processing_run_body import PostProcessingRunBody
from ...models.post_processing_run_response_202 import PostProcessingRunResponse202
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    body: PostProcessingRunBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/processing/run",
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | PostProcessingRunResponse202 | None:
    if response.status_code == 202:
        response_202 = PostProcessingRunResponse202.from_dict(response.json())

        return response_202

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
) -> Response[Error | PostProcessingRunResponse202]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    body: PostProcessingRunBody | Unset = UNSET,
) -> Response[Error | PostProcessingRunResponse202]:
    """Run an AI action on demand for a saved target

     Loads the saved target server-side and enqueues a high-priority (interactive) job. Idempotent per
    content version via the dedup key. Returns 202 with the job id.

    Args:
        body (PostProcessingRunBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PostProcessingRunResponse202]
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
    body: PostProcessingRunBody | Unset = UNSET,
) -> Error | PostProcessingRunResponse202 | None:
    """Run an AI action on demand for a saved target

     Loads the saved target server-side and enqueues a high-priority (interactive) job. Idempotent per
    content version via the dedup key. Returns 202 with the job id.

    Args:
        body (PostProcessingRunBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PostProcessingRunResponse202
    """

    return sync_detailed(
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    body: PostProcessingRunBody | Unset = UNSET,
) -> Response[Error | PostProcessingRunResponse202]:
    """Run an AI action on demand for a saved target

     Loads the saved target server-side and enqueues a high-priority (interactive) job. Idempotent per
    content version via the dedup key. Returns 202 with the job id.

    Args:
        body (PostProcessingRunBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PostProcessingRunResponse202]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    body: PostProcessingRunBody | Unset = UNSET,
) -> Error | PostProcessingRunResponse202 | None:
    """Run an AI action on demand for a saved target

     Loads the saved target server-side and enqueues a high-priority (interactive) job. Idempotent per
    content version via the dedup key. Returns 202 with the job id.

    Args:
        body (PostProcessingRunBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PostProcessingRunResponse202
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
        )
    ).parsed
