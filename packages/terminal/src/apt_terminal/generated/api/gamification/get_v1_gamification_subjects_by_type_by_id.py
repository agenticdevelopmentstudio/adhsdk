from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.get_v1_gamification_subjects_by_type_by_id_include_item import (
    GetV1GamificationSubjectsByTypeByIdIncludeItem,
)
from ...models.get_v1_gamification_subjects_by_type_by_id_response_200 import (
    GetV1GamificationSubjectsByTypeByIdResponse200,
)
from ...models.stripe_error import StripeError
from ...types import UNSET, Response, Unset


def _get_kwargs(
    type_: str,
    id: str,
    *,
    expand: list[str] | Unset = UNSET,
    include: list[GetV1GamificationSubjectsByTypeByIdIncludeItem] | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    json_expand: list[str] | Unset = UNSET
    if not isinstance(expand, Unset):
        json_expand = expand

    params["expand[]"] = json_expand

    json_include: list[str] | Unset = UNSET
    if not isinstance(include, Unset):
        json_include = []
        for include_item_data in include:
            include_item = include_item_data.value
            json_include.append(include_item)

    params["include[]"] = json_include

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/v1/gamification/subjects/{type_}/{id}".format(
            type_=quote(str(type_), safe=""),
            id=quote(str(id), safe=""),
        ),
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> GetV1GamificationSubjectsByTypeByIdResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = GetV1GamificationSubjectsByTypeByIdResponse200.from_dict(response.json())

        return response_200

    if response.status_code == 401:
        response_401 = StripeError.from_dict(response.json())

        return response_401

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[GetV1GamificationSubjectsByTypeByIdResponse200 | StripeError]:
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
    expand: list[str] | Unset = UNSET,
    include: list[GetV1GamificationSubjectsByTypeByIdIncludeItem] | Unset = UNSET,
) -> Response[GetV1GamificationSubjectsByTypeByIdResponse200 | StripeError]:
    """A subject’s gamification summary (points, level, badges, opt-out)

     Replaces GET /gamification/subjects/{subjectType}/{subjectId}, GET
    /gamification/subjects/{subjectType}/{subjectId}/points (include points).

    Args:
        type_ (str):
        id (str):
        expand (list[str] | Unset):
        include (list[GetV1GamificationSubjectsByTypeByIdIncludeItem] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1GamificationSubjectsByTypeByIdResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        type_=type_,
        id=id,
        expand=expand,
        include=include,
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
    expand: list[str] | Unset = UNSET,
    include: list[GetV1GamificationSubjectsByTypeByIdIncludeItem] | Unset = UNSET,
) -> GetV1GamificationSubjectsByTypeByIdResponse200 | StripeError | None:
    """A subject’s gamification summary (points, level, badges, opt-out)

     Replaces GET /gamification/subjects/{subjectType}/{subjectId}, GET
    /gamification/subjects/{subjectType}/{subjectId}/points (include points).

    Args:
        type_ (str):
        id (str):
        expand (list[str] | Unset):
        include (list[GetV1GamificationSubjectsByTypeByIdIncludeItem] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1GamificationSubjectsByTypeByIdResponse200 | StripeError
    """

    return sync_detailed(
        type_=type_,
        id=id,
        client=client,
        expand=expand,
        include=include,
    ).parsed


async def asyncio_detailed(
    type_: str,
    id: str,
    *,
    client: AuthenticatedClient,
    expand: list[str] | Unset = UNSET,
    include: list[GetV1GamificationSubjectsByTypeByIdIncludeItem] | Unset = UNSET,
) -> Response[GetV1GamificationSubjectsByTypeByIdResponse200 | StripeError]:
    """A subject’s gamification summary (points, level, badges, opt-out)

     Replaces GET /gamification/subjects/{subjectType}/{subjectId}, GET
    /gamification/subjects/{subjectType}/{subjectId}/points (include points).

    Args:
        type_ (str):
        id (str):
        expand (list[str] | Unset):
        include (list[GetV1GamificationSubjectsByTypeByIdIncludeItem] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1GamificationSubjectsByTypeByIdResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        type_=type_,
        id=id,
        expand=expand,
        include=include,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    type_: str,
    id: str,
    *,
    client: AuthenticatedClient,
    expand: list[str] | Unset = UNSET,
    include: list[GetV1GamificationSubjectsByTypeByIdIncludeItem] | Unset = UNSET,
) -> GetV1GamificationSubjectsByTypeByIdResponse200 | StripeError | None:
    """A subject’s gamification summary (points, level, badges, opt-out)

     Replaces GET /gamification/subjects/{subjectType}/{subjectId}, GET
    /gamification/subjects/{subjectType}/{subjectId}/points (include points).

    Args:
        type_ (str):
        id (str):
        expand (list[str] | Unset):
        include (list[GetV1GamificationSubjectsByTypeByIdIncludeItem] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1GamificationSubjectsByTypeByIdResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            type_=type_,
            id=id,
            client=client,
            expand=expand,
            include=include,
        )
    ).parsed
