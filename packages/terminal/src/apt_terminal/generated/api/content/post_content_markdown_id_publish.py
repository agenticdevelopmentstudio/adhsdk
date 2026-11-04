from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.markdown_document import MarkdownDocument
from ...models.post_content_markdown_id_publish_body import PostContentMarkdownIdPublishBody
from ...types import UNSET, Response, Unset


def _get_kwargs(
    id: str,
    *,
    body: PostContentMarkdownIdPublishBody | Unset = UNSET,
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
        "url": "/content/markdown/{id}/publish".format(
            id=quote(str(id), safe=""),
        ),
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
    if response.status_code == 200:
        response_200 = MarkdownDocument.from_dict(response.json())

        return response_200

    if response.status_code == 400:
        response_400 = Error.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = Error.from_dict(response.json())

        return response_401

    if response.status_code == 404:
        response_404 = Error.from_dict(response.json())

        return response_404

    if response.status_code == 409:
        response_409 = Error.from_dict(response.json())

        return response_409

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
    id: str,
    *,
    client: AuthenticatedClient,
    body: PostContentMarkdownIdPublishBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
    ecosystem_id: str | Unset = UNSET,
) -> Response[Error | MarkdownDocument]:
    """Publish a document under an author-defined public route slug

     Makes the document readable UNAUTHENTICATED at /public/users/{slug}/papers/{route}. The route is
    lowercase, url-safe, and UNIQUE PER AUTHOR — a collision with another of the caller’s live papers
    returns 409.

    Args:
        id (str):
        workspace (str | Unset):
        ecosystem_id (str | Unset):
        body (PostContentMarkdownIdPublishBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | MarkdownDocument]
    """

    kwargs = _get_kwargs(
        id=id,
        body=body,
        workspace=workspace,
        ecosystem_id=ecosystem_id,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    *,
    client: AuthenticatedClient,
    body: PostContentMarkdownIdPublishBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
    ecosystem_id: str | Unset = UNSET,
) -> Error | MarkdownDocument | None:
    """Publish a document under an author-defined public route slug

     Makes the document readable UNAUTHENTICATED at /public/users/{slug}/papers/{route}. The route is
    lowercase, url-safe, and UNIQUE PER AUTHOR — a collision with another of the caller’s live papers
    returns 409.

    Args:
        id (str):
        workspace (str | Unset):
        ecosystem_id (str | Unset):
        body (PostContentMarkdownIdPublishBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | MarkdownDocument
    """

    return sync_detailed(
        id=id,
        client=client,
        body=body,
        workspace=workspace,
        ecosystem_id=ecosystem_id,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
    body: PostContentMarkdownIdPublishBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
    ecosystem_id: str | Unset = UNSET,
) -> Response[Error | MarkdownDocument]:
    """Publish a document under an author-defined public route slug

     Makes the document readable UNAUTHENTICATED at /public/users/{slug}/papers/{route}. The route is
    lowercase, url-safe, and UNIQUE PER AUTHOR — a collision with another of the caller’s live papers
    returns 409.

    Args:
        id (str):
        workspace (str | Unset):
        ecosystem_id (str | Unset):
        body (PostContentMarkdownIdPublishBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | MarkdownDocument]
    """

    kwargs = _get_kwargs(
        id=id,
        body=body,
        workspace=workspace,
        ecosystem_id=ecosystem_id,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    *,
    client: AuthenticatedClient,
    body: PostContentMarkdownIdPublishBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
    ecosystem_id: str | Unset = UNSET,
) -> Error | MarkdownDocument | None:
    """Publish a document under an author-defined public route slug

     Makes the document readable UNAUTHENTICATED at /public/users/{slug}/papers/{route}. The route is
    lowercase, url-safe, and UNIQUE PER AUTHOR — a collision with another of the caller’s live papers
    returns 409.

    Args:
        id (str):
        workspace (str | Unset):
        ecosystem_id (str | Unset):
        body (PostContentMarkdownIdPublishBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | MarkdownDocument
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            body=body,
            workspace=workspace,
            ecosystem_id=ecosystem_id,
        )
    ).parsed
