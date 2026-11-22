import datetime
from http import HTTPStatus
from typing import Any
from uuid import UUID

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.get_v1_system_operator_access_response_200 import (
    GetV1SystemOperatorAccessResponse200,
)
from ...models.stripe_error import StripeError
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    operator_account_id: UUID | Unset = UNSET,
    target_ecosystem_id: UUID | Unset = UNSET,
    from_: datetime.datetime | Unset = UNSET,
    to: datetime.datetime | Unset = UNSET,
    after: UUID | Unset = UNSET,
    limit: int | Unset = 10,
    starting_after: str | Unset = UNSET,
    ending_before: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    json_operator_account_id: str | Unset = UNSET
    if not isinstance(operator_account_id, Unset):
        json_operator_account_id = str(operator_account_id)
    params["operator_account_id"] = json_operator_account_id

    json_target_ecosystem_id: str | Unset = UNSET
    if not isinstance(target_ecosystem_id, Unset):
        json_target_ecosystem_id = str(target_ecosystem_id)
    params["target_ecosystem_id"] = json_target_ecosystem_id

    json_from_: str | Unset = UNSET
    if not isinstance(from_, Unset):
        json_from_ = from_.isoformat()
    params["from"] = json_from_

    json_to: str | Unset = UNSET
    if not isinstance(to, Unset):
        json_to = to.isoformat()
    params["to"] = json_to

    json_after: str | Unset = UNSET
    if not isinstance(after, Unset):
        json_after = str(after)
    params["after"] = json_after

    params["limit"] = limit

    params["starting_after"] = starting_after

    params["ending_before"] = ending_before

    json_expand: list[str] | Unset = UNSET
    if not isinstance(expand, Unset):
        json_expand = expand

    params["expand[]"] = json_expand

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/v1/system/operator_access",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> GetV1SystemOperatorAccessResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = GetV1SystemOperatorAccessResponse200.from_dict(response.json())

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

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[GetV1SystemOperatorAccessResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    operator_account_id: UUID | Unset = UNSET,
    target_ecosystem_id: UUID | Unset = UNSET,
    from_: datetime.datetime | Unset = UNSET,
    to: datetime.datetime | Unset = UNSET,
    after: UUID | Unset = UNSET,
    limit: int | Unset = 10,
    starting_after: str | Unset = UNSET,
    ending_before: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1SystemOperatorAccessResponse200 | StripeError]:
    """Admin-only operator access log (newest first, cursor-paged)

     Replaces GET /system/operator-access.

    Args:
        operator_account_id (UUID | Unset):
        target_ecosystem_id (UUID | Unset):
        from_ (datetime.datetime | Unset):
        to (datetime.datetime | Unset):
        after (UUID | Unset):
        limit (int | Unset):  Default: 10.
        starting_after (str | Unset):
        ending_before (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1SystemOperatorAccessResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        operator_account_id=operator_account_id,
        target_ecosystem_id=target_ecosystem_id,
        from_=from_,
        to=to,
        after=after,
        limit=limit,
        starting_after=starting_after,
        ending_before=ending_before,
        expand=expand,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    operator_account_id: UUID | Unset = UNSET,
    target_ecosystem_id: UUID | Unset = UNSET,
    from_: datetime.datetime | Unset = UNSET,
    to: datetime.datetime | Unset = UNSET,
    after: UUID | Unset = UNSET,
    limit: int | Unset = 10,
    starting_after: str | Unset = UNSET,
    ending_before: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> GetV1SystemOperatorAccessResponse200 | StripeError | None:
    """Admin-only operator access log (newest first, cursor-paged)

     Replaces GET /system/operator-access.

    Args:
        operator_account_id (UUID | Unset):
        target_ecosystem_id (UUID | Unset):
        from_ (datetime.datetime | Unset):
        to (datetime.datetime | Unset):
        after (UUID | Unset):
        limit (int | Unset):  Default: 10.
        starting_after (str | Unset):
        ending_before (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1SystemOperatorAccessResponse200 | StripeError
    """

    return sync_detailed(
        client=client,
        operator_account_id=operator_account_id,
        target_ecosystem_id=target_ecosystem_id,
        from_=from_,
        to=to,
        after=after,
        limit=limit,
        starting_after=starting_after,
        ending_before=ending_before,
        expand=expand,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    operator_account_id: UUID | Unset = UNSET,
    target_ecosystem_id: UUID | Unset = UNSET,
    from_: datetime.datetime | Unset = UNSET,
    to: datetime.datetime | Unset = UNSET,
    after: UUID | Unset = UNSET,
    limit: int | Unset = 10,
    starting_after: str | Unset = UNSET,
    ending_before: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1SystemOperatorAccessResponse200 | StripeError]:
    """Admin-only operator access log (newest first, cursor-paged)

     Replaces GET /system/operator-access.

    Args:
        operator_account_id (UUID | Unset):
        target_ecosystem_id (UUID | Unset):
        from_ (datetime.datetime | Unset):
        to (datetime.datetime | Unset):
        after (UUID | Unset):
        limit (int | Unset):  Default: 10.
        starting_after (str | Unset):
        ending_before (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1SystemOperatorAccessResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        operator_account_id=operator_account_id,
        target_ecosystem_id=target_ecosystem_id,
        from_=from_,
        to=to,
        after=after,
        limit=limit,
        starting_after=starting_after,
        ending_before=ending_before,
        expand=expand,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    operator_account_id: UUID | Unset = UNSET,
    target_ecosystem_id: UUID | Unset = UNSET,
    from_: datetime.datetime | Unset = UNSET,
    to: datetime.datetime | Unset = UNSET,
    after: UUID | Unset = UNSET,
    limit: int | Unset = 10,
    starting_after: str | Unset = UNSET,
    ending_before: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> GetV1SystemOperatorAccessResponse200 | StripeError | None:
    """Admin-only operator access log (newest first, cursor-paged)

     Replaces GET /system/operator-access.

    Args:
        operator_account_id (UUID | Unset):
        target_ecosystem_id (UUID | Unset):
        from_ (datetime.datetime | Unset):
        to (datetime.datetime | Unset):
        after (UUID | Unset):
        limit (int | Unset):  Default: 10.
        starting_after (str | Unset):
        ending_before (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1SystemOperatorAccessResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            client=client,
            operator_account_id=operator_account_id,
            target_ecosystem_id=target_ecosystem_id,
            from_=from_,
            to=to,
            after=after,
            limit=limit,
            starting_after=starting_after,
            ending_before=ending_before,
            expand=expand,
        )
    ).parsed
