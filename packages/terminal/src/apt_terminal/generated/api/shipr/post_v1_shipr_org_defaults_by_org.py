from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.post_v1_shipr_org_defaults_by_org_body import PostV1ShiprOrgDefaultsByOrgBody
from ...models.post_v1_shipr_org_defaults_by_org_response_200 import (
    PostV1ShiprOrgDefaultsByOrgResponse200,
)
from ...models.stripe_error import StripeError
from ...types import UNSET, Response, Unset


def _get_kwargs(
    org: str,
    *,
    body: PostV1ShiprOrgDefaultsByOrgBody,
    workspace: str | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    params: dict[str, Any] = {}

    params["workspace"] = workspace

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/shipr/org_defaults/{org}".format(
            org=quote(str(org), safe=""),
        ),
        "params": params,
    }

    _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostV1ShiprOrgDefaultsByOrgResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = PostV1ShiprOrgDefaultsByOrgResponse200.from_dict(response.json())

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
) -> Response[PostV1ShiprOrgDefaultsByOrgResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    org: str,
    *,
    client: AuthenticatedClient,
    body: PostV1ShiprOrgDefaultsByOrgBody,
    workspace: str | Unset = UNSET,
) -> Response[PostV1ShiprOrgDefaultsByOrgResponse200 | StripeError]:
    """Set one org’s defaults

     UPSERT, because “the defaults for this org” is one row whether or not anybody has written it yet. IT
    PROVISIONS NOTHING AND CHANGES NO EXISTING MIRROR — a default is read when a mirror is born, so
    writing one re-aims the next repository and leaves every registered one where the operator put it.
    An ABSENT field is left alone rather than reset, so a request about environments cannot quietly
    restore the suffix.

    Replaces PUT /shipr/org-defaults/{org}.

    Args:
        org (str):
        workspace (str | Unset):
        body (PostV1ShiprOrgDefaultsByOrgBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1ShiprOrgDefaultsByOrgResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        org=org,
        body=body,
        workspace=workspace,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    org: str,
    *,
    client: AuthenticatedClient,
    body: PostV1ShiprOrgDefaultsByOrgBody,
    workspace: str | Unset = UNSET,
) -> PostV1ShiprOrgDefaultsByOrgResponse200 | StripeError | None:
    """Set one org’s defaults

     UPSERT, because “the defaults for this org” is one row whether or not anybody has written it yet. IT
    PROVISIONS NOTHING AND CHANGES NO EXISTING MIRROR — a default is read when a mirror is born, so
    writing one re-aims the next repository and leaves every registered one where the operator put it.
    An ABSENT field is left alone rather than reset, so a request about environments cannot quietly
    restore the suffix.

    Replaces PUT /shipr/org-defaults/{org}.

    Args:
        org (str):
        workspace (str | Unset):
        body (PostV1ShiprOrgDefaultsByOrgBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1ShiprOrgDefaultsByOrgResponse200 | StripeError
    """

    return sync_detailed(
        org=org,
        client=client,
        body=body,
        workspace=workspace,
    ).parsed


async def asyncio_detailed(
    org: str,
    *,
    client: AuthenticatedClient,
    body: PostV1ShiprOrgDefaultsByOrgBody,
    workspace: str | Unset = UNSET,
) -> Response[PostV1ShiprOrgDefaultsByOrgResponse200 | StripeError]:
    """Set one org’s defaults

     UPSERT, because “the defaults for this org” is one row whether or not anybody has written it yet. IT
    PROVISIONS NOTHING AND CHANGES NO EXISTING MIRROR — a default is read when a mirror is born, so
    writing one re-aims the next repository and leaves every registered one where the operator put it.
    An ABSENT field is left alone rather than reset, so a request about environments cannot quietly
    restore the suffix.

    Replaces PUT /shipr/org-defaults/{org}.

    Args:
        org (str):
        workspace (str | Unset):
        body (PostV1ShiprOrgDefaultsByOrgBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1ShiprOrgDefaultsByOrgResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        org=org,
        body=body,
        workspace=workspace,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    org: str,
    *,
    client: AuthenticatedClient,
    body: PostV1ShiprOrgDefaultsByOrgBody,
    workspace: str | Unset = UNSET,
) -> PostV1ShiprOrgDefaultsByOrgResponse200 | StripeError | None:
    """Set one org’s defaults

     UPSERT, because “the defaults for this org” is one row whether or not anybody has written it yet. IT
    PROVISIONS NOTHING AND CHANGES NO EXISTING MIRROR — a default is read when a mirror is born, so
    writing one re-aims the next repository and leaves every registered one where the operator put it.
    An ABSENT field is left alone rather than reset, so a request about environments cannot quietly
    restore the suffix.

    Replaces PUT /shipr/org-defaults/{org}.

    Args:
        org (str):
        workspace (str | Unset):
        body (PostV1ShiprOrgDefaultsByOrgBody):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1ShiprOrgDefaultsByOrgResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            org=org,
            client=client,
            body=body,
            workspace=workspace,
        )
    ).parsed
