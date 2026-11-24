from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.integration_action_album_create import IntegrationActionAlbumCreate
from ...models.integration_action_album_remove_items import IntegrationActionAlbumRemoveItems
from ...models.integration_action_album_update import IntegrationActionAlbumUpdate
from ...models.integration_action_broadcast import IntegrationActionBroadcast
from ...models.integration_action_broadcast_send import IntegrationActionBroadcastSend
from ...models.integration_action_comment import IntegrationActionComment
from ...models.integration_action_import_picked import IntegrationActionImportPicked
from ...models.integration_action_label_create import IntegrationActionLabelCreate
from ...models.integration_action_label_delete import IntegrationActionLabelDelete
from ...models.integration_action_label_update import IntegrationActionLabelUpdate
from ...models.integration_action_modify_labels import IntegrationActionModifyLabels
from ...models.integration_action_post import IntegrationActionPost
from ...models.integration_action_send import IntegrationActionSend
from ...models.integration_action_sms import IntegrationActionSms
from ...models.integration_action_submit import IntegrationActionSubmit
from ...models.integration_action_subscribe import IntegrationActionSubscribe
from ...models.integration_action_unsubscribe import IntegrationActionUnsubscribe
from ...models.integration_action_upload import IntegrationActionUpload
from ...models.post_v1_integrations_connections_by_id_actions_by_action_type_response_200 import (
    PostV1IntegrationsConnectionsByIdActionsByActionTypeResponse200,
)
from ...models.stripe_error import StripeError
from ...types import Response


