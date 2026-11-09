from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.delete_v1_shipr_repos_by_id_response_202 import DeleteV1ShiprReposByIdResponse202
from ...models.deleted import Deleted
from ...models.stripe_error import StripeError
from ...types import Response


def _get_kwargs(
    id: str,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "delete",
        "url": "/v1/shipr/repos/{id}".format(
            id=quote(str(id), safe=""),
        ),
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> DeleteV1ShiprReposByIdResponse202 | Deleted | StripeError | None:
    if response.status_code == 200:
        response_200 = Deleted.from_dict(response.json())

        return response_200

    if response.status_code == 202:
        response_202 = DeleteV1ShiprReposByIdResponse202.from_dict(response.json())

        return response_202

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
) -> Response[DeleteV1ShiprReposByIdResponse202 | Deleted | StripeError]:
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
) -> Response[DeleteV1ShiprReposByIdResponse202 | Deleted | StripeError]:
    """Queue a unregister for this repository

     Sugar over POST /shipr/runs with scopeKind=deploy_repo. Returns immediately with a run id — watch it
    on /shipr/stream/runs/{id}.

    Replaces POST /shipr/repos/{id}/unregister.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[DeleteV1ShiprReposByIdResponse202 | Deleted | StripeError]
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
) -> DeleteV1ShiprReposByIdResponse202 | Deleted | StripeError | None:
    """Queue a unregister for this repository

     Sugar over POST /shipr/runs with scopeKind=deploy_repo. Returns immediately with a run id — watch it
    on /shipr/stream/runs/{id}.

    Replaces POST /shipr/repos/{id}/unregister.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        DeleteV1ShiprReposByIdResponse202 | Deleted | StripeError
    """

    return sync_detailed(
        id=id,
        client=client,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
) -> Response[DeleteV1ShiprReposByIdResponse202 | Deleted | StripeError]:
    """Queue a unregister for this repository

     Sugar over POST /shipr/runs with scopeKind=deploy_repo. Returns immediately with a run id — watch it
    on /shipr/stream/runs/{id}.

    Replaces POST /shipr/repos/{id}/unregister.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[DeleteV1ShiprReposByIdResponse202 | Deleted | StripeError]
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
) -> DeleteV1ShiprReposByIdResponse202 | Deleted | StripeError | None:
    """Queue a unregister for this repository

     Sugar over POST /shipr/runs with scopeKind=deploy_repo. Returns immediately with a run id — watch it
    on /shipr/stream/runs/{id}.

    Replaces POST /shipr/repos/{id}/unregister.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        DeleteV1ShiprReposByIdResponse202 | Deleted | StripeError
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
        )
    ).parsed
