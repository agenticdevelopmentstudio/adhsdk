from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.post_v1_iterations_by_id_rollover_body import PostV1IterationsByIdRolloverBody
from ...models.post_v1_iterations_by_id_rollover_response_200 import (
    PostV1IterationsByIdRolloverResponse200,
)
from ...models.stripe_error import StripeError
from ...types import Response


def _get_kwargs(
    id: str,
    *,
    body: PostV1IterationsByIdRolloverBody,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/iterations/{id}/rollover".format(
            id=quote(str(id), safe=""),
        ),
    }

    _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostV1IterationsByIdRolloverResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = PostV1IterationsByIdRolloverResponse200.from_dict(response.json())

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
) -> Response[PostV1IterationsByIdRolloverResponse200 | StripeError]:
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
    body: PostV1IterationsByIdRolloverBody,
) -> Response[PostV1IterationsByIdRolloverResponse200 | StripeError]:
    """Close a cycle: move what did not finish into the next box (or the backlog)

     "Did not finish" is read from each card’s status CATEGORY, never from a list of status keys — a
    board may call its terminal column anything, and `done`/`canceled` are the two categories that mean
    out of play. Everything else moves, `backlog` included: a card nobody started is exactly what rolls
    over. Both boxes are loaded through the same reach and U-verb gates, so a rollover can never push
    cards into an iteration the caller could not otherwise write to.

    Replaces POST /project/iterations/{id}/rollover.

    Args:
        id (str):
        body (PostV1IterationsByIdRolloverBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1IterationsByIdRolloverResponse200 | StripeError]
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
    body: PostV1IterationsByIdRolloverBody,
) -> PostV1IterationsByIdRolloverResponse200 | StripeError | None:
    """Close a cycle: move what did not finish into the next box (or the backlog)

     "Did not finish" is read from each card’s status CATEGORY, never from a list of status keys — a
    board may call its terminal column anything, and `done`/`canceled` are the two categories that mean
    out of play. Everything else moves, `backlog` included: a card nobody started is exactly what rolls
    over. Both boxes are loaded through the same reach and U-verb gates, so a rollover can never push
    cards into an iteration the caller could not otherwise write to.

    Replaces POST /project/iterations/{id}/rollover.

    Args:
        id (str):
        body (PostV1IterationsByIdRolloverBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1IterationsByIdRolloverResponse200 | StripeError
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
    body: PostV1IterationsByIdRolloverBody,
) -> Response[PostV1IterationsByIdRolloverResponse200 | StripeError]:
    """Close a cycle: move what did not finish into the next box (or the backlog)

     "Did not finish" is read from each card’s status CATEGORY, never from a list of status keys — a
    board may call its terminal column anything, and `done`/`canceled` are the two categories that mean
    out of play. Everything else moves, `backlog` included: a card nobody started is exactly what rolls
    over. Both boxes are loaded through the same reach and U-verb gates, so a rollover can never push
    cards into an iteration the caller could not otherwise write to.

    Replaces POST /project/iterations/{id}/rollover.

    Args:
        id (str):
        body (PostV1IterationsByIdRolloverBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1IterationsByIdRolloverResponse200 | StripeError]
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
    body: PostV1IterationsByIdRolloverBody,
) -> PostV1IterationsByIdRolloverResponse200 | StripeError | None:
    """Close a cycle: move what did not finish into the next box (or the backlog)

     "Did not finish" is read from each card’s status CATEGORY, never from a list of status keys — a
    board may call its terminal column anything, and `done`/`canceled` are the two categories that mean
    out of play. Everything else moves, `backlog` included: a card nobody started is exactly what rolls
    over. Both boxes are loaded through the same reach and U-verb gates, so a rollover can never push
    cards into an iteration the caller could not otherwise write to.

    Replaces POST /project/iterations/{id}/rollover.

    Args:
        id (str):
        body (PostV1IterationsByIdRolloverBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1IterationsByIdRolloverResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            body=body,
        )
    ).parsed
