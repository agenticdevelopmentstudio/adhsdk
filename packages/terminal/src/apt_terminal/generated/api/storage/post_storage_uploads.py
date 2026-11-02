from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.post_storage_uploads_body import PostStorageUploadsBody
from ...models.storage_deduplicated import StorageDeduplicated
from ...models.storage_presigned_upload import StoragePresignedUpload
from ...models.storage_quota_exceeded import StorageQuotaExceeded
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    body: PostStorageUploadsBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/storage/uploads",
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | StorageDeduplicated | StoragePresignedUpload | StorageQuotaExceeded | None:
    if response.status_code == 200:
        response_200 = StorageDeduplicated.from_dict(response.json())

        return response_200

    if response.status_code == 201:
        response_201 = StoragePresignedUpload.from_dict(response.json())

        return response_201

    if response.status_code == 400:
        response_400 = Error.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = Error.from_dict(response.json())

        return response_401

    if response.status_code == 413:
        response_413 = StorageQuotaExceeded.from_dict(response.json())

        return response_413

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | StorageDeduplicated | StoragePresignedUpload | StorageQuotaExceeded]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    body: PostStorageUploadsBody | Unset = UNSET,
) -> Response[Error | StorageDeduplicated | StoragePresignedUpload | StorageQuotaExceeded]:
    """Begin an upload: reserve an attachment + presigned PUT URL

    Args:
        body (PostStorageUploadsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | StorageDeduplicated | StoragePresignedUpload | StorageQuotaExceeded]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    body: PostStorageUploadsBody | Unset = UNSET,
) -> Error | StorageDeduplicated | StoragePresignedUpload | StorageQuotaExceeded | None:
    """Begin an upload: reserve an attachment + presigned PUT URL

    Args:
        body (PostStorageUploadsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | StorageDeduplicated | StoragePresignedUpload | StorageQuotaExceeded
    """

    return sync_detailed(
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    body: PostStorageUploadsBody | Unset = UNSET,
) -> Response[Error | StorageDeduplicated | StoragePresignedUpload | StorageQuotaExceeded]:
    """Begin an upload: reserve an attachment + presigned PUT URL

    Args:
        body (PostStorageUploadsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | StorageDeduplicated | StoragePresignedUpload | StorageQuotaExceeded]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    body: PostStorageUploadsBody | Unset = UNSET,
) -> Error | StorageDeduplicated | StoragePresignedUpload | StorageQuotaExceeded | None:
    """Begin an upload: reserve an attachment + presigned PUT URL

    Args:
        body (PostStorageUploadsBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | StorageDeduplicated | StoragePresignedUpload | StorageQuotaExceeded
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
        )
    ).parsed
