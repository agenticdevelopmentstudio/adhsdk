from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.get_v1_ownership_transfers_preview_entity_type import (
    GetV1OwnershipTransfersPreviewEntityType,
)
from ...models.get_v1_ownership_transfers_preview_response_200 import (
    GetV1OwnershipTransfersPreviewResponse200,
)
from ...models.get_v1_ownership_transfers_preview_target_kind import (
    GetV1OwnershipTransfersPreviewTargetKind,
)
from ...models.stripe_error import StripeError
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    entity_type: GetV1OwnershipTransfersPreviewEntityType,
    entity_id: str,
    target: str,
    target_kind: GetV1OwnershipTransfersPreviewTargetKind | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    json_entity_type = entity_type.value
    params["entity_type"] = json_entity_type

    params["entity_id"] = entity_id

    params["target"] = target

    json_target_kind: str | Unset = UNSET
    if not isinstance(target_kind, Unset):
        json_target_kind = target_kind.value

    params["target_kind"] = json_target_kind

    json_expand: list[str] | Unset = UNSET
    if not isinstance(expand, Unset):
        json_expand = expand

    params["expand[]"] = json_expand

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/v1/ownership/transfers/preview",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> GetV1OwnershipTransfersPreviewResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = GetV1OwnershipTransfersPreviewResponse200.from_dict(response.json())

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

    if response.status_code == 409:
        response_409 = StripeError.from_dict(response.json())

        return response_409

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[GetV1OwnershipTransfersPreviewResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    entity_type: GetV1OwnershipTransfersPreviewEntityType,
    entity_id: str,
    target: str,
    target_kind: GetV1OwnershipTransfersPreviewTargetKind | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1OwnershipTransfersPreviewResponse200 | StripeError]:
    """What a transfer would do, without doing it

     Replaces GET /ownership/transfer/preview.

    Args:
        entity_type (GetV1OwnershipTransfersPreviewEntityType): a transferable entity type, from
            the server’s TRANSFER_PLANS registry
        entity_id (str):
        target (str):
        target_kind (GetV1OwnershipTransfersPreviewTargetKind | Unset): the namespace `target`
            names, when the client knows it
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1OwnershipTransfersPreviewResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        entity_type=entity_type,
        entity_id=entity_id,
        target=target,
        target_kind=target_kind,
        expand=expand,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    entity_type: GetV1OwnershipTransfersPreviewEntityType,
    entity_id: str,
    target: str,
    target_kind: GetV1OwnershipTransfersPreviewTargetKind | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> GetV1OwnershipTransfersPreviewResponse200 | StripeError | None:
    """What a transfer would do, without doing it

     Replaces GET /ownership/transfer/preview.

    Args:
        entity_type (GetV1OwnershipTransfersPreviewEntityType): a transferable entity type, from
            the server’s TRANSFER_PLANS registry
        entity_id (str):
        target (str):
        target_kind (GetV1OwnershipTransfersPreviewTargetKind | Unset): the namespace `target`
            names, when the client knows it
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1OwnershipTransfersPreviewResponse200 | StripeError
    """

    return sync_detailed(
        client=client,
        entity_type=entity_type,
        entity_id=entity_id,
        target=target,
        target_kind=target_kind,
        expand=expand,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    entity_type: GetV1OwnershipTransfersPreviewEntityType,
    entity_id: str,
    target: str,
    target_kind: GetV1OwnershipTransfersPreviewTargetKind | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1OwnershipTransfersPreviewResponse200 | StripeError]:
    """What a transfer would do, without doing it

     Replaces GET /ownership/transfer/preview.

    Args:
        entity_type (GetV1OwnershipTransfersPreviewEntityType): a transferable entity type, from
            the server’s TRANSFER_PLANS registry
        entity_id (str):
        target (str):
        target_kind (GetV1OwnershipTransfersPreviewTargetKind | Unset): the namespace `target`
            names, when the client knows it
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1OwnershipTransfersPreviewResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        entity_type=entity_type,
        entity_id=entity_id,
        target=target,
        target_kind=target_kind,
        expand=expand,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    entity_type: GetV1OwnershipTransfersPreviewEntityType,
    entity_id: str,
    target: str,
    target_kind: GetV1OwnershipTransfersPreviewTargetKind | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> GetV1OwnershipTransfersPreviewResponse200 | StripeError | None:
    """What a transfer would do, without doing it

     Replaces GET /ownership/transfer/preview.

    Args:
        entity_type (GetV1OwnershipTransfersPreviewEntityType): a transferable entity type, from
            the server’s TRANSFER_PLANS registry
        entity_id (str):
        target (str):
        target_kind (GetV1OwnershipTransfersPreviewTargetKind | Unset): the namespace `target`
            names, when the client knows it
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1OwnershipTransfersPreviewResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            client=client,
            entity_type=entity_type,
            entity_id=entity_id,
            target=target,
            target_kind=target_kind,
            expand=expand,
        )
    ).parsed
