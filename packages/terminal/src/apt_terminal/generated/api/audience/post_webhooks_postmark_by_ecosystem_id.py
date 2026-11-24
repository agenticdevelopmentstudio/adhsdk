from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.legacy_error import LegacyError
from ...models.legacy_postmark_deliverability_event import LegacyPostmarkDeliverabilityEvent
from ...models.post_webhooks_postmark_by_ecosystem_id_response_200 import (
    PostWebhooksPostmarkByEcosystemIdResponse200,
)
from ...types import Response


def _get_kwargs(
    ecosystem_id: str,
    *,
    body: LegacyPostmarkDeliverabilityEvent,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/webhooks/postmark/{ecosystem_id}".format(
            ecosystem_id=quote(str(ecosystem_id), safe=""),
        ),
    }

    _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> LegacyError | PostWebhooksPostmarkByEcosystemIdResponse200 | None:
    if response.status_code == 200:
        response_200 = PostWebhooksPostmarkByEcosystemIdResponse200.from_dict(response.json())

        return response_200

    if response.status_code == 400:
        response_400 = LegacyError.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = LegacyError.from_dict(response.json())

        return response_401

    if response.status_code == 403:
        response_403 = LegacyError.from_dict(response.json())

        return response_403

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[LegacyError | PostWebhooksPostmarkByEcosystemIdResponse200]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    ecosystem_id: str,
    *,
    client: AuthenticatedClient | Client,
    body: LegacyPostmarkDeliverabilityEvent,
) -> Response[LegacyError | PostWebhooksPostmarkByEcosystemIdResponse200]:
    """Deliverability events from Postmark (per-ecosystem secret header, not a JWT)

     Replaces POST /public/webhooks/postmark/{ecosystemId}.

    Args:
        ecosystem_id (str):
        body (LegacyPostmarkDeliverabilityEvent):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[LegacyError | PostWebhooksPostmarkByEcosystemIdResponse200]
    """

    kwargs = _get_kwargs(
        ecosystem_id=ecosystem_id,
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    ecosystem_id: str,
    *,
    client: AuthenticatedClient | Client,
    body: LegacyPostmarkDeliverabilityEvent,
) -> LegacyError | PostWebhooksPostmarkByEcosystemIdResponse200 | None:
    """Deliverability events from Postmark (per-ecosystem secret header, not a JWT)

     Replaces POST /public/webhooks/postmark/{ecosystemId}.

    Args:
        ecosystem_id (str):
        body (LegacyPostmarkDeliverabilityEvent):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        LegacyError | PostWebhooksPostmarkByEcosystemIdResponse200
    """

    return sync_detailed(
        ecosystem_id=ecosystem_id,
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    ecosystem_id: str,
    *,
    client: AuthenticatedClient | Client,
    body: LegacyPostmarkDeliverabilityEvent,
) -> Response[LegacyError | PostWebhooksPostmarkByEcosystemIdResponse200]:
    """Deliverability events from Postmark (per-ecosystem secret header, not a JWT)

     Replaces POST /public/webhooks/postmark/{ecosystemId}.

    Args:
        ecosystem_id (str):
        body (LegacyPostmarkDeliverabilityEvent):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[LegacyError | PostWebhooksPostmarkByEcosystemIdResponse200]
    """

    kwargs = _get_kwargs(
        ecosystem_id=ecosystem_id,
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    ecosystem_id: str,
    *,
    client: AuthenticatedClient | Client,
    body: LegacyPostmarkDeliverabilityEvent,
) -> LegacyError | PostWebhooksPostmarkByEcosystemIdResponse200 | None:
    """Deliverability events from Postmark (per-ecosystem secret header, not a JWT)

     Replaces POST /public/webhooks/postmark/{ecosystemId}.

    Args:
        ecosystem_id (str):
        body (LegacyPostmarkDeliverabilityEvent):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        LegacyError | PostWebhooksPostmarkByEcosystemIdResponse200
    """

    return (
        await asyncio_detailed(
            ecosystem_id=ecosystem_id,
            client=client,
            body=body,
        )
    ).parsed
