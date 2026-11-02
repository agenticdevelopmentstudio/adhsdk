from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.post_ecosystem_ecosystem_regions_body import PostEcosystemEcosystemRegionsBody
from ...models.post_ecosystem_ecosystem_regions_response_201 import (
    PostEcosystemEcosystemRegionsResponse201,
)
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    body: PostEcosystemEcosystemRegionsBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/ecosystem/ecosystem-regions",
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | PostEcosystemEcosystemRegionsResponse201 | None:
    if response.status_code == 201:
        response_201 = PostEcosystemEcosystemRegionsResponse201.from_dict(response.json())

        return response_201

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
) -> Response[Error | PostEcosystemEcosystemRegionsResponse201]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    body: PostEcosystemEcosystemRegionsBody | Unset = UNSET,
) -> Response[Error | PostEcosystemEcosystemRegionsResponse201]:
    """Create ecosystem_regions

    Args:
        body (PostEcosystemEcosystemRegionsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PostEcosystemEcosystemRegionsResponse201]
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
    body: PostEcosystemEcosystemRegionsBody | Unset = UNSET,
) -> Error | PostEcosystemEcosystemRegionsResponse201 | None:
    """Create ecosystem_regions

    Args:
        body (PostEcosystemEcosystemRegionsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PostEcosystemEcosystemRegionsResponse201
    """

    return sync_detailed(
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    body: PostEcosystemEcosystemRegionsBody | Unset = UNSET,
) -> Response[Error | PostEcosystemEcosystemRegionsResponse201]:
    """Create ecosystem_regions

    Args:
        body (PostEcosystemEcosystemRegionsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PostEcosystemEcosystemRegionsResponse201]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    body: PostEcosystemEcosystemRegionsBody | Unset = UNSET,
) -> Error | PostEcosystemEcosystemRegionsResponse201 | None:
    """Create ecosystem_regions

    Args:
        body (PostEcosystemEcosystemRegionsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PostEcosystemEcosystemRegionsResponse201
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
        )
    ).parsed
