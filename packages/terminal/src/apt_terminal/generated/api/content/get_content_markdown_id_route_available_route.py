from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.get_content_markdown_id_route_available_route_response_200 import (
    GetContentMarkdownIdRouteAvailableRouteResponse200,
)
from ...types import UNSET, Response, Unset


def _get_kwargs(
    id: str,
    route: str,
    *,
    workspace: str | Unset = UNSET,
    ecosystem_id: str | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["workspace"] = workspace

    params["ecosystemId"] = ecosystem_id

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/content/markdown/{id}/route-available/{route}".format(
            id=quote(str(id), safe=""),
            route=quote(str(route), safe=""),
        ),
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | GetContentMarkdownIdRouteAvailableRouteResponse200 | None:
    if response.status_code == 200:
        response_200 = GetContentMarkdownIdRouteAvailableRouteResponse200.from_dict(response.json())

        return response_200

    if response.status_code == 401:
        response_401 = Error.from_dict(response.json())

        return response_401

    if response.status_code == 404:
        response_404 = Error.from_dict(response.json())

        return response_404

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | GetContentMarkdownIdRouteAvailableRouteResponse200]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    id: str,
    route: str,
    *,
    client: AuthenticatedClient,
    workspace: str | Unset = UNSET,
    ecosystem_id: str | Unset = UNSET,
) -> Response[Error | GetContentMarkdownIdRouteAvailableRouteResponse200]:
    """Check whether a public route slug is free for this document

     The live availability check behind the publish field. It answers the SAME question `POST
    /{id}/publish` answers with a 409, against the same author and the same exclusion (a document’s own
    route is never taken for itself), so the two can never disagree. Always 200 with a verdict — an
    unavailable route is an answer, not an error. 404s a missing, deleted, or non-owned document BEFORE
    looking at the route, so it cannot be used to probe another author’s slug space.

    Args:
        id (str):
        route (str):
        workspace (str | Unset):
        ecosystem_id (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GetContentMarkdownIdRouteAvailableRouteResponse200]
    """

    kwargs = _get_kwargs(
        id=id,
        route=route,
        workspace=workspace,
        ecosystem_id=ecosystem_id,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    route: str,
    *,
    client: AuthenticatedClient,
    workspace: str | Unset = UNSET,
    ecosystem_id: str | Unset = UNSET,
) -> Error | GetContentMarkdownIdRouteAvailableRouteResponse200 | None:
    """Check whether a public route slug is free for this document

     The live availability check behind the publish field. It answers the SAME question `POST
    /{id}/publish` answers with a 409, against the same author and the same exclusion (a document’s own
    route is never taken for itself), so the two can never disagree. Always 200 with a verdict — an
    unavailable route is an answer, not an error. 404s a missing, deleted, or non-owned document BEFORE
    looking at the route, so it cannot be used to probe another author’s slug space.

    Args:
        id (str):
        route (str):
        workspace (str | Unset):
        ecosystem_id (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GetContentMarkdownIdRouteAvailableRouteResponse200
    """

    return sync_detailed(
        id=id,
        route=route,
        client=client,
        workspace=workspace,
        ecosystem_id=ecosystem_id,
    ).parsed


async def asyncio_detailed(
    id: str,
    route: str,
    *,
    client: AuthenticatedClient,
    workspace: str | Unset = UNSET,
    ecosystem_id: str | Unset = UNSET,
) -> Response[Error | GetContentMarkdownIdRouteAvailableRouteResponse200]:
    """Check whether a public route slug is free for this document

     The live availability check behind the publish field. It answers the SAME question `POST
    /{id}/publish` answers with a 409, against the same author and the same exclusion (a document’s own
    route is never taken for itself), so the two can never disagree. Always 200 with a verdict — an
    unavailable route is an answer, not an error. 404s a missing, deleted, or non-owned document BEFORE
    looking at the route, so it cannot be used to probe another author’s slug space.

    Args:
        id (str):
        route (str):
        workspace (str | Unset):
        ecosystem_id (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GetContentMarkdownIdRouteAvailableRouteResponse200]
    """

    kwargs = _get_kwargs(
        id=id,
        route=route,
        workspace=workspace,
        ecosystem_id=ecosystem_id,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    route: str,
    *,
    client: AuthenticatedClient,
    workspace: str | Unset = UNSET,
    ecosystem_id: str | Unset = UNSET,
) -> Error | GetContentMarkdownIdRouteAvailableRouteResponse200 | None:
    """Check whether a public route slug is free for this document

     The live availability check behind the publish field. It answers the SAME question `POST
    /{id}/publish` answers with a 409, against the same author and the same exclusion (a document’s own
    route is never taken for itself), so the two can never disagree. Always 200 with a verdict — an
    unavailable route is an answer, not an error. 404s a missing, deleted, or non-owned document BEFORE
    looking at the route, so it cannot be used to probe another author’s slug space.

    Args:
        id (str):
        route (str):
        workspace (str | Unset):
        ecosystem_id (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GetContentMarkdownIdRouteAvailableRouteResponse200
    """

    return (
        await asyncio_detailed(
            id=id,
            route=route,
            client=client,
            workspace=workspace,
            ecosystem_id=ecosystem_id,
        )
    ).parsed
