from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.bucket_access_group_list import BucketAccessGroupList
from ...models.error import Error
from ...types import Response


def _get_kwargs(
    bucket_id: str,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/bucket/buckets/{bucket_id}/access-groups".format(
            bucket_id=quote(str(bucket_id), safe=""),
        ),
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> BucketAccessGroupList | Error | None:
    if response.status_code == 200:
        response_200 = BucketAccessGroupList.from_dict(response.json())

        return response_200

    if response.status_code == 401:
        response_401 = Error.from_dict(response.json())

        return response_401

    if response.status_code == 404:
        response_404 = Error.from_dict(response.json())

        return response_404

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[BucketAccessGroupList | Error]:
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
) -> Response[BucketAccessGroupList | Error]:
    """List access groups in a bucket

    Args:
        bucket_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[BucketAccessGroupList | Error]
    """

    kwargs = _get_kwargs(
        bucket_id=bucket_id,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    bucket_id: str,
    *,
    client: AuthenticatedClient,
) -> BucketAccessGroupList | Error | None:
    """List access groups in a bucket

    Args:
        bucket_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        BucketAccessGroupList | Error
    """

    return sync_detailed(
        bucket_id=bucket_id,
        client=client,
    ).parsed


async def asyncio_detailed(
    bucket_id: str,
    *,
    client: AuthenticatedClient,
) -> Response[BucketAccessGroupList | Error]:
    """List access groups in a bucket

    Args:
        bucket_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[BucketAccessGroupList | Error]
    """

    kwargs = _get_kwargs(
        bucket_id=bucket_id,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    bucket_id: str,
    *,
    client: AuthenticatedClient,
) -> BucketAccessGroupList | Error | None:
    """List access groups in a bucket

    Args:
        bucket_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        BucketAccessGroupList | Error
    """

    return (
        await asyncio_detailed(
            bucket_id=bucket_id,
            client=client,
        )
    ).parsed
