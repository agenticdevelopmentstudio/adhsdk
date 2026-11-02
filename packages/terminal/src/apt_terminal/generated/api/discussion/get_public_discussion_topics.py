from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.get_public_discussion_topics_response_200 import GetPublicDiscussionTopicsResponse200
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["page"] = page

    params["pageSize"] = page_size

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/public/discussion/topics",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> GetPublicDiscussionTopicsResponse200 | None:
    if response.status_code == 200:
        response_200 = GetPublicDiscussionTopicsResponse200.from_dict(response.json())

        return response_200

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[GetPublicDiscussionTopicsResponse200]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient | Client,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
) -> Response[GetPublicDiscussionTopicsResponse200]:
    """List the hub’s live PUBLIC topics (anonymous; author id omitted)

    Args:
        page (str | Unset):
        page_size (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetPublicDiscussionTopicsResponse200]
    """

    kwargs = _get_kwargs(
        page=page,
        page_size=page_size,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient | Client,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
) -> GetPublicDiscussionTopicsResponse200 | None:
    """List the hub’s live PUBLIC topics (anonymous; author id omitted)

    Args:
        page (str | Unset):
        page_size (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetPublicDiscussionTopicsResponse200
    """

    return sync_detailed(
        client=client,
        page=page,
        page_size=page_size,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient | Client,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
) -> Response[GetPublicDiscussionTopicsResponse200]:
    """List the hub’s live PUBLIC topics (anonymous; author id omitted)

    Args:
        page (str | Unset):
        page_size (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetPublicDiscussionTopicsResponse200]
    """

    kwargs = _get_kwargs(
        page=page,
        page_size=page_size,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient | Client,
    page: str | Unset = UNSET,
    page_size: str | Unset = UNSET,
) -> GetPublicDiscussionTopicsResponse200 | None:
    """List the hub’s live PUBLIC topics (anonymous; author id omitted)

    Args:
        page (str | Unset):
        page_size (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetPublicDiscussionTopicsResponse200
    """

    return (
        await asyncio_detailed(
            client=client,
            page=page,
            page_size=page_size,
        )
    ).parsed
