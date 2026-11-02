from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.markdown_tag_set import MarkdownTagSet
from ...types import Response


def _get_kwargs() -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/content/markdown/tags",
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | MarkdownTagSet | None:
    if response.status_code == 200:
        response_200 = MarkdownTagSet.from_dict(response.json())

        return response_200

    if response.status_code == 401:
        response_401 = Error.from_dict(response.json())

        return response_401

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | MarkdownTagSet]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
) -> Response[Error | MarkdownTagSet]:
    """List the caller's existing tag labels (autocomplete source)

     The account's full set of tag labels (content.keywords), scoped to the caller and ecosystem,
    distinct and alphabetical — the autocomplete/browse source for the research tag field. `nodes` is
    the same set with each label's row id, which is what addresses a tag for a rename or delete.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | MarkdownTagSet]
    """

    kwargs = _get_kwargs()

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
) -> Error | MarkdownTagSet | None:
    """List the caller's existing tag labels (autocomplete source)

     The account's full set of tag labels (content.keywords), scoped to the caller and ecosystem,
    distinct and alphabetical — the autocomplete/browse source for the research tag field. `nodes` is
    the same set with each label's row id, which is what addresses a tag for a rename or delete.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | MarkdownTagSet
    """

    return sync_detailed(
        client=client,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
) -> Response[Error | MarkdownTagSet]:
    """List the caller's existing tag labels (autocomplete source)

     The account's full set of tag labels (content.keywords), scoped to the caller and ecosystem,
    distinct and alphabetical — the autocomplete/browse source for the research tag field. `nodes` is
    the same set with each label's row id, which is what addresses a tag for a rename or delete.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | MarkdownTagSet]
    """

    kwargs = _get_kwargs()

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
) -> Error | MarkdownTagSet | None:
    """List the caller's existing tag labels (autocomplete source)

     The account's full set of tag labels (content.keywords), scoped to the caller and ecosystem,
    distinct and alphabetical — the autocomplete/browse source for the research tag field. `nodes` is
    the same set with each label's row id, which is what addresses a tag for a rename or delete.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | MarkdownTagSet
    """

    return (
        await asyncio_detailed(
            client=client,
        )
    ).parsed
