from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.post_v1_ecosystems_by_id_features_body import PostV1EcosystemsByIdFeaturesBody
from ...models.post_v1_ecosystems_by_id_features_response_201 import (
    PostV1EcosystemsByIdFeaturesResponse201,
)
from ...models.stripe_error import StripeError
from ...types import Response


def _get_kwargs(
    id: str,
    *,
    body: PostV1EcosystemsByIdFeaturesBody,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/ecosystems/{id}/features".format(
            id=quote(str(id), safe=""),
        ),
    }

    _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostV1EcosystemsByIdFeaturesResponse201 | StripeError | None:
    if response.status_code == 201:
        response_201 = PostV1EcosystemsByIdFeaturesResponse201.from_dict(response.json())

        return response_201

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

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[PostV1EcosystemsByIdFeaturesResponse201 | StripeError]:
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
    body: PostV1EcosystemsByIdFeaturesBody,
) -> Response[PostV1EcosystemsByIdFeaturesResponse201 | StripeError]:
    """Provision features onto the ecosystem

     Creates whatever each feature needs — the storage buckets, the system roles, the ecosystem’s Project
    — in ONE transaction, so a partial failure rolls back whole. A key that is already active is a no-
    op, not a conflict. Returns the ecosystem’s full feature list afterwards. 422 when the ecosystem has
    no workspace principal behind it and a requested feature needs one.

    Replaces POST /ecosystem/features/{id}.

    Args:
        id (str):
        body (PostV1EcosystemsByIdFeaturesBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1EcosystemsByIdFeaturesResponse201 | StripeError]
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
    body: PostV1EcosystemsByIdFeaturesBody,
) -> PostV1EcosystemsByIdFeaturesResponse201 | StripeError | None:
    """Provision features onto the ecosystem

     Creates whatever each feature needs — the storage buckets, the system roles, the ecosystem’s Project
    — in ONE transaction, so a partial failure rolls back whole. A key that is already active is a no-
    op, not a conflict. Returns the ecosystem’s full feature list afterwards. 422 when the ecosystem has
    no workspace principal behind it and a requested feature needs one.

    Replaces POST /ecosystem/features/{id}.

    Args:
        id (str):
        body (PostV1EcosystemsByIdFeaturesBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1EcosystemsByIdFeaturesResponse201 | StripeError
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
    body: PostV1EcosystemsByIdFeaturesBody,
) -> Response[PostV1EcosystemsByIdFeaturesResponse201 | StripeError]:
    """Provision features onto the ecosystem

     Creates whatever each feature needs — the storage buckets, the system roles, the ecosystem’s Project
    — in ONE transaction, so a partial failure rolls back whole. A key that is already active is a no-
    op, not a conflict. Returns the ecosystem’s full feature list afterwards. 422 when the ecosystem has
    no workspace principal behind it and a requested feature needs one.

    Replaces POST /ecosystem/features/{id}.

    Args:
        id (str):
        body (PostV1EcosystemsByIdFeaturesBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1EcosystemsByIdFeaturesResponse201 | StripeError]
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
    body: PostV1EcosystemsByIdFeaturesBody,
) -> PostV1EcosystemsByIdFeaturesResponse201 | StripeError | None:
    """Provision features onto the ecosystem

     Creates whatever each feature needs — the storage buckets, the system roles, the ecosystem’s Project
    — in ONE transaction, so a partial failure rolls back whole. A key that is already active is a no-
    op, not a conflict. Returns the ecosystem’s full feature list afterwards. 422 when the ecosystem has
    no workspace principal behind it and a requested feature needs one.

    Replaces POST /ecosystem/features/{id}.

    Args:
        id (str):
        body (PostV1EcosystemsByIdFeaturesBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1EcosystemsByIdFeaturesResponse201 | StripeError
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            body=body,
        )
    ).parsed
