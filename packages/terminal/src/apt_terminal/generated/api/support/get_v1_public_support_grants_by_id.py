from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.get_v1_public_support_grants_by_id_response_200 import (
    GetV1PublicSupportGrantsByIdResponse200,
)
from ...models.stripe_error import StripeError
from ...types import UNSET, Response, Unset


def _get_kwargs(
    id: str,
    *,
    token: str,
    expand: list[str] | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["token"] = token

    json_expand: list[str] | Unset = UNSET
    if not isinstance(expand, Unset):
        json_expand = expand

    params["expand[]"] = json_expand

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/v1/public/support/grants/{id}".format(
            id=quote(str(id), safe=""),
        ),
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> GetV1PublicSupportGrantsByIdResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = GetV1PublicSupportGrantsByIdResponse200.from_dict(response.json())

        return response_200

    if response.status_code == 404:
        response_404 = StripeError.from_dict(response.json())

        return response_404

    if response.status_code == 409:
        response_409 = StripeError.from_dict(response.json())

        return response_409

    if response.status_code == 410:
        response_410 = StripeError.from_dict(response.json())

        return response_410

    if response.status_code == 429:
        response_429 = StripeError.from_dict(response.json())

        return response_429

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[GetV1PublicSupportGrantsByIdResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    id: str,
    *,
    client: AuthenticatedClient | Client,
    token: str,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1PublicSupportGrantsByIdResponse200 | StripeError]:
    """A support request, by its email link

     The grant and the reads under it, while it is pending or live. 409 `decided` for a grant denied,
    ended or revoked; 410 `lapsed` for one not decided within seven days.

    Replaces GET /public/support/grants/{id}.

    Args:
        id (str):
        token (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1PublicSupportGrantsByIdResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
        token=token,
        expand=expand,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    *,
    client: AuthenticatedClient | Client,
    token: str,
    expand: list[str] | Unset = UNSET,
) -> GetV1PublicSupportGrantsByIdResponse200 | StripeError | None:
    """A support request, by its email link

     The grant and the reads under it, while it is pending or live. 409 `decided` for a grant denied,
    ended or revoked; 410 `lapsed` for one not decided within seven days.

    Replaces GET /public/support/grants/{id}.

    Args:
        id (str):
        token (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1PublicSupportGrantsByIdResponse200 | StripeError
    """

    return sync_detailed(
        id=id,
        client=client,
        token=token,
        expand=expand,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient | Client,
    token: str,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1PublicSupportGrantsByIdResponse200 | StripeError]:
    """A support request, by its email link

     The grant and the reads under it, while it is pending or live. 409 `decided` for a grant denied,
    ended or revoked; 410 `lapsed` for one not decided within seven days.

    Replaces GET /public/support/grants/{id}.

    Args:
        id (str):
        token (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1PublicSupportGrantsByIdResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
        token=token,
        expand=expand,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    *,
    client: AuthenticatedClient | Client,
    token: str,
    expand: list[str] | Unset = UNSET,
) -> GetV1PublicSupportGrantsByIdResponse200 | StripeError | None:
    """A support request, by its email link

     The grant and the reads under it, while it is pending or live. 409 `decided` for a grant denied,
    ended or revoked; 410 `lapsed` for one not decided within seven days.

    Replaces GET /public/support/grants/{id}.

    Args:
        id (str):
        token (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1PublicSupportGrantsByIdResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            token=token,
            expand=expand,
        )
    ).parsed
