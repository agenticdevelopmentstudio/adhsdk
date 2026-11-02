from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.get_ownership_transfer_preview_entity_type import (
    GetOwnershipTransferPreviewEntityType,
)
from ...models.get_ownership_transfer_preview_response_200 import (
    GetOwnershipTransferPreviewResponse200,
)
from ...models.get_ownership_transfer_preview_target_kind import (
    GetOwnershipTransferPreviewTargetKind,
)
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    entity_type: GetOwnershipTransferPreviewEntityType,
    entity_id: str,
    target: str,
    target_kind: GetOwnershipTransferPreviewTargetKind | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    json_entity_type = entity_type.value
    params["entityType"] = json_entity_type

    params["entityId"] = entity_id

    params["target"] = target

    json_target_kind: str | Unset = UNSET
    if not isinstance(target_kind, Unset):
        json_target_kind = target_kind.value

    params["targetKind"] = json_target_kind

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/ownership/transfer/preview",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | GetOwnershipTransferPreviewResponse200 | None:
    if response.status_code == 200:
        response_200 = GetOwnershipTransferPreviewResponse200.from_dict(response.json())

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

    if response.status_code == 409:
        response_409 = Error.from_dict(response.json())

        return response_409

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | GetOwnershipTransferPreviewResponse200]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    entity_type: GetOwnershipTransferPreviewEntityType,
    entity_id: str,
    target: str,
    target_kind: GetOwnershipTransferPreviewTargetKind | Unset = UNSET,
) -> Response[Error | GetOwnershipTransferPreviewResponse200]:
    """What a transfer would do, without doing it

    Args:
        entity_type (GetOwnershipTransferPreviewEntityType): a transferable entity type, from the
            server’s TRANSFER_PLANS registry
        entity_id (str):
        target (str):
        target_kind (GetOwnershipTransferPreviewTargetKind | Unset): the namespace `target` names,
            when the client knows it

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GetOwnershipTransferPreviewResponse200]
    """

    kwargs = _get_kwargs(
        entity_type=entity_type,
        entity_id=entity_id,
        target=target,
        target_kind=target_kind,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    entity_type: GetOwnershipTransferPreviewEntityType,
    entity_id: str,
    target: str,
    target_kind: GetOwnershipTransferPreviewTargetKind | Unset = UNSET,
) -> Error | GetOwnershipTransferPreviewResponse200 | None:
    """What a transfer would do, without doing it

    Args:
        entity_type (GetOwnershipTransferPreviewEntityType): a transferable entity type, from the
            server’s TRANSFER_PLANS registry
        entity_id (str):
        target (str):
        target_kind (GetOwnershipTransferPreviewTargetKind | Unset): the namespace `target` names,
            when the client knows it

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GetOwnershipTransferPreviewResponse200
    """

    return sync_detailed(
        client=client,
        entity_type=entity_type,
        entity_id=entity_id,
        target=target,
        target_kind=target_kind,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    entity_type: GetOwnershipTransferPreviewEntityType,
    entity_id: str,
    target: str,
    target_kind: GetOwnershipTransferPreviewTargetKind | Unset = UNSET,
) -> Response[Error | GetOwnershipTransferPreviewResponse200]:
    """What a transfer would do, without doing it

    Args:
        entity_type (GetOwnershipTransferPreviewEntityType): a transferable entity type, from the
            server’s TRANSFER_PLANS registry
        entity_id (str):
        target (str):
        target_kind (GetOwnershipTransferPreviewTargetKind | Unset): the namespace `target` names,
            when the client knows it

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GetOwnershipTransferPreviewResponse200]
    """

    kwargs = _get_kwargs(
        entity_type=entity_type,
        entity_id=entity_id,
        target=target,
        target_kind=target_kind,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    entity_type: GetOwnershipTransferPreviewEntityType,
    entity_id: str,
    target: str,
    target_kind: GetOwnershipTransferPreviewTargetKind | Unset = UNSET,
) -> Error | GetOwnershipTransferPreviewResponse200 | None:
    """What a transfer would do, without doing it

    Args:
        entity_type (GetOwnershipTransferPreviewEntityType): a transferable entity type, from the
            server’s TRANSFER_PLANS registry
        entity_id (str):
        target (str):
        target_kind (GetOwnershipTransferPreviewTargetKind | Unset): the namespace `target` names,
            when the client knows it

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GetOwnershipTransferPreviewResponse200
    """

    return (
        await asyncio_detailed(
            client=client,
            entity_type=entity_type,
            entity_id=entity_id,
            target=target,
            target_kind=target_kind,
        )
    ).parsed
