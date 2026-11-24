from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.deleted import Deleted
from ...models.stripe_error import StripeError
from ...types import UNSET, Response


def _get_kwargs(
    *,
    artifact_id: str,
    kind: str,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["artifact_id"] = artifact_id

    params["kind"] = kind

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "delete",
        "url": "/v1/game/holdings",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Deleted | StripeError | None:
    if response.status_code == 200:
        response_200 = Deleted.from_dict(response.json())

        return response_200

    if response.status_code == 400:
        response_400 = StripeError.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = StripeError.from_dict(response.json())

        return response_401

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Deleted | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    artifact_id: str,
    kind: str,
) -> Response[Deleted | StripeError]:
    """Revoke a holding (no-op when not held)

     The selector is on the query string rather than in a body: a DELETE body is legal but is dropped by
    enough proxies that a route depending on one fails intermittently, in somebody else’s
    infrastructure. 204 whether or not a row was hit — a 404 would distinguish "you never held this"
    from "you did".

    Replaces DELETE /game/holdings.

    Args:
        artifact_id (str):
        kind (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Deleted | StripeError]
    """

    kwargs = _get_kwargs(
        artifact_id=artifact_id,
        kind=kind,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    artifact_id: str,
    kind: str,
) -> Deleted | StripeError | None:
    """Revoke a holding (no-op when not held)

     The selector is on the query string rather than in a body: a DELETE body is legal but is dropped by
    enough proxies that a route depending on one fails intermittently, in somebody else’s
    infrastructure. 204 whether or not a row was hit — a 404 would distinguish "you never held this"
    from "you did".

    Replaces DELETE /game/holdings.

    Args:
        artifact_id (str):
        kind (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Deleted | StripeError
    """

    return sync_detailed(
        client=client,
        artifact_id=artifact_id,
        kind=kind,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    artifact_id: str,
    kind: str,
) -> Response[Deleted | StripeError]:
    """Revoke a holding (no-op when not held)

     The selector is on the query string rather than in a body: a DELETE body is legal but is dropped by
    enough proxies that a route depending on one fails intermittently, in somebody else’s
    infrastructure. 204 whether or not a row was hit — a 404 would distinguish "you never held this"
    from "you did".

    Replaces DELETE /game/holdings.

    Args:
        artifact_id (str):
        kind (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Deleted | StripeError]
    """

    kwargs = _get_kwargs(
        artifact_id=artifact_id,
        kind=kind,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    artifact_id: str,
    kind: str,
) -> Deleted | StripeError | None:
    """Revoke a holding (no-op when not held)

     The selector is on the query string rather than in a body: a DELETE body is legal but is dropped by
    enough proxies that a route depending on one fails intermittently, in somebody else’s
    infrastructure. 204 whether or not a row was hit — a 404 would distinguish "you never held this"
    from "you did".

    Replaces DELETE /game/holdings.

    Args:
        artifact_id (str):
        kind (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Deleted | StripeError
    """

    return (
        await asyncio_detailed(
            client=client,
            artifact_id=artifact_id,
            kind=kind,
        )
    ).parsed
