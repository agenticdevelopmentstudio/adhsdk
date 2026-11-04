from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.post_processing_nodes_register_body import PostProcessingNodesRegisterBody
from ...models.post_processing_nodes_register_response_200 import (
    PostProcessingNodesRegisterResponse200,
)
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    body: PostProcessingNodesRegisterBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/processing/nodes/register",
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | PostProcessingNodesRegisterResponse200 | None:
    if response.status_code == 200:
        response_200 = PostProcessingNodesRegisterResponse200.from_dict(response.json())

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
) -> Response[Error | PostProcessingNodesRegisterResponse200]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    body: PostProcessingNodesRegisterBody | Unset = UNSET,
) -> Response[Error | PostProcessingNodesRegisterResponse200]:
    """Register or refresh an AI node (worker)

     A node announces itself at start and every 60 s. Upserts the registry row keyed on the node's stable
    id. A `config` carrying a credential-looking key is refused (400): the registry holds no secret.

    Args:
        body (PostProcessingNodesRegisterBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PostProcessingNodesRegisterResponse200]
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
    body: PostProcessingNodesRegisterBody | Unset = UNSET,
) -> Error | PostProcessingNodesRegisterResponse200 | None:
    """Register or refresh an AI node (worker)

     A node announces itself at start and every 60 s. Upserts the registry row keyed on the node's stable
    id. A `config` carrying a credential-looking key is refused (400): the registry holds no secret.

    Args:
        body (PostProcessingNodesRegisterBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PostProcessingNodesRegisterResponse200
    """

    return sync_detailed(
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    body: PostProcessingNodesRegisterBody | Unset = UNSET,
) -> Response[Error | PostProcessingNodesRegisterResponse200]:
    """Register or refresh an AI node (worker)

     A node announces itself at start and every 60 s. Upserts the registry row keyed on the node's stable
    id. A `config` carrying a credential-looking key is refused (400): the registry holds no secret.

    Args:
        body (PostProcessingNodesRegisterBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PostProcessingNodesRegisterResponse200]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    body: PostProcessingNodesRegisterBody | Unset = UNSET,
) -> Error | PostProcessingNodesRegisterResponse200 | None:
    """Register or refresh an AI node (worker)

     A node announces itself at start and every 60 s. Upserts the registry row keyed on the node's stable
    id. A `config` carrying a credential-looking key is refused (400): the registry holds no secret.

    Args:
        body (PostProcessingNodesRegisterBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PostProcessingNodesRegisterResponse200
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
        )
    ).parsed
