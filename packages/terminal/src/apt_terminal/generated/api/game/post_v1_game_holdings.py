from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.game_holding_put import GameHoldingPut
from ...models.post_v1_game_holdings_response_200 import PostV1GameHoldingsResponse200
from ...models.stripe_error import StripeError
from ...types import Response


def _get_kwargs(
    *,
    body: GameHoldingPut,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/game/holdings",
    }

    _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostV1GameHoldingsResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = PostV1GameHoldingsResponse200.from_dict(response.json())

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
) -> Response[PostV1GameHoldingsResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    body: GameHoldingPut,
) -> Response[PostV1GameHoldingsResponse200 | StripeError]:
    """Acquire an artifact (idempotent by the unique, not by a caller-sent key)

     A toggle, not an append: `uq_holdings_owner_artifact` makes a repeat an update of the same row, so
    no `client_event_id` is involved — the row IS the key. `acquired_at` is deliberately NOT refreshed
    on a repeat, so re-tapping cannot reorder your own inventory. The artifact must belong to this game
    AND be one the caller may see; without that last test this route would be a read oracle over every
    other player’s private work. The owner comes from the principal and is never read from the body,
    which is why this is not generic CRUD.

    Replaces PUT /game/holdings.

    Args:
        body (GameHoldingPut):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1GameHoldingsResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    body: GameHoldingPut,
) -> PostV1GameHoldingsResponse200 | StripeError | None:
    """Acquire an artifact (idempotent by the unique, not by a caller-sent key)

     A toggle, not an append: `uq_holdings_owner_artifact` makes a repeat an update of the same row, so
    no `client_event_id` is involved — the row IS the key. `acquired_at` is deliberately NOT refreshed
    on a repeat, so re-tapping cannot reorder your own inventory. The artifact must belong to this game
    AND be one the caller may see; without that last test this route would be a read oracle over every
    other player’s private work. The owner comes from the principal and is never read from the body,
    which is why this is not generic CRUD.

    Replaces PUT /game/holdings.

    Args:
        body (GameHoldingPut):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1GameHoldingsResponse200 | StripeError
    """

    return sync_detailed(
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    body: GameHoldingPut,
) -> Response[PostV1GameHoldingsResponse200 | StripeError]:
    """Acquire an artifact (idempotent by the unique, not by a caller-sent key)

     A toggle, not an append: `uq_holdings_owner_artifact` makes a repeat an update of the same row, so
    no `client_event_id` is involved — the row IS the key. `acquired_at` is deliberately NOT refreshed
    on a repeat, so re-tapping cannot reorder your own inventory. The artifact must belong to this game
    AND be one the caller may see; without that last test this route would be a read oracle over every
    other player’s private work. The owner comes from the principal and is never read from the body,
    which is why this is not generic CRUD.

    Replaces PUT /game/holdings.

    Args:
        body (GameHoldingPut):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1GameHoldingsResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    body: GameHoldingPut,
) -> PostV1GameHoldingsResponse200 | StripeError | None:
    """Acquire an artifact (idempotent by the unique, not by a caller-sent key)

     A toggle, not an append: `uq_holdings_owner_artifact` makes a repeat an update of the same row, so
    no `client_event_id` is involved — the row IS the key. `acquired_at` is deliberately NOT refreshed
    on a repeat, so re-tapping cannot reorder your own inventory. The artifact must belong to this game
    AND be one the caller may see; without that last test this route would be a read oracle over every
    other player’s private work. The owner comes from the principal and is never read from the body,
    which is why this is not generic CRUD.

    Replaces PUT /game/holdings.

    Args:
        body (GameHoldingPut):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1GameHoldingsResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
        )
    ).parsed
