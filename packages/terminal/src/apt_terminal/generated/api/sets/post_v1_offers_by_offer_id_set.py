from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.offer_set_put import OfferSetPut
from ...models.post_v1_offers_by_offer_id_set_response_200 import (
    PostV1OffersByOfferIdSetResponse200,
)
from ...models.stripe_error import StripeError
from ...types import Response


def _get_kwargs(
    offer_id: str,
    *,
    body: OfferSetPut,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/offers/{offer_id}/set".format(
            offer_id=quote(str(offer_id), safe=""),
        ),
    }

    _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostV1OffersByOfferIdSetResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = PostV1OffersByOfferIdSetResponse200.from_dict(response.json())

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

    if response.status_code == 422:
        response_422 = StripeError.from_dict(response.json())

        return response_422

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[PostV1OffersByOfferIdSetResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    offer_id: str,
    *,
    client: AuthenticatedClient,
    body: OfferSetPut,
) -> Response[PostV1OffersByOfferIdSetResponse200 | StripeError]:
    """Set the set an offer sells

     null stops the offer granting a set. Refused (rule 9) when the set conflicts with another live
    offer's set; a personal set is never sold (400). A product admin, signed in through the product's
    admin site, is refused (403): what an offer sells is billing.

    Replaces PUT /sets/offers/{offerId}.

    Args:
        offer_id (str):
        body (OfferSetPut):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1OffersByOfferIdSetResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        offer_id=offer_id,
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    offer_id: str,
    *,
    client: AuthenticatedClient,
    body: OfferSetPut,
) -> PostV1OffersByOfferIdSetResponse200 | StripeError | None:
    """Set the set an offer sells

     null stops the offer granting a set. Refused (rule 9) when the set conflicts with another live
    offer's set; a personal set is never sold (400). A product admin, signed in through the product's
    admin site, is refused (403): what an offer sells is billing.

    Replaces PUT /sets/offers/{offerId}.

    Args:
        offer_id (str):
        body (OfferSetPut):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1OffersByOfferIdSetResponse200 | StripeError
    """

    return sync_detailed(
        offer_id=offer_id,
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    offer_id: str,
    *,
    client: AuthenticatedClient,
    body: OfferSetPut,
) -> Response[PostV1OffersByOfferIdSetResponse200 | StripeError]:
    """Set the set an offer sells

     null stops the offer granting a set. Refused (rule 9) when the set conflicts with another live
    offer's set; a personal set is never sold (400). A product admin, signed in through the product's
    admin site, is refused (403): what an offer sells is billing.

    Replaces PUT /sets/offers/{offerId}.

    Args:
        offer_id (str):
        body (OfferSetPut):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1OffersByOfferIdSetResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        offer_id=offer_id,
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    offer_id: str,
    *,
    client: AuthenticatedClient,
    body: OfferSetPut,
) -> PostV1OffersByOfferIdSetResponse200 | StripeError | None:
    """Set the set an offer sells

     null stops the offer granting a set. Refused (rule 9) when the set conflicts with another live
    offer's set; a personal set is never sold (400). A product admin, signed in through the product's
    admin site, is refused (403): what an offer sells is billing.

    Replaces PUT /sets/offers/{offerId}.

    Args:
        offer_id (str):
        body (OfferSetPut):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1OffersByOfferIdSetResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            offer_id=offer_id,
            client=client,
            body=body,
        )
    ).parsed
