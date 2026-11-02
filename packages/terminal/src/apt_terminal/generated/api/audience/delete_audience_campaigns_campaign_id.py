from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.delete_audience_campaigns_campaign_id_response_200 import (
    DeleteAudienceCampaignsCampaignIdResponse200,
)
from ...models.error import Error
from ...types import Response


def _get_kwargs(
    campaign_id: str,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "delete",
        "url": "/audience/campaigns/{campaign_id}".format(
            campaign_id=quote(str(campaign_id), safe=""),
        ),
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> DeleteAudienceCampaignsCampaignIdResponse200 | Error | None:
    if response.status_code == 200:
        response_200 = DeleteAudienceCampaignsCampaignIdResponse200.from_dict(response.json())

        return response_200

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
) -> Response[DeleteAudienceCampaignsCampaignIdResponse200 | Error]:
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
) -> Response[DeleteAudienceCampaignsCampaignIdResponse200 | Error]:
    """Delete a draft campaign

    Args:
        campaign_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[DeleteAudienceCampaignsCampaignIdResponse200 | Error]
    """

    kwargs = _get_kwargs(
        campaign_id=campaign_id,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    campaign_id: str,
    *,
    client: AuthenticatedClient,
) -> DeleteAudienceCampaignsCampaignIdResponse200 | Error | None:
    """Delete a draft campaign

    Args:
        campaign_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        DeleteAudienceCampaignsCampaignIdResponse200 | Error
    """

    return sync_detailed(
        campaign_id=campaign_id,
        client=client,
    ).parsed


async def asyncio_detailed(
    campaign_id: str,
    *,
    client: AuthenticatedClient,
) -> Response[DeleteAudienceCampaignsCampaignIdResponse200 | Error]:
    """Delete a draft campaign

    Args:
        campaign_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[DeleteAudienceCampaignsCampaignIdResponse200 | Error]
    """

    kwargs = _get_kwargs(
        campaign_id=campaign_id,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    campaign_id: str,
    *,
    client: AuthenticatedClient,
) -> DeleteAudienceCampaignsCampaignIdResponse200 | Error | None:
    """Delete a draft campaign

    Args:
        campaign_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        DeleteAudienceCampaignsCampaignIdResponse200 | Error
    """

    return (
        await asyncio_detailed(
            campaign_id=campaign_id,
            client=client,
        )
    ).parsed
