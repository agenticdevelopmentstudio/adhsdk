from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.bucket_type_tag_ids import BucketTypeTagIds
from ...models.error import Error
from ...models.put_bucket_buckets_bucket_id_types_type_id_tags_body import (
    PutBucketBucketsBucketIdTypesTypeIdTagsBody,
)
from ...types import UNSET, Response, Unset


def _get_kwargs(
    bucket_id: str,
    type_id: str,
    *,
    body: PutBucketBucketsBucketIdTypesTypeIdTagsBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "put",
        "url": "/bucket/buckets/{bucket_id}/types/{type_id}/tags".format(
            bucket_id=quote(str(bucket_id), safe=""),
            type_id=quote(str(type_id), safe=""),
        ),
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> BucketTypeTagIds | Error | None:
    if response.status_code == 200:
        response_200 = BucketTypeTagIds.from_dict(response.json())

        return response_200

    if response.status_code == 400:
        response_400 = Error.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = Error.from_dict(response.json())

        return response_401

    if response.status_code == 404:
        response_404 = Error.from_dict(response.json())

        return response_404

    if response.status_code == 409:
        response_409 = Error.from_dict(response.json())

        return response_409

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[BucketTypeTagIds | Error]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    bucket_id: str,
    type_id: str,
    *,
    client: AuthenticatedClient,
    body: PutBucketBucketsBucketIdTypesTypeIdTagsBody | Unset = UNSET,
) -> Response[BucketTypeTagIds | Error]:
    """Replace a tags-mode bucket type's tags

    Args:
        bucket_id (str):
        type_id (str):
        body (PutBucketBucketsBucketIdTypesTypeIdTagsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[BucketTypeTagIds | Error]
    """

    kwargs = _get_kwargs(
        bucket_id=bucket_id,
        type_id=type_id,
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    bucket_id: str,
    type_id: str,
    *,
    client: AuthenticatedClient,
    body: PutBucketBucketsBucketIdTypesTypeIdTagsBody | Unset = UNSET,
) -> BucketTypeTagIds | Error | None:
    """Replace a tags-mode bucket type's tags

    Args:
        bucket_id (str):
        type_id (str):
        body (PutBucketBucketsBucketIdTypesTypeIdTagsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        BucketTypeTagIds | Error
    """

    return sync_detailed(
        bucket_id=bucket_id,
        type_id=type_id,
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    bucket_id: str,
    type_id: str,
    *,
    client: AuthenticatedClient,
    body: PutBucketBucketsBucketIdTypesTypeIdTagsBody | Unset = UNSET,
) -> Response[BucketTypeTagIds | Error]:
    """Replace a tags-mode bucket type's tags

    Args:
        bucket_id (str):
        type_id (str):
        body (PutBucketBucketsBucketIdTypesTypeIdTagsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[BucketTypeTagIds | Error]
    """

    kwargs = _get_kwargs(
        bucket_id=bucket_id,
        type_id=type_id,
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    bucket_id: str,
    type_id: str,
    *,
    client: AuthenticatedClient,
    body: PutBucketBucketsBucketIdTypesTypeIdTagsBody | Unset = UNSET,
) -> BucketTypeTagIds | Error | None:
    """Replace a tags-mode bucket type's tags

    Args:
        bucket_id (str):
        type_id (str):
        body (PutBucketBucketsBucketIdTypesTypeIdTagsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        BucketTypeTagIds | Error
    """

    return (
        await asyncio_detailed(
            bucket_id=bucket_id,
            type_id=type_id,
            client=client,
            body=body,
        )
    ).parsed
