from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.get_v1_organizations_response_200 import GetV1OrganizationsResponse200
from ...models.stripe_error import StripeError
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    slug: str | Unset = UNSET,
    workspace: str,
    limit: int | Unset = 10,
    starting_after: str | Unset = UNSET,
    ending_before: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["slug"] = slug

    params["workspace"] = workspace

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
        "url": "/v1/organizations",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> GetV1OrganizationsResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = GetV1OrganizationsResponse200.from_dict(response.json())

        return response_200

    if response.status_code == 400:
        response_400 = StripeError.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = StripeError.from_dict(response.json())

        return response_401

    if response.status_code == 404:
        response_404 = StripeError.from_dict(response.json())

        return response_404

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[GetV1OrganizationsResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    slug: str | Unset = UNSET,
    workspace: str,
    limit: int | Unset = 10,
    starting_after: str | Unset = UNSET,
    ending_before: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1OrganizationsResponse200 | StripeError]:
    """List the organizations a workspace owns (personal workspaces also include the ones you belong to)

     Scoped by `workspace`, which is REQUIRED — an unscoped organizations list is the same answer in
    every workspace, which is the bug this replaced. A PERSONAL workspace answers with the orgs you own
    UNION the orgs you belong to; an ORGANIZATION workspace answers with the orgs that org owns, never
    including itself. A workspace slug the caller neither owns nor reaches is a 404, the same answer as
    one that does not exist. Ordered by name (case-insensitively, ties broken by id) and capped at 500
    rows.

    Replaces GET /organization/organizations, GET /orgs/{slug}, GET /public/orgs/{slug}.

    Args:
        slug (str | Unset):
        workspace (str):
        limit (int | Unset):  Default: 10.
        starting_after (str | Unset):
        ending_before (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1OrganizationsResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        slug=slug,
        workspace=workspace,
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
    slug: str | Unset = UNSET,
    workspace: str,
    limit: int | Unset = 10,
    starting_after: str | Unset = UNSET,
    ending_before: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> GetV1OrganizationsResponse200 | StripeError | None:
    """List the organizations a workspace owns (personal workspaces also include the ones you belong to)

     Scoped by `workspace`, which is REQUIRED — an unscoped organizations list is the same answer in
    every workspace, which is the bug this replaced. A PERSONAL workspace answers with the orgs you own
    UNION the orgs you belong to; an ORGANIZATION workspace answers with the orgs that org owns, never
    including itself. A workspace slug the caller neither owns nor reaches is a 404, the same answer as
    one that does not exist. Ordered by name (case-insensitively, ties broken by id) and capped at 500
    rows.

    Replaces GET /organization/organizations, GET /orgs/{slug}, GET /public/orgs/{slug}.

    Args:
        slug (str | Unset):
        workspace (str):
        limit (int | Unset):  Default: 10.
        starting_after (str | Unset):
        ending_before (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1OrganizationsResponse200 | StripeError
    """

    return sync_detailed(
        client=client,
        slug=slug,
        workspace=workspace,
        limit=limit,
        starting_after=starting_after,
        ending_before=ending_before,
        expand=expand,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    slug: str | Unset = UNSET,
    workspace: str,
    limit: int | Unset = 10,
    starting_after: str | Unset = UNSET,
    ending_before: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> Response[GetV1OrganizationsResponse200 | StripeError]:
    """List the organizations a workspace owns (personal workspaces also include the ones you belong to)

     Scoped by `workspace`, which is REQUIRED — an unscoped organizations list is the same answer in
    every workspace, which is the bug this replaced. A PERSONAL workspace answers with the orgs you own
    UNION the orgs you belong to; an ORGANIZATION workspace answers with the orgs that org owns, never
    including itself. A workspace slug the caller neither owns nor reaches is a 404, the same answer as
    one that does not exist. Ordered by name (case-insensitively, ties broken by id) and capped at 500
    rows.

    Replaces GET /organization/organizations, GET /orgs/{slug}, GET /public/orgs/{slug}.

    Args:
        slug (str | Unset):
        workspace (str):
        limit (int | Unset):  Default: 10.
        starting_after (str | Unset):
        ending_before (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[GetV1OrganizationsResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        slug=slug,
        workspace=workspace,
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
    slug: str | Unset = UNSET,
    workspace: str,
    limit: int | Unset = 10,
    starting_after: str | Unset = UNSET,
    ending_before: str | Unset = UNSET,
    expand: list[str] | Unset = UNSET,
) -> GetV1OrganizationsResponse200 | StripeError | None:
    """List the organizations a workspace owns (personal workspaces also include the ones you belong to)

     Scoped by `workspace`, which is REQUIRED — an unscoped organizations list is the same answer in
    every workspace, which is the bug this replaced. A PERSONAL workspace answers with the orgs you own
    UNION the orgs you belong to; an ORGANIZATION workspace answers with the orgs that org owns, never
    including itself. A workspace slug the caller neither owns nor reaches is a 404, the same answer as
    one that does not exist. Ordered by name (case-insensitively, ties broken by id) and capped at 500
    rows.

    Replaces GET /organization/organizations, GET /orgs/{slug}, GET /public/orgs/{slug}.

    Args:
        slug (str | Unset):
        workspace (str):
        limit (int | Unset):  Default: 10.
        starting_after (str | Unset):
        ending_before (str | Unset):
        expand (list[str] | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        GetV1OrganizationsResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            client=client,
            slug=slug,
            workspace=workspace,
            limit=limit,
            starting_after=starting_after,
            ending_before=ending_before,
            expand=expand,
        )
    ).parsed
