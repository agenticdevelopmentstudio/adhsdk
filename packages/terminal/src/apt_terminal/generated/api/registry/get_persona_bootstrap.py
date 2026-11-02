from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.persona_bootstrap import PersonaBootstrap
from ...types import Response


def _get_kwargs() -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/persona/bootstrap",
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | PersonaBootstrap | None:
    if response.status_code == 200:
        response_200 = PersonaBootstrap.from_dict(response.json())

        return response_200

    if response.status_code == 400:
        response_400 = Error.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = Error.from_dict(response.json())

        return response_401

    if response.status_code == 403:
        response_403 = Error.from_dict(response.json())

        return response_403

    if response.status_code == 503:
        response_503 = Error.from_dict(response.json())

        return response_503

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | PersonaBootstrap]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
) -> Response[Error | PersonaBootstrap]:
    """Everything a persona implementation needs to start, from its token alone

     Requires a persona or visitor API token (`tmp_…`) in the Authorization header — NOT a user session
    JWT, which is a 400, and not an application token, which is a 403. The token identifies the persona;
    there is nothing to pass.

    A visitor token gets the same shape with the anonymous floor applied: no tools, no memory, read-only
    buckets, and the public conversation URL. If the persona has since been made non-public, a visitor
    token stops working (403) even though it has not expired.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PersonaBootstrap]
    """

    kwargs = _get_kwargs()

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
) -> Error | PersonaBootstrap | None:
    """Everything a persona implementation needs to start, from its token alone

     Requires a persona or visitor API token (`tmp_…`) in the Authorization header — NOT a user session
    JWT, which is a 400, and not an application token, which is a 403. The token identifies the persona;
    there is nothing to pass.

    A visitor token gets the same shape with the anonymous floor applied: no tools, no memory, read-only
    buckets, and the public conversation URL. If the persona has since been made non-public, a visitor
    token stops working (403) even though it has not expired.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PersonaBootstrap
    """

    return sync_detailed(
        client=client,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
) -> Response[Error | PersonaBootstrap]:
    """Everything a persona implementation needs to start, from its token alone

     Requires a persona or visitor API token (`tmp_…`) in the Authorization header — NOT a user session
    JWT, which is a 400, and not an application token, which is a 403. The token identifies the persona;
    there is nothing to pass.

    A visitor token gets the same shape with the anonymous floor applied: no tools, no memory, read-only
    buckets, and the public conversation URL. If the persona has since been made non-public, a visitor
    token stops working (403) even though it has not expired.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PersonaBootstrap]
    """

    kwargs = _get_kwargs()

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
) -> Error | PersonaBootstrap | None:
    """Everything a persona implementation needs to start, from its token alone

     Requires a persona or visitor API token (`tmp_…`) in the Authorization header — NOT a user session
    JWT, which is a 400, and not an application token, which is a 403. The token identifies the persona;
    there is nothing to pass.

    A visitor token gets the same shape with the anonymous floor applied: no tools, no memory, read-only
    buckets, and the public conversation URL. If the persona has since been made non-public, a visitor
    token stops working (403) even though it has not expired.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PersonaBootstrap
    """

    return (
        await asyncio_detailed(
            client=client,
        )
    ).parsed