def _get_kwargs(
    id: str,
    action_type: str,
    *,
    body: IntegrationActionAlbumCreate
    | IntegrationActionAlbumRemoveItems
    | IntegrationActionAlbumUpdate
    | IntegrationActionBroadcast
    | IntegrationActionBroadcastSend
    | IntegrationActionComment
    | IntegrationActionImportPicked
    | IntegrationActionLabelCreate
    | IntegrationActionLabelDelete
    | IntegrationActionLabelUpdate
    | IntegrationActionModifyLabels
    | IntegrationActionPost
    | IntegrationActionSend
    | IntegrationActionSms
    | IntegrationActionSubmit
    | IntegrationActionSubscribe
    | IntegrationActionUnsubscribe
    | IntegrationActionUpload,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/integrations/connections/{id}/actions/{action_type}".format(
            id=quote(str(id), safe=""),
            action_type=quote(str(action_type), safe=""),
        ),
    }

    if (
        isinstance(body, IntegrationActionSend)
        or isinstance(body, IntegrationActionPost)
        or isinstance(body, IntegrationActionSms)
        or isinstance(body, IntegrationActionSubmit)
        or isinstance(body, IntegrationActionComment)
        or isinstance(body, IntegrationActionSubscribe)
        or isinstance(body, IntegrationActionUnsubscribe)
        or isinstance(body, IntegrationActionBroadcast)
        or isinstance(body, IntegrationActionBroadcastSend)
        or isinstance(body, IntegrationActionLabelCreate)
        or isinstance(body, IntegrationActionLabelUpdate)
        or isinstance(body, IntegrationActionLabelDelete)
        or isinstance(body, IntegrationActionModifyLabels)
        or isinstance(body, IntegrationActionAlbumCreate)
        or isinstance(body, IntegrationActionAlbumUpdate)
        or isinstance(body, IntegrationActionAlbumRemoveItems)
        or isinstance(body, IntegrationActionUpload)
    ):
        _kwargs["json"] = body.to_dict()
    else:
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostV1IntegrationsConnectionsByIdActionsByActionTypeResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = PostV1IntegrationsConnectionsByIdActionsByActionTypeResponse200.from_dict(
            response.json()
        )

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

    if response.status_code == 422:
        response_422 = StripeError.from_dict(response.json())

        return response_422

    if response.status_code == 503:
        response_503 = StripeError.from_dict(response.json())

        return response_503

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[PostV1IntegrationsConnectionsByIdActionsByActionTypeResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    id: str,
    action_type: str,
    *,
    client: AuthenticatedClient,
    body: IntegrationActionAlbumCreate
    | IntegrationActionAlbumRemoveItems
    | IntegrationActionAlbumUpdate
    | IntegrationActionBroadcast
    | IntegrationActionBroadcastSend
    | IntegrationActionComment
    | IntegrationActionImportPicked
    | IntegrationActionLabelCreate
    | IntegrationActionLabelDelete
    | IntegrationActionLabelUpdate
    | IntegrationActionModifyLabels
    | IntegrationActionPost
    | IntegrationActionSend
    | IntegrationActionSms
    | IntegrationActionSubmit
    | IntegrationActionSubscribe
    | IntegrationActionUnsubscribe
    | IntegrationActionUpload,
) -> Response[PostV1IntegrationsConnectionsByIdActionsByActionTypeResponse200 | StripeError]:
    """Act as the user on one of their connections

     Same actions and payloads as the operator route. Unlike it, the response carries the action's raw
    `result`. An optional `Idempotency-Key` header collapses a repeat onto the first row.

    Replaces POST /integrations/me/connections/{id}/actions/{actionType}, POST
    /integrations/{connectionId}/actions/{actionType}.

    Args:
        id (str):
        action_type (str):
        body (IntegrationActionAlbumCreate | IntegrationActionAlbumRemoveItems |
            IntegrationActionAlbumUpdate | IntegrationActionBroadcast | IntegrationActionBroadcastSend
            | IntegrationActionComment | IntegrationActionImportPicked | IntegrationActionLabelCreate
            | IntegrationActionLabelDelete | IntegrationActionLabelUpdate |
            IntegrationActionModifyLabels | IntegrationActionPost | IntegrationActionSend |
            IntegrationActionSms | IntegrationActionSubmit | IntegrationActionSubscribe |
            IntegrationActionUnsubscribe | IntegrationActionUpload):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1IntegrationsConnectionsByIdActionsByActionTypeResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
        action_type=action_type,
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    action_type: str,
    *,
    client: AuthenticatedClient,
    body: IntegrationActionAlbumCreate
    | IntegrationActionAlbumRemoveItems
    | IntegrationActionAlbumUpdate
    | IntegrationActionBroadcast
    | IntegrationActionBroadcastSend
    | IntegrationActionComment
    | IntegrationActionImportPicked
    | IntegrationActionLabelCreate
    | IntegrationActionLabelDelete
    | IntegrationActionLabelUpdate
    | IntegrationActionModifyLabels
    | IntegrationActionPost
    | IntegrationActionSend
    | IntegrationActionSms
    | IntegrationActionSubmit
    | IntegrationActionSubscribe
    | IntegrationActionUnsubscribe
    | IntegrationActionUpload,
) -> PostV1IntegrationsConnectionsByIdActionsByActionTypeResponse200 | StripeError | None:
    """Act as the user on one of their connections

     Same actions and payloads as the operator route. Unlike it, the response carries the action's raw
    `result`. An optional `Idempotency-Key` header collapses a repeat onto the first row.

    Replaces POST /integrations/me/connections/{id}/actions/{actionType}, POST
    /integrations/{connectionId}/actions/{actionType}.

    Args:
        id (str):
        action_type (str):
        body (IntegrationActionAlbumCreate | IntegrationActionAlbumRemoveItems |
            IntegrationActionAlbumUpdate | IntegrationActionBroadcast | IntegrationActionBroadcastSend
            | IntegrationActionComment | IntegrationActionImportPicked | IntegrationActionLabelCreate
            | IntegrationActionLabelDelete | IntegrationActionLabelUpdate |
            IntegrationActionModifyLabels | IntegrationActionPost | IntegrationActionSend |
            IntegrationActionSms | IntegrationActionSubmit | IntegrationActionSubscribe |
            IntegrationActionUnsubscribe | IntegrationActionUpload):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1IntegrationsConnectionsByIdActionsByActionTypeResponse200 | StripeError
    """

    return sync_detailed(
        id=id,
        action_type=action_type,
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    id: str,
    action_type: str,
    *,
    client: AuthenticatedClient,
    body: IntegrationActionAlbumCreate
    | IntegrationActionAlbumRemoveItems
    | IntegrationActionAlbumUpdate
    | IntegrationActionBroadcast
    | IntegrationActionBroadcastSend
    | IntegrationActionComment
    | IntegrationActionImportPicked
    | IntegrationActionLabelCreate
    | IntegrationActionLabelDelete
    | IntegrationActionLabelUpdate
    | IntegrationActionModifyLabels
    | IntegrationActionPost
    | IntegrationActionSend
    | IntegrationActionSms
    | IntegrationActionSubmit
    | IntegrationActionSubscribe
    | IntegrationActionUnsubscribe
    | IntegrationActionUpload,
) -> Response[PostV1IntegrationsConnectionsByIdActionsByActionTypeResponse200 | StripeError]:
    """Act as the user on one of their connections

     Same actions and payloads as the operator route. Unlike it, the response carries the action's raw
    `result`. An optional `Idempotency-Key` header collapses a repeat onto the first row.

    Replaces POST /integrations/me/connections/{id}/actions/{actionType}, POST
    /integrations/{connectionId}/actions/{actionType}.

    Args:
        id (str):
        action_type (str):
        body (IntegrationActionAlbumCreate | IntegrationActionAlbumRemoveItems |
            IntegrationActionAlbumUpdate | IntegrationActionBroadcast | IntegrationActionBroadcastSend
            | IntegrationActionComment | IntegrationActionImportPicked | IntegrationActionLabelCreate
            | IntegrationActionLabelDelete | IntegrationActionLabelUpdate |
            IntegrationActionModifyLabels | IntegrationActionPost | IntegrationActionSend |
            IntegrationActionSms | IntegrationActionSubmit | IntegrationActionSubscribe |
            IntegrationActionUnsubscribe | IntegrationActionUpload):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1IntegrationsConnectionsByIdActionsByActionTypeResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
        action_type=action_type,
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    action_type: str,
    *,
    client: AuthenticatedClient,
    body: IntegrationActionAlbumCreate
    | IntegrationActionAlbumRemoveItems
    | IntegrationActionAlbumUpdate
    | IntegrationActionBroadcast
    | IntegrationActionBroadcastSend
    | IntegrationActionComment
    | IntegrationActionImportPicked
    | IntegrationActionLabelCreate
    | IntegrationActionLabelDelete
    | IntegrationActionLabelUpdate
    | IntegrationActionModifyLabels
    | IntegrationActionPost
    | IntegrationActionSend
    | IntegrationActionSms
    | IntegrationActionSubmit
    | IntegrationActionSubscribe
    | IntegrationActionUnsubscribe
    | IntegrationActionUpload,
) -> PostV1IntegrationsConnectionsByIdActionsByActionTypeResponse200 | StripeError | None:
    """Act as the user on one of their connections

     Same actions and payloads as the operator route. Unlike it, the response carries the action's raw
    `result`. An optional `Idempotency-Key` header collapses a repeat onto the first row.

    Replaces POST /integrations/me/connections/{id}/actions/{actionType}, POST
    /integrations/{connectionId}/actions/{actionType}.

    Args:
        id (str):
        action_type (str):
        body (IntegrationActionAlbumCreate | IntegrationActionAlbumRemoveItems |
            IntegrationActionAlbumUpdate | IntegrationActionBroadcast | IntegrationActionBroadcastSend
            | IntegrationActionComment | IntegrationActionImportPicked | IntegrationActionLabelCreate
            | IntegrationActionLabelDelete | IntegrationActionLabelUpdate |
            IntegrationActionModifyLabels | IntegrationActionPost | IntegrationActionSend |
            IntegrationActionSms | IntegrationActionSubmit | IntegrationActionSubscribe |
            IntegrationActionUnsubscribe | IntegrationActionUpload):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1IntegrationsConnectionsByIdActionsByActionTypeResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            id=id,
            action_type=action_type,
            client=client,
            body=body,
        )
    ).parsed
