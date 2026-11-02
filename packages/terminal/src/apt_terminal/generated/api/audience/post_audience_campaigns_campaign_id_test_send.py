from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.post_audience_campaigns_campaign_id_test_send_response_200 import (
    PostAudienceCampaignsCampaignIdTestSendResponse200,
)
from ...models.test_send_body import TestSendBody
from ...types import UNSET, Response, Unset


def _get_kwargs(
    campaign_id: str,
    *,
    body: TestSendBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/audience/campaigns/{campaign_id}/test-send".format(
            campaign_id=quote(str(campaign_id), safe=""),
        ),
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | PostAudienceCampaignsCampaignIdTestSendResponse200 | None:
    if response.status_code == 200:
        response_200 = PostAudienceCampaignsCampaignIdTestSendResponse200.from_dict(response.json())

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

    if response.status_code == 502:
        response_502 = Error.from_dict(response.json())

        return response_502

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | PostAudienceCampaignsCampaignIdTestSendResponse200]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    campaign_id: str,
    *,
    client: AuthenticatedClient,
    body: TestSendBody | Unset = UNSET,
) -> Response[Error | PostAudienceCampaignsCampaignIdTestSendResponse200]:
    """Send one preview copy to an address of the caller's choosing

     The one endpoint in this feature that sends email synchronously, inside the request — an author-
    only, single-recipient preview that never touches the bulk queue. Never reachable by an acting
    (agent-on-behalf-of) principal. 409 when no email provider is connected, or when the address is a
    suppressed contact (bounced/complained/suppressed) — suppression applies to previews exactly as it
    does to a real send. 502 when the provider itself rejects the message.

    Args:
        campaign_id (str):
        body (TestSendBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PostAudienceCampaignsCampaignIdTestSendResponse200]
    """

    kwargs = _get_kwargs(
        campaign_id=campaign_id,
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    campaign_id: str,
    *,
    client: AuthenticatedClient,
    body: TestSendBody | Unset = UNSET,
) -> Error | PostAudienceCampaignsCampaignIdTestSendResponse200 | None:
    """Send one preview copy to an address of the caller's choosing

     The one endpoint in this feature that sends email synchronously, inside the request — an author-
    only, single-recipient preview that never touches the bulk queue. Never reachable by an acting
    (agent-on-behalf-of) principal. 409 when no email provider is connected, or when the address is a
    suppressed contact (bounced/complained/suppressed) — suppression applies to previews exactly as it
    does to a real send. 502 when the provider itself rejects the message.

    Args:
        campaign_id (str):
        body (TestSendBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PostAudienceCampaignsCampaignIdTestSendResponse200
    """

    return sync_detailed(
        campaign_id=campaign_id,
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    campaign_id: str,
    *,
    client: AuthenticatedClient,
    body: TestSendBody | Unset = UNSET,
) -> Response[Error | PostAudienceCampaignsCampaignIdTestSendResponse200]:
    """Send one preview copy to an address of the caller's choosing

     The one endpoint in this feature that sends email synchronously, inside the request — an author-
    only, single-recipient preview that never touches the bulk queue. Never reachable by an acting
    (agent-on-behalf-of) principal. 409 when no email provider is connected, or when the address is a
    suppressed contact (bounced/complained/suppressed) — suppression applies to previews exactly as it
    does to a real send. 502 when the provider itself rejects the message.

    Args:
        campaign_id (str):
        body (TestSendBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PostAudienceCampaignsCampaignIdTestSendResponse200]
    """

    kwargs = _get_kwargs(
        campaign_id=campaign_id,
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    campaign_id: str,
    *,
    client: AuthenticatedClient,
    body: TestSendBody | Unset = UNSET,
) -> Error | PostAudienceCampaignsCampaignIdTestSendResponse200 | None:
    """Send one preview copy to an address of the caller's choosing

     The one endpoint in this feature that sends email synchronously, inside the request — an author-
    only, single-recipient preview that never touches the bulk queue. Never reachable by an acting
    (agent-on-behalf-of) principal. 409 when no email provider is connected, or when the address is a
    suppressed contact (bounced/complained/suppressed) — suppression applies to previews exactly as it
    does to a real send. 502 when the provider itself rejects the message.

    Args:
        campaign_id (str):
        body (TestSendBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PostAudienceCampaignsCampaignIdTestSendResponse200
    """

    return (
        await asyncio_detailed(
            campaign_id=campaign_id,
            client=client,
            body=body,
        )
    ).parsed
