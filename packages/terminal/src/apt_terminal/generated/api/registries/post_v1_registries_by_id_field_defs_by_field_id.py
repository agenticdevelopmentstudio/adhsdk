from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.post_v1_registries_by_id_field_defs_by_field_id_body import (
    PostV1RegistriesByIdFieldDefsByFieldIdBody,
)
from ...models.post_v1_registries_by_id_field_defs_by_field_id_response_200 import (
    PostV1RegistriesByIdFieldDefsByFieldIdResponse200,
)
from ...models.stripe_error import StripeError
from ...types import Response


def _get_kwargs(
    id: str,
    field_id: str,
    *,
    body: PostV1RegistriesByIdFieldDefsByFieldIdBody,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/registries/{id}/field_defs/{field_id}".format(
            id=quote(str(id), safe=""),
            field_id=quote(str(field_id), safe=""),
        ),
    }

    _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostV1RegistriesByIdFieldDefsByFieldIdResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = PostV1RegistriesByIdFieldDefsByFieldIdResponse200.from_dict(response.json())

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

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[PostV1RegistriesByIdFieldDefsByFieldIdResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    id: str,
    field_id: str,
    *,
    client: AuthenticatedClient,
    body: PostV1RegistriesByIdFieldDefsByFieldIdBody,
) -> Response[PostV1RegistriesByIdFieldDefsByFieldIdResponse200 | StripeError]:
    """Update a field def (key/type immutable — a type change is a 400, a key change a no-op)

     Replaces PATCH /registry/registries/{id}/field-defs/{fieldId}.

    Args:
        id (str):
        field_id (str):
        body (PostV1RegistriesByIdFieldDefsByFieldIdBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1RegistriesByIdFieldDefsByFieldIdResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
        field_id=field_id,
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    field_id: str,
    *,
    client: AuthenticatedClient,
    body: PostV1RegistriesByIdFieldDefsByFieldIdBody,
) -> PostV1RegistriesByIdFieldDefsByFieldIdResponse200 | StripeError | None:
    """Update a field def (key/type immutable — a type change is a 400, a key change a no-op)

     Replaces PATCH /registry/registries/{id}/field-defs/{fieldId}.

    Args:
        id (str):
        field_id (str):
        body (PostV1RegistriesByIdFieldDefsByFieldIdBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1RegistriesByIdFieldDefsByFieldIdResponse200 | StripeError
    """

    return sync_detailed(
        id=id,
        field_id=field_id,
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    id: str,
    field_id: str,
    *,
    client: AuthenticatedClient,
    body: PostV1RegistriesByIdFieldDefsByFieldIdBody,
) -> Response[PostV1RegistriesByIdFieldDefsByFieldIdResponse200 | StripeError]:
    """Update a field def (key/type immutable — a type change is a 400, a key change a no-op)

     Replaces PATCH /registry/registries/{id}/field-defs/{fieldId}.

    Args:
        id (str):
        field_id (str):
        body (PostV1RegistriesByIdFieldDefsByFieldIdBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1RegistriesByIdFieldDefsByFieldIdResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
        field_id=field_id,
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    field_id: str,
    *,
    client: AuthenticatedClient,
    body: PostV1RegistriesByIdFieldDefsByFieldIdBody,
) -> PostV1RegistriesByIdFieldDefsByFieldIdResponse200 | StripeError | None:
    """Update a field def (key/type immutable — a type change is a 400, a key change a no-op)

     Replaces PATCH /registry/registries/{id}/field-defs/{fieldId}.

    Args:
        id (str):
        field_id (str):
        body (PostV1RegistriesByIdFieldDefsByFieldIdBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1RegistriesByIdFieldDefsByFieldIdResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            id=id,
            field_id=field_id,
            client=client,
            body=body,
        )
    ).parsed
