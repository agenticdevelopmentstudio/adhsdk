from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.post_v1_processing_nodes_body import PostV1ProcessingNodesBody
from ...models.post_v1_processing_nodes_response_200 import PostV1ProcessingNodesResponse200
from ...models.stripe_error import StripeError
from ...types import Response


def _get_kwargs(
    *,
    body: PostV1ProcessingNodesBody,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/processing/nodes",
    }

    _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostV1ProcessingNodesResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = PostV1ProcessingNodesResponse200.from_dict(response.json())

        return response_200

    if response.status_code == 400:
        response_400 = StripeError.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = StripeError.from_dict(response.json())

        return response_401

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[PostV1ProcessingNodesResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    body: PostV1ProcessingNodesBody,
) -> Response[PostV1ProcessingNodesResponse200 | StripeError]:
    """Register or refresh an AI node (worker)

     A node announces itself at start and every 60 s. Upserts the registry row keyed on the node's stable
    id. A `config` carrying a credential-looking key is refused (400): the registry holds no secret.

    Replaces POST /processing/nodes/register.

    Args:
        body (PostV1ProcessingNodesBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1ProcessingNodesResponse200 | StripeError]
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
    body: PostV1ProcessingNodesBody,
) -> PostV1ProcessingNodesResponse200 | StripeError | None:
    """Register or refresh an AI node (worker)

     A node announces itself at start and every 60 s. Upserts the registry row keyed on the node's stable
    id. A `config` carrying a credential-looking key is refused (400): the registry holds no secret.

    Replaces POST /processing/nodes/register.

    Args:
        body (PostV1ProcessingNodesBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1ProcessingNodesResponse200 | StripeError
    """

    return sync_detailed(
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    body: PostV1ProcessingNodesBody,
) -> Response[PostV1ProcessingNodesResponse200 | StripeError]:
    """Register or refresh an AI node (worker)

     A node announces itself at start and every 60 s. Upserts the registry row keyed on the node's stable
    id. A `config` carrying a credential-looking key is refused (400): the registry holds no secret.

    Replaces POST /processing/nodes/register.

    Args:
        body (PostV1ProcessingNodesBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1ProcessingNodesResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    body: PostV1ProcessingNodesBody,
) -> PostV1ProcessingNodesResponse200 | StripeError | None:
    """Register or refresh an AI node (worker)

     A node announces itself at start and every 60 s. Upserts the registry row keyed on the node's stable
    id. A `config` carrying a credential-looking key is refused (400): the registry holds no secret.

    Replaces POST /processing/nodes/register.

    Args:
        body (PostV1ProcessingNodesBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1ProcessingNodesResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
        )
    ).parsed
