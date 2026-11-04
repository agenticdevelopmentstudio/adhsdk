from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.get_ownership_owned_kind import GetOwnershipOwnedKind
from ...models.get_ownership_owned_response_200 import GetOwnershipOwnedResponse200
from ...types import UNSET, Response


def _get_kwargs(
    *,
    kind: GetOwnershipOwnedKind,
    id: str,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    json_kind = kind.value
    params["kind"] = json_kind

    params["id"] = id

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/ownership/owned",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | GetOwnershipOwnedResponse200 | None:
    if response.status_code == 200:
        response_200 = GetOwnershipOwnedResponse200.from_dict(response.json())

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

    if response.status_code == 404:
        response_404 = Error.from_dict(response.json())

        return response_404

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | GetOwnershipOwnedResponse200]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    kind: GetOwnershipOwnedKind,
    id: str,
) -> Response[Error | GetOwnershipOwnedResponse200]:
    """What a customer, organization, persona or ecosystem still owns

    Args:
        kind (GetOwnershipOwnedKind):
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GetOwnershipOwnedResponse200]
    """

    kwargs = _get_kwargs(
        kind=kind,
        id=id,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    kind: GetOwnershipOwnedKind,
    id: str,
) -> Error | GetOwnershipOwnedResponse200 | None:
    """What a customer, organization, persona or ecosystem still owns

    Args:
        kind (GetOwnershipOwnedKind):
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GetOwnershipOwnedResponse200
    """

    return sync_detailed(
        client=client,
        kind=kind,
        id=id,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    kind: GetOwnershipOwnedKind,
    id: str,
) -> Response[Error | GetOwnershipOwnedResponse200]:
    """What a customer, organization, persona or ecosystem still owns

    Args:
        kind (GetOwnershipOwnedKind):
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GetOwnershipOwnedResponse200]
    """

    kwargs = _get_kwargs(
        kind=kind,
        id=id,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    kind: GetOwnershipOwnedKind,
    id: str,
) -> Error | GetOwnershipOwnedResponse200 | None:
    """What a customer, organization, persona or ecosystem still owns

    Args:
        kind (GetOwnershipOwnedKind):
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GetOwnershipOwnedResponse200
    """

    return (
        await asyncio_detailed(
            client=client,
            kind=kind,
            id=id,
        )
    ).parsed
