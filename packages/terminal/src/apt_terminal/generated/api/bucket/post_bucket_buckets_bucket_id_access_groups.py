from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.bucket_access_group import BucketAccessGroup
from ...models.error import Error
from ...models.post_bucket_buckets_bucket_id_access_groups_body import (
    PostBucketBucketsBucketIdAccessGroupsBody,
)
from ...types import UNSET, Response, Unset


def _get_kwargs(
    bucket_id: str,
    *,
    body: PostBucketBucketsBucketIdAccessGroupsBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/bucket/buckets/{bucket_id}/access-groups".format(
            bucket_id=quote(str(bucket_id), safe=""),
        ),
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> BucketAccessGroup | Error | None:
    if response.status_code == 201:
        response_201 = BucketAccessGroup.from_dict(response.json())

        return response_201

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
) -> Response[BucketAccessGroup | Error]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    bucket_id: str,
    *,
    client: AuthenticatedClient,
    body: PostBucketBucketsBucketIdAccessGroupsBody | Unset = UNSET,
) -> Response[BucketAccessGroup | Error]:
    """Create an access group in a bucket

    Args:
        bucket_id (str):
        body (PostBucketBucketsBucketIdAccessGroupsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[BucketAccessGroup | Error]
    """

    kwargs = _get_kwargs(
        bucket_id=bucket_id,
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    bucket_id: str,
    *,
    client: AuthenticatedClient,
    body: PostBucketBucketsBucketIdAccessGroupsBody | Unset = UNSET,
) -> BucketAccessGroup | Error | None:
    """Create an access group in a bucket

    Args:
        bucket_id (str):
        body (PostBucketBucketsBucketIdAccessGroupsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        BucketAccessGroup | Error
    """

    return sync_detailed(
        bucket_id=bucket_id,
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    bucket_id: str,
    *,
    client: AuthenticatedClient,
    body: PostBucketBucketsBucketIdAccessGroupsBody | Unset = UNSET,
) -> Response[BucketAccessGroup | Error]:
    """Create an access group in a bucket

    Args:
        bucket_id (str):
        body (PostBucketBucketsBucketIdAccessGroupsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[BucketAccessGroup | Error]
    """

    kwargs = _get_kwargs(
        bucket_id=bucket_id,
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    bucket_id: str,
    *,
    client: AuthenticatedClient,
    body: PostBucketBucketsBucketIdAccessGroupsBody | Unset = UNSET,
) -> BucketAccessGroup | Error | None:
    """Create an access group in a bucket

    Args:
        bucket_id (str):
        body (PostBucketBucketsBucketIdAccessGroupsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        BucketAccessGroup | Error
    """

    return (
        await asyncio_detailed(
            bucket_id=bucket_id,
            client=client,
            body=body,
        )
    ).parsed
