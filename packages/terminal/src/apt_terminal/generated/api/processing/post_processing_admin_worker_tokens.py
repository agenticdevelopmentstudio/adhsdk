from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.ai_processing_worker_token_input import AiProcessingWorkerTokenInput
from ...models.error import Error
from ...models.post_processing_admin_worker_tokens_response_201 import (
    PostProcessingAdminWorkerTokensResponse201,
)
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    body: AiProcessingWorkerTokenInput | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/processing/admin/worker-tokens",
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | PostProcessingAdminWorkerTokensResponse201 | None:
    if response.status_code == 201:
        response_201 = PostProcessingAdminWorkerTokensResponse201.from_dict(response.json())

        return response_201

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
) -> Response[Error | PostProcessingAdminWorkerTokensResponse201]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    body: AiProcessingWorkerTokenInput | Unset = UNSET,
) -> Response[Error | PostProcessingAdminWorkerTokensResponse201]:
    """Mint an AI node worker token (admin)

     A token scoped ai-processing:worker, for a node to set as AI_NODE_API_TOKEN. The raw value is in
    `token` and is returned only here.

    Args:
        body (AiProcessingWorkerTokenInput | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PostProcessingAdminWorkerTokensResponse201]
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
    body: AiProcessingWorkerTokenInput | Unset = UNSET,
) -> Error | PostProcessingAdminWorkerTokensResponse201 | None:
    """Mint an AI node worker token (admin)

     A token scoped ai-processing:worker, for a node to set as AI_NODE_API_TOKEN. The raw value is in
    `token` and is returned only here.

    Args:
        body (AiProcessingWorkerTokenInput | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PostProcessingAdminWorkerTokensResponse201
    """

    return sync_detailed(
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    body: AiProcessingWorkerTokenInput | Unset = UNSET,
) -> Response[Error | PostProcessingAdminWorkerTokensResponse201]:
    """Mint an AI node worker token (admin)

     A token scoped ai-processing:worker, for a node to set as AI_NODE_API_TOKEN. The raw value is in
    `token` and is returned only here.

    Args:
        body (AiProcessingWorkerTokenInput | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PostProcessingAdminWorkerTokensResponse201]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    body: AiProcessingWorkerTokenInput | Unset = UNSET,
) -> Error | PostProcessingAdminWorkerTokensResponse201 | None:
    """Mint an AI node worker token (admin)

     A token scoped ai-processing:worker, for a node to set as AI_NODE_API_TOKEN. The raw value is in
    `token` and is returned only here.

    Args:
        body (AiProcessingWorkerTokenInput | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PostProcessingAdminWorkerTokensResponse201
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
        )
    ).parsed
