from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.post_v1_papers_by_id_publish_body import PostV1PapersByIdPublishBody
from ...models.post_v1_papers_by_id_publish_response_200 import PostV1PapersByIdPublishResponse200
from ...models.stripe_error import StripeError
from ...types import Response


def _get_kwargs(
    id: str,
    *,
    body: PostV1PapersByIdPublishBody,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/papers/{id}/publish".format(
            id=quote(str(id), safe=""),
        ),
    }

    _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostV1PapersByIdPublishResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = PostV1PapersByIdPublishResponse200.from_dict(response.json())

        return response_200

    if response.status_code == 400:
        response_400 = StripeError.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = StripeError.from_dict(response.json())

        return response_401

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
) -> Response[PostV1PapersByIdPublishResponse200 | StripeError]:
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
    body: PostV1PapersByIdPublishBody,
) -> Response[PostV1PapersByIdPublishResponse200 | StripeError]:
    """Publish a document under an author-defined public route slug

     Makes the document readable UNAUTHENTICATED at /public/users/{slug}/papers/{route}. The route is
    lowercase, url-safe, and UNIQUE PER AUTHOR — a collision with another of the caller’s live papers
    returns 409.

    Replaces POST /content/markdown/{id}/publish.

    Args:
        id (str):
        body (PostV1PapersByIdPublishBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1PapersByIdPublishResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    *,
    client: AuthenticatedClient,
    body: PostV1PapersByIdPublishBody,
) -> PostV1PapersByIdPublishResponse200 | StripeError | None:
    """Publish a document under an author-defined public route slug

     Makes the document readable UNAUTHENTICATED at /public/users/{slug}/papers/{route}. The route is
    lowercase, url-safe, and UNIQUE PER AUTHOR — a collision with another of the caller’s live papers
    returns 409.

    Replaces POST /content/markdown/{id}/publish.

    Args:
        id (str):
        body (PostV1PapersByIdPublishBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1PapersByIdPublishResponse200 | StripeError
    """

    return sync_detailed(
        id=id,
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
    body: PostV1PapersByIdPublishBody,
) -> Response[PostV1PapersByIdPublishResponse200 | StripeError]:
    """Publish a document under an author-defined public route slug

     Makes the document readable UNAUTHENTICATED at /public/users/{slug}/papers/{route}. The route is
    lowercase, url-safe, and UNIQUE PER AUTHOR — a collision with another of the caller’s live papers
    returns 409.

    Replaces POST /content/markdown/{id}/publish.

    Args:
        id (str):
        body (PostV1PapersByIdPublishBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1PapersByIdPublishResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    *,
    client: AuthenticatedClient,
    body: PostV1PapersByIdPublishBody,
) -> PostV1PapersByIdPublishResponse200 | StripeError | None:
    """Publish a document under an author-defined public route slug

     Makes the document readable UNAUTHENTICATED at /public/users/{slug}/papers/{route}. The route is
    lowercase, url-safe, and UNIQUE PER AUTHOR — a collision with another of the caller’s live papers
    returns 409.

    Replaces POST /content/markdown/{id}/publish.

    Args:
        id (str):
        body (PostV1PapersByIdPublishBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1PapersByIdPublishResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            body=body,
        )
    ).parsed
