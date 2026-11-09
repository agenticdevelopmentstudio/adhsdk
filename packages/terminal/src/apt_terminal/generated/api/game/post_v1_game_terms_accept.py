from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.game_term_post import GameTermPost
from ...models.post_v1_game_terms_accept_response_200 import PostV1GameTermsAcceptResponse200
from ...models.stripe_error import StripeError
from ...types import Response


def _get_kwargs(
    *,
    body: GameTermPost,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/game/terms/accept",
    }

    _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostV1GameTermsAcceptResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = PostV1GameTermsAcceptResponse200.from_dict(response.json())

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

    if response.status_code == 422:
        response_422 = StripeError.from_dict(response.json())

        return response_422

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[PostV1GameTermsAcceptResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    body: GameTermPost,
) -> Response[PostV1GameTermsAcceptResponse200 | StripeError]:
    """Coin a term (screened; idempotent on the normalised key)

     The one route in this feature that exists for a safety reason rather than a data one. A term is
    minted by a player and then appears in every OTHER player’s composer, so it is screened BEFORE the
    insert — a refused value mints no row. §5.2 folded `terms` into `game.definitions`, and one table
    cannot carry two write settings, so the restriction that used to live on the table lives on this
    path. Write-only: reading the roster is a `kind=term` read of `game.definitions` through generic
    CRUD. The `key` is the name lowercased with runs of non-alphanumerics collapsed to one hyphen, which
    is what makes "Fire Ball", "fire ball" and "fire-ball" one term; a name that normalises to nothing
    is 422. A term already coined returns the EXISTING row with 200 — the first coiner keeps the
    authorship credit — rather than a 409, because two players reaching the same word is the ordinary
    case for a shared vocabulary. `artifact_id` is recorded as `data.coined_from_artifact_id`, written
    over any caller-supplied value.

    Replaces POST /game/terms.

    Args:
        body (GameTermPost):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1GameTermsAcceptResponse200 | StripeError]
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
    body: GameTermPost,
) -> PostV1GameTermsAcceptResponse200 | StripeError | None:
    """Coin a term (screened; idempotent on the normalised key)

     The one route in this feature that exists for a safety reason rather than a data one. A term is
    minted by a player and then appears in every OTHER player’s composer, so it is screened BEFORE the
    insert — a refused value mints no row. §5.2 folded `terms` into `game.definitions`, and one table
    cannot carry two write settings, so the restriction that used to live on the table lives on this
    path. Write-only: reading the roster is a `kind=term` read of `game.definitions` through generic
    CRUD. The `key` is the name lowercased with runs of non-alphanumerics collapsed to one hyphen, which
    is what makes "Fire Ball", "fire ball" and "fire-ball" one term; a name that normalises to nothing
    is 422. A term already coined returns the EXISTING row with 200 — the first coiner keeps the
    authorship credit — rather than a 409, because two players reaching the same word is the ordinary
    case for a shared vocabulary. `artifact_id` is recorded as `data.coined_from_artifact_id`, written
    over any caller-supplied value.

    Replaces POST /game/terms.

    Args:
        body (GameTermPost):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1GameTermsAcceptResponse200 | StripeError
    """

    return sync_detailed(
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    body: GameTermPost,
) -> Response[PostV1GameTermsAcceptResponse200 | StripeError]:
    """Coin a term (screened; idempotent on the normalised key)

     The one route in this feature that exists for a safety reason rather than a data one. A term is
    minted by a player and then appears in every OTHER player’s composer, so it is screened BEFORE the
    insert — a refused value mints no row. §5.2 folded `terms` into `game.definitions`, and one table
    cannot carry two write settings, so the restriction that used to live on the table lives on this
    path. Write-only: reading the roster is a `kind=term` read of `game.definitions` through generic
    CRUD. The `key` is the name lowercased with runs of non-alphanumerics collapsed to one hyphen, which
    is what makes "Fire Ball", "fire ball" and "fire-ball" one term; a name that normalises to nothing
    is 422. A term already coined returns the EXISTING row with 200 — the first coiner keeps the
    authorship credit — rather than a 409, because two players reaching the same word is the ordinary
    case for a shared vocabulary. `artifact_id` is recorded as `data.coined_from_artifact_id`, written
    over any caller-supplied value.

    Replaces POST /game/terms.

    Args:
        body (GameTermPost):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1GameTermsAcceptResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    body: GameTermPost,
) -> PostV1GameTermsAcceptResponse200 | StripeError | None:
    """Coin a term (screened; idempotent on the normalised key)

     The one route in this feature that exists for a safety reason rather than a data one. A term is
    minted by a player and then appears in every OTHER player’s composer, so it is screened BEFORE the
    insert — a refused value mints no row. §5.2 folded `terms` into `game.definitions`, and one table
    cannot carry two write settings, so the restriction that used to live on the table lives on this
    path. Write-only: reading the roster is a `kind=term` read of `game.definitions` through generic
    CRUD. The `key` is the name lowercased with runs of non-alphanumerics collapsed to one hyphen, which
    is what makes "Fire Ball", "fire ball" and "fire-ball" one term; a name that normalises to nothing
    is 422. A term already coined returns the EXISTING row with 200 — the first coiner keeps the
    authorship credit — rather than a 409, because two players reaching the same word is the ordinary
    case for a shared vocabulary. `artifact_id` is recorded as `data.coined_from_artifact_id`, written
    over any caller-supplied value.

    Replaces POST /game/terms.

    Args:
        body (GameTermPost):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1GameTermsAcceptResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
        )
    ).parsed
