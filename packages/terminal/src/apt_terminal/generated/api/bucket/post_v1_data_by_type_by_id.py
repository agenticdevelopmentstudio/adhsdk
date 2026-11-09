from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.post_v1_data_by_type_by_id_body import PostV1DataByTypeByIdBody
from ...models.post_v1_data_by_type_by_id_response_200 import PostV1DataByTypeByIdResponse200
from ...models.stripe_error import StripeError
from ...types import UNSET, Response


def _get_kwargs(
    type_: str,
    id: str,
    *,
    body: PostV1DataByTypeByIdBody,
    as_type: str,
    as_id: str,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    params: dict[str, Any] = {}

    params["as_type"] = as_type

    params["as_id"] = as_id

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/data/{type_}/{id}".format(
            type_=quote(str(type_), safe=""),
            id=quote(str(id), safe=""),
        ),
        "params": params,
    }

    _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostV1DataByTypeByIdResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = PostV1DataByTypeByIdResponse200.from_dict(response.json())

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
) -> Response[PostV1DataByTypeByIdResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    type_: str,
    id: str,
    *,
    client: AuthenticatedClient,
    body: PostV1DataByTypeByIdBody,
    as_type: str,
    as_id: str,
) -> Response[PostV1DataByTypeByIdResponse200 | StripeError]:
    """Update a bucket-type row (acting as an app/persona)

     Replaces PUT /bucket/buckets/{bucketId}/types/{typeId}/rows/{rowId}.

    Args:
        type_ (str):
        id (str):
        as_type (str):
        as_id (str):
        body (PostV1DataByTypeByIdBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1DataByTypeByIdResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        type_=type_,
        id=id,
        body=body,
        as_type=as_type,
        as_id=as_id,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    type_: str,
    id: str,
    *,
    client: AuthenticatedClient,
    body: PostV1DataByTypeByIdBody,
    as_type: str,
    as_id: str,
) -> PostV1DataByTypeByIdResponse200 | StripeError | None:
    """Update a bucket-type row (acting as an app/persona)

     Replaces PUT /bucket/buckets/{bucketId}/types/{typeId}/rows/{rowId}.

    Args:
        type_ (str):
        id (str):
        as_type (str):
        as_id (str):
        body (PostV1DataByTypeByIdBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1DataByTypeByIdResponse200 | StripeError
    """

    return sync_detailed(
        type_=type_,
        id=id,
        client=client,
        body=body,
        as_type=as_type,
        as_id=as_id,
    ).parsed


async def asyncio_detailed(
    type_: str,
    id: str,
    *,
    client: AuthenticatedClient,
    body: PostV1DataByTypeByIdBody,
    as_type: str,
    as_id: str,
) -> Response[PostV1DataByTypeByIdResponse200 | StripeError]:
    """Update a bucket-type row (acting as an app/persona)

     Replaces PUT /bucket/buckets/{bucketId}/types/{typeId}/rows/{rowId}.

    Args:
        type_ (str):
        id (str):
        as_type (str):
        as_id (str):
        body (PostV1DataByTypeByIdBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1DataByTypeByIdResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        type_=type_,
        id=id,
        body=body,
        as_type=as_type,
        as_id=as_id,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    type_: str,
    id: str,
    *,
    client: AuthenticatedClient,
    body: PostV1DataByTypeByIdBody,
    as_type: str,
    as_id: str,
) -> PostV1DataByTypeByIdResponse200 | StripeError | None:
    """Update a bucket-type row (acting as an app/persona)

     Replaces PUT /bucket/buckets/{bucketId}/types/{typeId}/rows/{rowId}.

    Args:
        type_ (str):
        id (str):
        as_type (str):
        as_id (str):
        body (PostV1DataByTypeByIdBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1DataByTypeByIdResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            type_=type_,
            id=id,
            client=client,
            body=body,
            as_type=as_type,
            as_id=as_id,
        )
    ).parsed
