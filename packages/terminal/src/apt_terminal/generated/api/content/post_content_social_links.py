from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.post_content_social_links_body import PostContentSocialLinksBody
from ...models.post_content_social_links_response_201 import PostContentSocialLinksResponse201
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    body: PostContentSocialLinksBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    params: dict[str, Any] = {}

    params["workspace"] = workspace

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/content/social-links",
        "params": params,
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | PostContentSocialLinksResponse201 | None:
    if response.status_code == 201:
        response_201 = PostContentSocialLinksResponse201.from_dict(response.json())

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

    if response.status_code == 404:
        response_404 = Error.from_dict(response.json())

        return response_404

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | PostContentSocialLinksResponse201]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    body: PostContentSocialLinksBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> Response[Error | PostContentSocialLinksResponse201]:
    """Create social_links

    Args:
        workspace (str | Unset):
        body (PostContentSocialLinksBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PostContentSocialLinksResponse201]
    """

    kwargs = _get_kwargs(
        body=body,
        workspace=workspace,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    body: PostContentSocialLinksBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> Error | PostContentSocialLinksResponse201 | None:
    """Create social_links

    Args:
        workspace (str | Unset):
        body (PostContentSocialLinksBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PostContentSocialLinksResponse201
    """

    return sync_detailed(
        client=client,
        body=body,
        workspace=workspace,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    body: PostContentSocialLinksBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> Response[Error | PostContentSocialLinksResponse201]:
    """Create social_links

    Args:
        workspace (str | Unset):
        body (PostContentSocialLinksBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PostContentSocialLinksResponse201]
    """

    kwargs = _get_kwargs(
        body=body,
        workspace=workspace,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    body: PostContentSocialLinksBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> Error | PostContentSocialLinksResponse201 | None:
    """Create social_links

    Args:
        workspace (str | Unset):
        body (PostContentSocialLinksBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PostContentSocialLinksResponse201
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
            workspace=workspace,
        )
    ).parsed
