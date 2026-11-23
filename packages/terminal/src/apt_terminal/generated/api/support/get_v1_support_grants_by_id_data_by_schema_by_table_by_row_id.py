from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.get_v1_support_grants_by_id_data_by_schema_by_table_by_row_id_response_200 import (
    GetV1SupportGrantsByIdDataBySchemaByTableByRowIdResponse200,
)
from ...models.stripe_error import StripeError
from ...types import UNSET, Response, Unset


def _get_kwargs(
    id: str,
    schema: str,
    table: str,
    row_id: str,
    *,
    expand: list[str] | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    json_expand: list[str] | Unset = UNSET
    if not isinstance(expand, Unset):
        json_expand = expand

    params["expand[]"] = json_expand

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/v1/support/grants/{id}/data/{schema}/{table}/{row_id}".format(
            id=quote(str(id), safe=""),
            schema=quote(str(schema), safe=""),
            table=quote(str(table), safe=""),
            row_id=quote(str(row_id), safe=""),
        ),
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> GetV1SupportGrantsByIdDataBySchemaByTableByRowIdResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = GetV1SupportGrantsByIdDataBySchemaByTableByRowIdResponse200.from_dict(
            response.json()
        )

        return response_200

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
) -> Response[GetV1SupportGrantsByIdDataBySchemaByTableByRowIdResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    id: str,
    schema: str,
    table: str,
    row_id: str,
    *,
    client: AuthenticatedClient,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1SupportGrantsByIdDataBySchemaByTableByRowIdResponse200 | StripeError]:
    """One content row under a support grant

     The grant's grantee only, with aal 2 (403 otherwise). An operator's grant is read by the operator; a
    product admin's through the product's admin site. A grant that is not live is 403 with `error.code`
    `not_live`. Every request writes a row to the grant's read log before anything is read, and only
    rows in the grant's reach (the target and their personas) are returned, with the ownership key
    columns left out. A table keyed on more than one column has no row read (404).

    Replaces GET /support/grants/{id}/data/{schema}/{table}/{rowId}.

    Args:
        id (str):
        schema (str):
        table (str):
        row_id (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1SupportGrantsByIdDataBySchemaByTableByRowIdResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
        schema=schema,
        table=table,
        row_id=row_id,
        expand=expand,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    schema: str,
    table: str,
    row_id: str,
    *,
    client: AuthenticatedClient,
    expand: list[str] | Unset = UNSET,
) -> GetV1SupportGrantsByIdDataBySchemaByTableByRowIdResponse200 | StripeError | None:
    """One content row under a support grant

     The grant's grantee only, with aal 2 (403 otherwise). An operator's grant is read by the operator; a
    product admin's through the product's admin site. A grant that is not live is 403 with `error.code`
    `not_live`. Every request writes a row to the grant's read log before anything is read, and only
    rows in the grant's reach (the target and their personas) are returned, with the ownership key
    columns left out. A table keyed on more than one column has no row read (404).

    Replaces GET /support/grants/{id}/data/{schema}/{table}/{rowId}.

    Args:
        id (str):
        schema (str):
        table (str):
        row_id (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1SupportGrantsByIdDataBySchemaByTableByRowIdResponse200 | StripeError
    """

    return sync_detailed(
        id=id,
        schema=schema,
        table=table,
        row_id=row_id,
        client=client,
        expand=expand,
    ).parsed


async def asyncio_detailed(
    id: str,
    schema: str,
    table: str,
    row_id: str,
    *,
    client: AuthenticatedClient,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1SupportGrantsByIdDataBySchemaByTableByRowIdResponse200 | StripeError]:
    """One content row under a support grant

     The grant's grantee only, with aal 2 (403 otherwise). An operator's grant is read by the operator; a
    product admin's through the product's admin site. A grant that is not live is 403 with `error.code`
    `not_live`. Every request writes a row to the grant's read log before anything is read, and only
    rows in the grant's reach (the target and their personas) are returned, with the ownership key
    columns left out. A table keyed on more than one column has no row read (404).

    Replaces GET /support/grants/{id}/data/{schema}/{table}/{rowId}.

    Args:
        id (str):
        schema (str):
        table (str):
        row_id (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1SupportGrantsByIdDataBySchemaByTableByRowIdResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
        schema=schema,
        table=table,
        row_id=row_id,
        expand=expand,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    schema: str,
    table: str,
    row_id: str,
    *,
    client: AuthenticatedClient,
    expand: list[str] | Unset = UNSET,
) -> GetV1SupportGrantsByIdDataBySchemaByTableByRowIdResponse200 | StripeError | None:
    """One content row under a support grant

     The grant's grantee only, with aal 2 (403 otherwise). An operator's grant is read by the operator; a
    product admin's through the product's admin site. A grant that is not live is 403 with `error.code`
    `not_live`. Every request writes a row to the grant's read log before anything is read, and only
    rows in the grant's reach (the target and their personas) are returned, with the ownership key
    columns left out. A table keyed on more than one column has no row read (404).

    Replaces GET /support/grants/{id}/data/{schema}/{table}/{rowId}.

    Args:
        id (str):
        schema (str):
        table (str):
        row_id (str):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1SupportGrantsByIdDataBySchemaByTableByRowIdResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            id=id,
            schema=schema,
            table=table,
            row_id=row_id,
            client=client,
            expand=expand,
        )
    ).parsed
