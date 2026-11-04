from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.markdown_document import MarkdownDocument
from ...models.post_content_markdown_body import PostContentMarkdownBody
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    body: PostContentMarkdownBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
    ecosystem_id: str | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    params: dict[str, Any] = {}

    params["workspace"] = workspace

    params["ecosystemId"] = ecosystem_id

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/content/markdown",
        "params": params,
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | MarkdownDocument | None:
    if response.status_code == 201:
        response_201 = MarkdownDocument.from_dict(response.json())

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
) -> Response[Error | MarkdownDocument]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    body: PostContentMarkdownBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
    ecosystem_id: str | Unset = UNSET,
) -> Response[Error | MarkdownDocument]:
    """Create a markdown document (writes the head + version 1)

    Args:
        workspace (str | Unset):
        ecosystem_id (str | Unset):
        body (PostContentMarkdownBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | MarkdownDocument]
    """

    kwargs = _get_kwargs(
        body=body,
        workspace=workspace,
        ecosystem_id=ecosystem_id,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    body: PostContentMarkdownBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
    ecosystem_id: str | Unset = UNSET,
) -> Error | MarkdownDocument | None:
    """Create a markdown document (writes the head + version 1)

    Args:
        workspace (str | Unset):
        ecosystem_id (str | Unset):
        body (PostContentMarkdownBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | MarkdownDocument
    """

    return sync_detailed(
        client=client,
        body=body,
        workspace=workspace,
        ecosystem_id=ecosystem_id,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    body: PostContentMarkdownBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
    ecosystem_id: str | Unset = UNSET,
) -> Response[Error | MarkdownDocument]:
    """Create a markdown document (writes the head + version 1)

    Args:
        workspace (str | Unset):
        ecosystem_id (str | Unset):
        body (PostContentMarkdownBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | MarkdownDocument]
    """

    kwargs = _get_kwargs(
        body=body,
        workspace=workspace,
        ecosystem_id=ecosystem_id,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    body: PostContentMarkdownBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
    ecosystem_id: str | Unset = UNSET,
) -> Error | MarkdownDocument | None:
    """Create a markdown document (writes the head + version 1)

    Args:
        workspace (str | Unset):
        ecosystem_id (str | Unset):
        body (PostContentMarkdownBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | MarkdownDocument
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
            workspace=workspace,
            ecosystem_id=ecosystem_id,
        )
    ).parsed
