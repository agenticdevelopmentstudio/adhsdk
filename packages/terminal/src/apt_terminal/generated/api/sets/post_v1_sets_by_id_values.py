from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.post_v1_sets_by_id_values_response_200 import PostV1SetsByIdValuesResponse200
from ...models.set_values_put import SetValuesPut
from ...models.stripe_error import StripeError
from ...types import Response


def _get_kwargs(
    id: str,
    *,
    body: SetValuesPut,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/sets/{id}/values".format(
            id=quote(str(id), safe=""),
        ),
    }

    _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostV1SetsByIdValuesResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = PostV1SetsByIdValuesResponse200.from_dict(response.json())

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

    if response.status_code == 422:
        response_422 = StripeError.from_dict(response.json())

        return response_422

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[PostV1SetsByIdValuesResponse200 | StripeError]:
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
    body: SetValuesPut,
) -> Response[PostV1SetsByIdValuesResponse200 | StripeError]:
    """Replace a set's permissions and limits

     Every key must be one the catalog's `setEntries` declares, with a value of its type (400 otherwise).
    A product admin, signed in through the product's admin site, may not write `usage.tier`, nor a
    `storage.quota_bytes` above the default quota (403).

    Replaces PUT /sets/{id}/values.

    Args:
        id (str):
        body (SetValuesPut):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1SetsByIdValuesResponse200 | StripeError]
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
    body: SetValuesPut,
) -> PostV1SetsByIdValuesResponse200 | StripeError | None:
    """Replace a set's permissions and limits

     Every key must be one the catalog's `setEntries` declares, with a value of its type (400 otherwise).
    A product admin, signed in through the product's admin site, may not write `usage.tier`, nor a
    `storage.quota_bytes` above the default quota (403).

    Replaces PUT /sets/{id}/values.

    Args:
        id (str):
        body (SetValuesPut):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1SetsByIdValuesResponse200 | StripeError
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
    body: SetValuesPut,
) -> Response[PostV1SetsByIdValuesResponse200 | StripeError]:
    """Replace a set's permissions and limits

     Every key must be one the catalog's `setEntries` declares, with a value of its type (400 otherwise).
    A product admin, signed in through the product's admin site, may not write `usage.tier`, nor a
    `storage.quota_bytes` above the default quota (403).

    Replaces PUT /sets/{id}/values.

    Args:
        id (str):
        body (SetValuesPut):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1SetsByIdValuesResponse200 | StripeError]
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
    body: SetValuesPut,
) -> PostV1SetsByIdValuesResponse200 | StripeError | None:
    """Replace a set's permissions and limits

     Every key must be one the catalog's `setEntries` declares, with a value of its type (400 otherwise).
    A product admin, signed in through the product's admin site, may not write `usage.tier`, nor a
    `storage.quota_bytes` above the default quota (403).

    Replaces PUT /sets/{id}/values.

    Args:
        id (str):
        body (SetValuesPut):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1SetsByIdValuesResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            body=body,
        )
    ).parsed
