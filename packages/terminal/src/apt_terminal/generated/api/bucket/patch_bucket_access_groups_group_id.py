from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.bucket_access_group import BucketAccessGroup
from ...models.error import Error
from ...models.patch_bucket_access_groups_group_id_body import PatchBucketAccessGroupsGroupIdBody
from ...types import UNSET, Response, Unset


def _get_kwargs(
    group_id: str,
    *,
    body: PatchBucketAccessGroupsGroupIdBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "patch",
        "url": "/bucket/access-groups/{group_id}".format(
            group_id=quote(str(group_id), safe=""),
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
    if response.status_code == 200:
        response_200 = BucketAccessGroup.from_dict(response.json())

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
) -> Response[BucketAccessGroup | Error]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    group_id: str,
    *,
    client: AuthenticatedClient,
    body: PatchBucketAccessGroupsGroupIdBody | Unset = UNSET,
) -> Response[BucketAccessGroup | Error]:
    """Rename / edit an access group

    Args:
        group_id (str):
        body (PatchBucketAccessGroupsGroupIdBody | Unset): At least one of name or description is
            required.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[BucketAccessGroup | Error]
    """

    kwargs = _get_kwargs(
        group_id=group_id,
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    group_id: str,
    *,
    client: AuthenticatedClient,
    body: PatchBucketAccessGroupsGroupIdBody | Unset = UNSET,
) -> BucketAccessGroup | Error | None:
    """Rename / edit an access group

    Args:
        group_id (str):
        body (PatchBucketAccessGroupsGroupIdBody | Unset): At least one of name or description is
            required.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        BucketAccessGroup | Error
    """

    return sync_detailed(
        group_id=group_id,
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    group_id: str,
    *,
    client: AuthenticatedClient,
    body: PatchBucketAccessGroupsGroupIdBody | Unset = UNSET,
) -> Response[BucketAccessGroup | Error]:
    """Rename / edit an access group

    Args:
        group_id (str):
        body (PatchBucketAccessGroupsGroupIdBody | Unset): At least one of name or description is
            required.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[BucketAccessGroup | Error]
    """

    kwargs = _get_kwargs(
        group_id=group_id,
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    group_id: str,
    *,
    client: AuthenticatedClient,
    body: PatchBucketAccessGroupsGroupIdBody | Unset = UNSET,
) -> BucketAccessGroup | Error | None:
    """Rename / edit an access group

    Args:
        group_id (str):
        body (PatchBucketAccessGroupsGroupIdBody | Unset): At least one of name or description is
            required.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        BucketAccessGroup | Error
    """

    return (
        await asyncio_detailed(
            group_id=group_id,
            client=client,
            body=body,
        )
    ).parsed
