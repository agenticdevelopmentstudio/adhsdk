from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.post_v1_audience_campaigns_by_id_send_test_response_200 import (
    PostV1AudienceCampaignsByIdSendTestResponse200,
)
from ...models.stripe_error import StripeError
from ...models.test_send_body import TestSendBody
from ...types import Response


def _get_kwargs(
    id: str,
    *,
    body: TestSendBody,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/audience/campaigns/{id}/send_test".format(
            id=quote(str(id), safe=""),
        ),
    }

    _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostV1AudienceCampaignsByIdSendTestResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = PostV1AudienceCampaignsByIdSendTestResponse200.from_dict(response.json())

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

    if response.status_code == 502:
        response_502 = StripeError.from_dict(response.json())

        return response_502

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[PostV1AudienceCampaignsByIdSendTestResponse200 | StripeError]:
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
    body: TestSendBody,
) -> Response[PostV1AudienceCampaignsByIdSendTestResponse200 | StripeError]:
    """Send one preview copy to an address of the caller's choosing

     The one endpoint in this feature that sends email synchronously, inside the request — an author-
    only, single-recipient preview that never touches the bulk queue. Never reachable by an acting
    (agent-on-behalf-of) principal. 409 when no email provider is connected, or when the address is a
    suppressed contact (bounced/complained/suppressed) — suppression applies to previews exactly as it
    does to a real send. 502 when the provider itself rejects the message.

    Replaces POST /audience/campaigns/{campaignId}/test-send.

    Args:
        id (str):
        body (TestSendBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1AudienceCampaignsByIdSendTestResponse200 | StripeError]
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
    body: TestSendBody,
) -> PostV1AudienceCampaignsByIdSendTestResponse200 | StripeError | None:
    """Send one preview copy to an address of the caller's choosing

     The one endpoint in this feature that sends email synchronously, inside the request — an author-
    only, single-recipient preview that never touches the bulk queue. Never reachable by an acting
    (agent-on-behalf-of) principal. 409 when no email provider is connected, or when the address is a
    suppressed contact (bounced/complained/suppressed) — suppression applies to previews exactly as it
    does to a real send. 502 when the provider itself rejects the message.

    Replaces POST /audience/campaigns/{campaignId}/test-send.

    Args:
        id (str):
        body (TestSendBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1AudienceCampaignsByIdSendTestResponse200 | StripeError
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
    body: TestSendBody,
) -> Response[PostV1AudienceCampaignsByIdSendTestResponse200 | StripeError]:
    """Send one preview copy to an address of the caller's choosing

     The one endpoint in this feature that sends email synchronously, inside the request — an author-
    only, single-recipient preview that never touches the bulk queue. Never reachable by an acting
    (agent-on-behalf-of) principal. 409 when no email provider is connected, or when the address is a
    suppressed contact (bounced/complained/suppressed) — suppression applies to previews exactly as it
    does to a real send. 502 when the provider itself rejects the message.

    Replaces POST /audience/campaigns/{campaignId}/test-send.

    Args:
        id (str):
        body (TestSendBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1AudienceCampaignsByIdSendTestResponse200 | StripeError]
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
    body: TestSendBody,
) -> PostV1AudienceCampaignsByIdSendTestResponse200 | StripeError | None:
    """Send one preview copy to an address of the caller's choosing

     The one endpoint in this feature that sends email synchronously, inside the request — an author-
    only, single-recipient preview that never touches the bulk queue. Never reachable by an acting
    (agent-on-behalf-of) principal. 409 when no email provider is connected, or when the address is a
    suppressed contact (bounced/complained/suppressed) — suppression applies to previews exactly as it
    does to a real send. 502 when the provider itself rejects the message.

    Replaces POST /audience/campaigns/{campaignId}/test-send.

    Args:
        id (str):
        body (TestSendBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1AudienceCampaignsByIdSendTestResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            body=body,
        )
    ).parsed
