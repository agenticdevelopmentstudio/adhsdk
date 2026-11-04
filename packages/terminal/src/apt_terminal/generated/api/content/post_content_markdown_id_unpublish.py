from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.markdown_document import MarkdownDocument
from ...types import UNSET, Response, Unset


def _get_kwargs(
    id: str,
    *,
    workspace: str | Unset = UNSET,
    ecosystem_id: str | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["workspace"] = workspace

    params["ecosystemId"] = ecosystem_id

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/content/markdown/{id}/unpublish".format(
            id=quote(str(id), safe=""),
        ),
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | MarkdownDocument | None:
    if response.status_code == 200:
        response_200 = MarkdownDocument.from_dict(response.json())

        return response_200

    if response.status_code == 401:
        response_401 = Error.from_dict(response.json())

        return response_401

    if response.status_code == 404:
        response_404 = Error.from_dict(response.json())

        return response_404

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
    workspace: str | Unset = UNSET,
    ecosystem_id: str | Unset = UNSET,
) -> Response[Error | MarkdownDocument]:
    """Unpublish a document (revert to a private draft, freeing its route)

    Args:
        id (str):
        workspace (str | Unset):
        ecosystem_id (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | MarkdownDocument]
    """

    kwargs = _get_kwargs(
        id=id,
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
    workspace: str | Unset = UNSET,
    ecosystem_id: str | Unset = UNSET,
) -> Error | MarkdownDocument | None:
    """Unpublish a document (revert to a private draft, freeing its route)

    Args:
        id (str):
        workspace (str | Unset):
        ecosystem_id (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | MarkdownDocument
    """

    return sync_detailed(
        id=id,
        client=client,
        workspace=workspace,
        ecosystem_id=ecosystem_id,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
    workspace: str | Unset = UNSET,
    ecosystem_id: str | Unset = UNSET,
) -> Response[Error | MarkdownDocument]:
    """Unpublish a document (revert to a private draft, freeing its route)

    Args:
        id (str):
        workspace (str | Unset):
        ecosystem_id (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | MarkdownDocument]
    """

    kwargs = _get_kwargs(
        id=id,
        workspace=workspace,
        ecosystem_id=ecosystem_id,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    *,
    client: AuthenticatedClient,
    workspace: str | Unset = UNSET,
    ecosystem_id: str | Unset = UNSET,
) -> Error | MarkdownDocument | None:
    """Unpublish a document (revert to a private draft, freeing its route)

    Args:
        id (str):
        workspace (str | Unset):
        ecosystem_id (str | Unset):

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
            workspace=workspace,
            ecosystem_id=ecosystem_id,
        )
    ).parsed
