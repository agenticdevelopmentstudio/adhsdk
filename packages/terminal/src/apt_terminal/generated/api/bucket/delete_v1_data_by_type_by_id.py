from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.deleted import Deleted
from ...models.stripe_error import StripeError
from ...types import UNSET, Response


def _get_kwargs(
    type_: str,
    id: str,
    *,
    bucket: str,
    as_type: str,
    as_id: str,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["bucket"] = bucket

    params["as_type"] = as_type

    params["as_id"] = as_id

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "delete",
        "url": "/v1/data/{type_}/{id}".format(
            type_=quote(str(type_), safe=""),
            id=quote(str(id), safe=""),
        ),
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Deleted | StripeError | None:
    if response.status_code == 200:
        response_200 = Deleted.from_dict(response.json())

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
) -> Response[Deleted | StripeError]:
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
    bucket: str,
    as_type: str,
    as_id: str,
) -> Response[Deleted | StripeError]:
    """Delete a bucket-type row (acting as an app/persona)

     Replaces DELETE /bucket/buckets/{bucketId}/types/{typeId}/rows/{rowId}.

    Args:
        type_ (str):
        id (str):
        bucket (str):
        as_type (str):
        as_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Deleted | StripeError]
    """

    kwargs = _get_kwargs(
        type_=type_,
        id=id,
        bucket=bucket,
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
    bucket: str,
    as_type: str,
    as_id: str,
) -> Deleted | StripeError | None:
    """Delete a bucket-type row (acting as an app/persona)

     Replaces DELETE /bucket/buckets/{bucketId}/types/{typeId}/rows/{rowId}.

    Args:
        type_ (str):
        id (str):
        bucket (str):
        as_type (str):
        as_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Deleted | StripeError
    """

    return sync_detailed(
        type_=type_,
        id=id,
        client=client,
        bucket=bucket,
        as_type=as_type,
        as_id=as_id,
    ).parsed


async def asyncio_detailed(
    type_: str,
    id: str,
    *,
    client: AuthenticatedClient,
    bucket: str,
    as_type: str,
    as_id: str,
) -> Response[Deleted | StripeError]:
    """Delete a bucket-type row (acting as an app/persona)

     Replaces DELETE /bucket/buckets/{bucketId}/types/{typeId}/rows/{rowId}.

    Args:
        type_ (str):
        id (str):
        bucket (str):
        as_type (str):
        as_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Deleted | StripeError]
    """

    kwargs = _get_kwargs(
        type_=type_,
        id=id,
        bucket=bucket,
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
    bucket: str,
    as_type: str,
    as_id: str,
) -> Deleted | StripeError | None:
    """Delete a bucket-type row (acting as an app/persona)

     Replaces DELETE /bucket/buckets/{bucketId}/types/{typeId}/rows/{rowId}.

    Args:
        type_ (str):
        id (str):
        bucket (str):
        as_type (str):
        as_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Deleted | StripeError
    """

    return (
        await asyncio_detailed(
            type_=type_,
            id=id,
            client=client,
            bucket=bucket,
            as_type=as_type,
            as_id=as_id,
        )
    ).parsed
