from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.post_project_templates_id_work_items_body import PostProjectTemplatesIdWorkItemsBody
from ...models.post_project_templates_id_work_items_response_201 import (
    PostProjectTemplatesIdWorkItemsResponse201,
)
from ...types import UNSET, Response, Unset


def _get_kwargs(
    id: str,
    *,
    body: PostProjectTemplatesIdWorkItemsBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/project/templates/{id}/work-items".format(
            id=quote(str(id), safe=""),
        ),
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | PostProjectTemplatesIdWorkItemsResponse201 | None:
    if response.status_code == 201:
        response_201 = PostProjectTemplatesIdWorkItemsResponse201.from_dict(response.json())

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
) -> Response[Error | PostProjectTemplatesIdWorkItemsResponse201]:
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
    body: PostProjectTemplatesIdWorkItemsBody | Unset = UNSET,
) -> Response[Error | PostProjectTemplatesIdWorkItemsResponse201]:
    """Build a card (and its sub-tasks) from a work_item template

     The template supplies the WORDS; the request supplies the PLACE. Each card written is an ordinary
    create — same row, same labels, same `work_item.created` activity, same assignment notification —
    and one extra `work_item.instantiated` row on the parent names the template, once, rather than under
    every child. The children inherit the parent’s column, plan point and cycle: a checklist’s steps
    belong to the same delivery as the thing they are steps of. Requires projects C (subitem) on the
    TARGET board; 400 if the template’s kind is `project`.

    Args:
        id (str):
        body (PostProjectTemplatesIdWorkItemsBody | Unset): Where the card LANDS — the board-local
            half a template body deliberately does not carry.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PostProjectTemplatesIdWorkItemsResponse201]
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
    body: PostProjectTemplatesIdWorkItemsBody | Unset = UNSET,
) -> Error | PostProjectTemplatesIdWorkItemsResponse201 | None:
    """Build a card (and its sub-tasks) from a work_item template

     The template supplies the WORDS; the request supplies the PLACE. Each card written is an ordinary
    create — same row, same labels, same `work_item.created` activity, same assignment notification —
    and one extra `work_item.instantiated` row on the parent names the template, once, rather than under
    every child. The children inherit the parent’s column, plan point and cycle: a checklist’s steps
    belong to the same delivery as the thing they are steps of. Requires projects C (subitem) on the
    TARGET board; 400 if the template’s kind is `project`.

    Args:
        id (str):
        body (PostProjectTemplatesIdWorkItemsBody | Unset): Where the card LANDS — the board-local
            half a template body deliberately does not carry.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PostProjectTemplatesIdWorkItemsResponse201
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
    body: PostProjectTemplatesIdWorkItemsBody | Unset = UNSET,
) -> Response[Error | PostProjectTemplatesIdWorkItemsResponse201]:
    """Build a card (and its sub-tasks) from a work_item template

     The template supplies the WORDS; the request supplies the PLACE. Each card written is an ordinary
    create — same row, same labels, same `work_item.created` activity, same assignment notification —
    and one extra `work_item.instantiated` row on the parent names the template, once, rather than under
    every child. The children inherit the parent’s column, plan point and cycle: a checklist’s steps
    belong to the same delivery as the thing they are steps of. Requires projects C (subitem) on the
    TARGET board; 400 if the template’s kind is `project`.

    Args:
        id (str):
        body (PostProjectTemplatesIdWorkItemsBody | Unset): Where the card LANDS — the board-local
            half a template body deliberately does not carry.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PostProjectTemplatesIdWorkItemsResponse201]
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
    body: PostProjectTemplatesIdWorkItemsBody | Unset = UNSET,
) -> Error | PostProjectTemplatesIdWorkItemsResponse201 | None:
    """Build a card (and its sub-tasks) from a work_item template

     The template supplies the WORDS; the request supplies the PLACE. Each card written is an ordinary
    create — same row, same labels, same `work_item.created` activity, same assignment notification —
    and one extra `work_item.instantiated` row on the parent names the template, once, rather than under
    every child. The children inherit the parent’s column, plan point and cycle: a checklist’s steps
    belong to the same delivery as the thing they are steps of. Requires projects C (subitem) on the
    TARGET board; 400 if the template’s kind is `project`.

    Args:
        id (str):
        body (PostProjectTemplatesIdWorkItemsBody | Unset): Where the card LANDS — the board-local
            half a template body deliberately does not carry.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PostProjectTemplatesIdWorkItemsResponse201
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            body=body,
        )
    ).parsed
