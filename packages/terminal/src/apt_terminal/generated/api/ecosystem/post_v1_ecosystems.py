from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.post_v1_ecosystems_body import PostV1EcosystemsBody
from ...models.post_v1_ecosystems_response_201 import PostV1EcosystemsResponse201
from ...models.stripe_error import StripeError
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    body: PostV1EcosystemsBody,
    parent: str | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    params: dict[str, Any] = {}

    params["parent"] = parent

    params["workspace"] = workspace

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/ecosystems",
        "params": params,
    }

    _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostV1EcosystemsResponse201 | StripeError | None:
    if response.status_code == 201:
        response_201 = PostV1EcosystemsResponse201.from_dict(response.json())

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

    if response.status_code == 404:
        response_404 = StripeError.from_dict(response.json())

        return response_404

    if response.status_code == 409:
        response_409 = StripeError.from_dict(response.json())

        return response_409

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[PostV1EcosystemsResponse201 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    body: PostV1EcosystemsBody,
    parent: str | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> Response[PostV1EcosystemsResponse201 | StripeError]:
    """Create ecosystems

     Replaces POST /ecosystem/ecosystems.

    Args:
        parent (str | Unset):
        workspace (str | Unset):
        body (PostV1EcosystemsBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1EcosystemsResponse201 | StripeError]
    """

    kwargs = _get_kwargs(
        body=body,
        parent=parent,
        workspace=workspace,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    body: PostV1EcosystemsBody,
    parent: str | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> PostV1EcosystemsResponse201 | StripeError | None:
    """Create ecosystems

     Replaces POST /ecosystem/ecosystems.

    Args:
        parent (str | Unset):
        workspace (str | Unset):
        body (PostV1EcosystemsBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1EcosystemsResponse201 | StripeError
    """

    return sync_detailed(
        client=client,
        body=body,
        parent=parent,
        workspace=workspace,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    body: PostV1EcosystemsBody,
    parent: str | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> Response[PostV1EcosystemsResponse201 | StripeError]:
    """Create ecosystems

     Replaces POST /ecosystem/ecosystems.

    Args:
        parent (str | Unset):
        workspace (str | Unset):
        body (PostV1EcosystemsBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1EcosystemsResponse201 | StripeError]
    """

    kwargs = _get_kwargs(
        body=body,
        parent=parent,
        workspace=workspace,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    body: PostV1EcosystemsBody,
    parent: str | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> PostV1EcosystemsResponse201 | StripeError | None:
    """Create ecosystems

     Replaces POST /ecosystem/ecosystems.

    Args:
        parent (str | Unset):
        workspace (str | Unset):
        body (PostV1EcosystemsBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1EcosystemsResponse201 | StripeError
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
            parent=parent,
            workspace=workspace,
        )
    ).parsed
