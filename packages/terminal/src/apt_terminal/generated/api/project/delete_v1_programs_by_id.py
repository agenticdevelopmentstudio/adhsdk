from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.deleted import Deleted
from ...models.stripe_error import StripeError
from ...types import Response


def _get_kwargs(
    id: str,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "delete",
        "url": "/v1/programs/{id}".format(
            id=quote(str(id), safe=""),
        ),
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Deleted | StripeError | None:
    if response.status_code == 200:
        response_200 = Deleted.from_dict(response.json())

        return response_200

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
) -> Response[Deleted | StripeError]:
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
) -> Response[Deleted | StripeError]:
    """Soft-delete a program, UN-ASSIGNING every project in it

     The iteration-delete rule, applied one level up: `programId` is nullable and "in no program" is an
    ordinary state, so removing the container has a defined outcome. Refusing instead would strand the
    workspace behind a program it had to empty by hand, one board at a time. The sweep is NOT reach-
    filtered — the authority is the workspace D verb, and half-emptying it would leave boards pointing
    at a container nothing can show — so the response is a COUNT, never the boards. Requires the
    workspace’s projects D verb.

    Replaces DELETE /project/programs/{id}.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Deleted | StripeError]
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
) -> Deleted | StripeError | None:
    """Soft-delete a program, UN-ASSIGNING every project in it

     The iteration-delete rule, applied one level up: `programId` is nullable and "in no program" is an
    ordinary state, so removing the container has a defined outcome. Refusing instead would strand the
    workspace behind a program it had to empty by hand, one board at a time. The sweep is NOT reach-
    filtered — the authority is the workspace D verb, and half-emptying it would leave boards pointing
    at a container nothing can show — so the response is a COUNT, never the boards. Requires the
    workspace’s projects D verb.

    Replaces DELETE /project/programs/{id}.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Deleted | StripeError
    """

    return sync_detailed(
        id=id,
        client=client,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
) -> Response[Deleted | StripeError]:
    """Soft-delete a program, UN-ASSIGNING every project in it

     The iteration-delete rule, applied one level up: `programId` is nullable and "in no program" is an
    ordinary state, so removing the container has a defined outcome. Refusing instead would strand the
    workspace behind a program it had to empty by hand, one board at a time. The sweep is NOT reach-
    filtered — the authority is the workspace D verb, and half-emptying it would leave boards pointing
    at a container nothing can show — so the response is a COUNT, never the boards. Requires the
    workspace’s projects D verb.

    Replaces DELETE /project/programs/{id}.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Deleted | StripeError]
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
) -> Deleted | StripeError | None:
    """Soft-delete a program, UN-ASSIGNING every project in it

     The iteration-delete rule, applied one level up: `programId` is nullable and "in no program" is an
    ordinary state, so removing the container has a defined outcome. Refusing instead would strand the
    workspace behind a program it had to empty by hand, one board at a time. The sweep is NOT reach-
    filtered — the authority is the workspace D verb, and half-emptying it would leave boards pointing
    at a container nothing can show — so the response is a COUNT, never the boards. Requires the
    workspace’s projects D verb.

    Replaces DELETE /project/programs/{id}.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Deleted | StripeError
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
        )
    ).parsed
