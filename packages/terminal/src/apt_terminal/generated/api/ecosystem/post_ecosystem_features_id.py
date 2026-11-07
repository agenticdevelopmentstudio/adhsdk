from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.post_ecosystem_features_id_body import PostEcosystemFeaturesIdBody
from ...models.post_ecosystem_features_id_response_201 import PostEcosystemFeaturesIdResponse201
from ...types import UNSET, Response, Unset


def _get_kwargs(
    id: str,
    *,
    body: PostEcosystemFeaturesIdBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/ecosystem/features/{id}".format(
            id=quote(str(id), safe=""),
        ),
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | PostEcosystemFeaturesIdResponse201 | None:
    if response.status_code == 201:
        response_201 = PostEcosystemFeaturesIdResponse201.from_dict(response.json())

        return response_201

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

    if response.status_code == 422:
        response_422 = Error.from_dict(response.json())

        return response_422

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | PostEcosystemFeaturesIdResponse201]:
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
    body: PostEcosystemFeaturesIdBody | Unset = UNSET,
) -> Response[Error | PostEcosystemFeaturesIdResponse201]:
    """Provision features onto the ecosystem

     Creates whatever each feature needs — the storage buckets, the system roles, the ecosystem’s Project
    — in ONE transaction, so a partial failure rolls back whole. A key that is already active is a no-
    op, not a conflict. Returns the ecosystem’s full feature list afterwards. 422 when the ecosystem has
    no workspace principal behind it and a requested feature needs one.

    Args:
        id (str):
        body (PostEcosystemFeaturesIdBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PostEcosystemFeaturesIdResponse201]
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
    body: PostEcosystemFeaturesIdBody | Unset = UNSET,
) -> Error | PostEcosystemFeaturesIdResponse201 | None:
    """Provision features onto the ecosystem

     Creates whatever each feature needs — the storage buckets, the system roles, the ecosystem’s Project
    — in ONE transaction, so a partial failure rolls back whole. A key that is already active is a no-
    op, not a conflict. Returns the ecosystem’s full feature list afterwards. 422 when the ecosystem has
    no workspace principal behind it and a requested feature needs one.

    Args:
        id (str):
        body (PostEcosystemFeaturesIdBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PostEcosystemFeaturesIdResponse201
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
    body: PostEcosystemFeaturesIdBody | Unset = UNSET,
) -> Response[Error | PostEcosystemFeaturesIdResponse201]:
    """Provision features onto the ecosystem

     Creates whatever each feature needs — the storage buckets, the system roles, the ecosystem’s Project
    — in ONE transaction, so a partial failure rolls back whole. A key that is already active is a no-
    op, not a conflict. Returns the ecosystem’s full feature list afterwards. 422 when the ecosystem has
    no workspace principal behind it and a requested feature needs one.

    Args:
        id (str):
        body (PostEcosystemFeaturesIdBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PostEcosystemFeaturesIdResponse201]
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
    body: PostEcosystemFeaturesIdBody | Unset = UNSET,
) -> Error | PostEcosystemFeaturesIdResponse201 | None:
    """Provision features onto the ecosystem

     Creates whatever each feature needs — the storage buckets, the system roles, the ecosystem’s Project
    — in ONE transaction, so a partial failure rolls back whole. A key that is already active is a no-
    op, not a conflict. Returns the ecosystem’s full feature list afterwards. 422 when the ecosystem has
    no workspace principal behind it and a requested feature needs one.

    Args:
        id (str):
        body (PostEcosystemFeaturesIdBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PostEcosystemFeaturesIdResponse201
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            body=body,
        )
    ).parsed
