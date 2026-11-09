from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.post_v1_bucket_tags_by_id_rows_by_type_by_row_id_response_200 import (
    PostV1BucketTagsByIdRowsByTypeByRowIdResponse200,
)
from ...models.stripe_error import StripeError
from ...types import Response


def _get_kwargs(
    id: str,
    type_: str,
    row_id: str,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/bucket_tags/{id}/rows/{type_}/{row_id}".format(
            id=quote(str(id), safe=""),
            type_=quote(str(type_), safe=""),
            row_id=quote(str(row_id), safe=""),
        ),
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostV1BucketTagsByIdRowsByTypeByRowIdResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = PostV1BucketTagsByIdRowsByTypeByRowIdResponse200.from_dict(response.json())

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

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[PostV1BucketTagsByIdRowsByTypeByRowIdResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    id: str,
    type_: str,
    row_id: str,
    *,
    client: AuthenticatedClient,
) -> Response[PostV1BucketTagsByIdRowsByTypeByRowIdResponse200 | StripeError]:
    """Tag a row (idempotent)

     Replaces PUT /bucket/tags/{tagId}/rows/{table}/{rowId}.

    Args:
        id (str):
        type_ (str):
        row_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1BucketTagsByIdRowsByTypeByRowIdResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
        type_=type_,
        row_id=row_id,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    type_: str,
    row_id: str,
    *,
    client: AuthenticatedClient,
) -> PostV1BucketTagsByIdRowsByTypeByRowIdResponse200 | StripeError | None:
    """Tag a row (idempotent)

     Replaces PUT /bucket/tags/{tagId}/rows/{table}/{rowId}.

    Args:
        id (str):
        type_ (str):
        row_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1BucketTagsByIdRowsByTypeByRowIdResponse200 | StripeError
    """

    return sync_detailed(
        id=id,
        type_=type_,
        row_id=row_id,
        client=client,
    ).parsed


async def asyncio_detailed(
    id: str,
    type_: str,
    row_id: str,
    *,
    client: AuthenticatedClient,
) -> Response[PostV1BucketTagsByIdRowsByTypeByRowIdResponse200 | StripeError]:
    """Tag a row (idempotent)

     Replaces PUT /bucket/tags/{tagId}/rows/{table}/{rowId}.

    Args:
        id (str):
        type_ (str):
        row_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1BucketTagsByIdRowsByTypeByRowIdResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
        type_=type_,
        row_id=row_id,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    type_: str,
    row_id: str,
    *,
    client: AuthenticatedClient,
) -> PostV1BucketTagsByIdRowsByTypeByRowIdResponse200 | StripeError | None:
    """Tag a row (idempotent)

     Replaces PUT /bucket/tags/{tagId}/rows/{table}/{rowId}.

    Args:
        id (str):
        type_ (str):
        row_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1BucketTagsByIdRowsByTypeByRowIdResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            id=id,
            type_=type_,
            row_id=row_id,
            client=client,
        )
    ).parsed
