from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.game_artifact import GameArtifact
from ...types import Response


def _get_kwargs(
    id: str,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/game/artifacts/{id}/publish".format(
            id=quote(str(id), safe=""),
        ),
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | GameArtifact | None:
    if response.status_code == 200:
        response_200 = GameArtifact.from_dict(response.json())

        return response_200

    if response.status_code == 401:
        response_401 = Error.from_dict(response.json())

        return response_401

    if response.status_code == 403:
        response_403 = Error.from_dict(response.json())

        return response_403

    if response.status_code == 404:
        response_404 = Error.from_dict(response.json())

        return response_404

    if response.status_code == 422:
        response_422 = Error.from_dict(response.json())

        return response_422

    if response.status_code == 429:
        response_429 = Error.from_dict(response.json())

        return response_429

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | GameArtifact]:
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
) -> Response[Error | GameArtifact]:
    """Publish the caller’s own artifact to the public feed (screened)

     The write side §6.6 named and §6.3 owed: `visibility` and `published_at` are server-managed on
    `game.artifacts`, so this is the only way an artifact reaches `GET /game/feed`. Screening (§6.5)
    runs BEFORE the row flips, on every string the artifact carries — `text` plus every string leaf of
    `summary` and `data` — because adh cannot tell which jsonb slots hold player prose without doing the
    engine’s job. Long artifacts are screened in CHUNKS rather than truncated to the classifier’s
    character budget, which would publish the tail unjudged; past eight chunks the request is 422 rather
    than silently partly-screened. Idempotent: an already-published artifact returns 200 with the
    current row and calls no classifier, so a retry is free. 404 covers both "no such artifact" and "not
    yours" — the ownership term is in the UPDATE itself, so there is no check-then-write window.
    Publishing is one-way; withdrawing is `DELETE /game/artifacts/{id}`.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GameArtifact]
    """

    kwargs = _get_kwargs(
        id=id,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    *,
    client: AuthenticatedClient,
) -> Error | GameArtifact | None:
    """Publish the caller’s own artifact to the public feed (screened)

     The write side §6.6 named and §6.3 owed: `visibility` and `published_at` are server-managed on
    `game.artifacts`, so this is the only way an artifact reaches `GET /game/feed`. Screening (§6.5)
    runs BEFORE the row flips, on every string the artifact carries — `text` plus every string leaf of
    `summary` and `data` — because adh cannot tell which jsonb slots hold player prose without doing the
    engine’s job. Long artifacts are screened in CHUNKS rather than truncated to the classifier’s
    character budget, which would publish the tail unjudged; past eight chunks the request is 422 rather
    than silently partly-screened. Idempotent: an already-published artifact returns 200 with the
    current row and calls no classifier, so a retry is free. 404 covers both "no such artifact" and "not
    yours" — the ownership term is in the UPDATE itself, so there is no check-then-write window.
    Publishing is one-way; withdrawing is `DELETE /game/artifacts/{id}`.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GameArtifact
    """

    return sync_detailed(
        id=id,
        client=client,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
) -> Response[Error | GameArtifact]:
    """Publish the caller’s own artifact to the public feed (screened)

     The write side §6.6 named and §6.3 owed: `visibility` and `published_at` are server-managed on
    `game.artifacts`, so this is the only way an artifact reaches `GET /game/feed`. Screening (§6.5)
    runs BEFORE the row flips, on every string the artifact carries — `text` plus every string leaf of
    `summary` and `data` — because adh cannot tell which jsonb slots hold player prose without doing the
    engine’s job. Long artifacts are screened in CHUNKS rather than truncated to the classifier’s
    character budget, which would publish the tail unjudged; past eight chunks the request is 422 rather
    than silently partly-screened. Idempotent: an already-published artifact returns 200 with the
    current row and calls no classifier, so a retry is free. 404 covers both "no such artifact" and "not
    yours" — the ownership term is in the UPDATE itself, so there is no check-then-write window.
    Publishing is one-way; withdrawing is `DELETE /game/artifacts/{id}`.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GameArtifact]
    """

    kwargs = _get_kwargs(
        id=id,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    *,
    client: AuthenticatedClient,
) -> Error | GameArtifact | None:
    """Publish the caller’s own artifact to the public feed (screened)

     The write side §6.6 named and §6.3 owed: `visibility` and `published_at` are server-managed on
    `game.artifacts`, so this is the only way an artifact reaches `GET /game/feed`. Screening (§6.5)
    runs BEFORE the row flips, on every string the artifact carries — `text` plus every string leaf of
    `summary` and `data` — because adh cannot tell which jsonb slots hold player prose without doing the
    engine’s job. Long artifacts are screened in CHUNKS rather than truncated to the classifier’s
    character budget, which would publish the tail unjudged; past eight chunks the request is 422 rather
    than silently partly-screened. Idempotent: an already-published artifact returns 200 with the
    current row and calls no classifier, so a retry is free. 404 covers both "no such artifact" and "not
    yours" — the ownership term is in the UPDATE itself, so there is no check-then-write window.
    Publishing is one-way; withdrawing is `DELETE /game/artifacts/{id}`.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GameArtifact
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
        )
    ).parsed
