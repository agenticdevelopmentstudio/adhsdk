from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.post_v1_work_items_by_id_triage_body import PostV1WorkItemsByIdTriageBody
from ...models.post_v1_work_items_by_id_triage_response_200 import (
    PostV1WorkItemsByIdTriageResponse200,
)
from ...models.stripe_error import StripeError
from ...types import Response


def _get_kwargs(
    id: str,
    *,
    body: PostV1WorkItemsByIdTriageBody,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/work_items/{id}/triage".format(
            id=quote(str(id), safe=""),
        ),
    }

    _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostV1WorkItemsByIdTriageResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = PostV1WorkItemsByIdTriageResponse200.from_dict(response.json())

        return response_200

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

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[PostV1WorkItemsByIdTriageResponse200 | StripeError]:
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
    body: PostV1WorkItemsByIdTriageBody,
) -> Response[PostV1WorkItemsByIdTriageResponse200 | StripeError]:
    """Accept a card out of the inbox (+ a work_item.triaged activity)

     Stamps `triagedAt` and applies any placement carried in the body. The placement goes through the
    same writer a PATCH uses — so it validates its ids and records its own activity identically — and
    the stamp is appended after it rather than folded in: `triagedAt` is not a patchable field, and
    nothing un-accepts a card. IDEMPOTENT on the stamp: accepting an already-accepted card applies the
    placement and leaves the original timestamp alone, because when a card left the queue has one answer
    and a double-click must not rewrite it. Requires projects U (subitem) on the board. Addressable by
    uuid OR rendered key (`ADH-42`).

    Replaces POST /project/work-items/{id}/triage.

    Args:
        id (str):
        body (PostV1WorkItemsByIdTriageBody): Accepting a card out of the inbox, with the
            placement carried in the same request. Every key is optional — accepting a card that is
            already where it belongs is the common case — and each is applied through the same writer
            a PATCH uses, so it validates and records identically. There is no `decline`: declining is
            naming a status in the `canceled` category, which leaves the card findable in a column
            that says what happened to it.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1WorkItemsByIdTriageResponse200 | StripeError]
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
    body: PostV1WorkItemsByIdTriageBody,
) -> PostV1WorkItemsByIdTriageResponse200 | StripeError | None:
    """Accept a card out of the inbox (+ a work_item.triaged activity)

     Stamps `triagedAt` and applies any placement carried in the body. The placement goes through the
    same writer a PATCH uses — so it validates its ids and records its own activity identically — and
    the stamp is appended after it rather than folded in: `triagedAt` is not a patchable field, and
    nothing un-accepts a card. IDEMPOTENT on the stamp: accepting an already-accepted card applies the
    placement and leaves the original timestamp alone, because when a card left the queue has one answer
    and a double-click must not rewrite it. Requires projects U (subitem) on the board. Addressable by
    uuid OR rendered key (`ADH-42`).

    Replaces POST /project/work-items/{id}/triage.

    Args:
        id (str):
        body (PostV1WorkItemsByIdTriageBody): Accepting a card out of the inbox, with the
            placement carried in the same request. Every key is optional — accepting a card that is
            already where it belongs is the common case — and each is applied through the same writer
            a PATCH uses, so it validates and records identically. There is no `decline`: declining is
            naming a status in the `canceled` category, which leaves the card findable in a column
            that says what happened to it.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1WorkItemsByIdTriageResponse200 | StripeError
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
    body: PostV1WorkItemsByIdTriageBody,
) -> Response[PostV1WorkItemsByIdTriageResponse200 | StripeError]:
    """Accept a card out of the inbox (+ a work_item.triaged activity)

     Stamps `triagedAt` and applies any placement carried in the body. The placement goes through the
    same writer a PATCH uses — so it validates its ids and records its own activity identically — and
    the stamp is appended after it rather than folded in: `triagedAt` is not a patchable field, and
    nothing un-accepts a card. IDEMPOTENT on the stamp: accepting an already-accepted card applies the
    placement and leaves the original timestamp alone, because when a card left the queue has one answer
    and a double-click must not rewrite it. Requires projects U (subitem) on the board. Addressable by
    uuid OR rendered key (`ADH-42`).

    Replaces POST /project/work-items/{id}/triage.

    Args:
        id (str):
        body (PostV1WorkItemsByIdTriageBody): Accepting a card out of the inbox, with the
            placement carried in the same request. Every key is optional — accepting a card that is
            already where it belongs is the common case — and each is applied through the same writer
            a PATCH uses, so it validates and records identically. There is no `decline`: declining is
            naming a status in the `canceled` category, which leaves the card findable in a column
            that says what happened to it.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1WorkItemsByIdTriageResponse200 | StripeError]
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
    body: PostV1WorkItemsByIdTriageBody,
) -> PostV1WorkItemsByIdTriageResponse200 | StripeError | None:
    """Accept a card out of the inbox (+ a work_item.triaged activity)

     Stamps `triagedAt` and applies any placement carried in the body. The placement goes through the
    same writer a PATCH uses — so it validates its ids and records its own activity identically — and
    the stamp is appended after it rather than folded in: `triagedAt` is not a patchable field, and
    nothing un-accepts a card. IDEMPOTENT on the stamp: accepting an already-accepted card applies the
    placement and leaves the original timestamp alone, because when a card left the queue has one answer
    and a double-click must not rewrite it. Requires projects U (subitem) on the board. Addressable by
    uuid OR rendered key (`ADH-42`).

    Replaces POST /project/work-items/{id}/triage.

    Args:
        id (str):
        body (PostV1WorkItemsByIdTriageBody): Accepting a card out of the inbox, with the
            placement carried in the same request. Every key is optional — accepting a card that is
            already where it belongs is the common case — and each is applied through the same writer
            a PATCH uses, so it validates and records identically. There is no `decline`: declining is
            naming a status in the `canceled` category, which leaves the card findable in a column
            that says what happened to it.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1WorkItemsByIdTriageResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            body=body,
        )
    ).parsed
