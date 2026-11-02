from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.put_usage_principal_tiers_scope_principal_id_body import (
    PutUsagePrincipalTiersScopePrincipalIdBody,
)
from ...models.put_usage_principal_tiers_scope_principal_id_response_200 import (
    PutUsagePrincipalTiersScopePrincipalIdResponse200,
)
from ...types import UNSET, Response, Unset


def _get_kwargs(
    scope: str,
    principal_id: str,
    *,
    body: PutUsagePrincipalTiersScopePrincipalIdBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "put",
        "url": "/usage/principal-tiers/{scope}/{principal_id}".format(
            scope=quote(str(scope), safe=""),
            principal_id=quote(str(principal_id), safe=""),
        ),
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | PutUsagePrincipalTiersScopePrincipalIdResponse200 | None:
    if response.status_code == 200:
        response_200 = PutUsagePrincipalTiersScopePrincipalIdResponse200.from_dict(response.json())

        return response_200

    if response.status_code == 400:
        response_400 = Error.from_dict(response.json())

        return response_400

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
) -> Response[Error | PutUsagePrincipalTiersScopePrincipalIdResponse200]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    scope: str,
    principal_id: str,
    *,
    client: AuthenticatedClient,
    body: PutUsagePrincipalTiersScopePrincipalIdBody | Unset = UNSET,
) -> Response[Error | PutUsagePrincipalTiersScopePrincipalIdResponse200]:
    """Update principal_tiers

    Args:
        scope (str):
        principal_id (str):
        body (PutUsagePrincipalTiersScopePrincipalIdBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PutUsagePrincipalTiersScopePrincipalIdResponse200]
    """

    kwargs = _get_kwargs(
        scope=scope,
        principal_id=principal_id,
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    scope: str,
    principal_id: str,
    *,
    client: AuthenticatedClient,
    body: PutUsagePrincipalTiersScopePrincipalIdBody | Unset = UNSET,
) -> Error | PutUsagePrincipalTiersScopePrincipalIdResponse200 | None:
    """Update principal_tiers

    Args:
        scope (str):
        principal_id (str):
        body (PutUsagePrincipalTiersScopePrincipalIdBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PutUsagePrincipalTiersScopePrincipalIdResponse200
    """

    return sync_detailed(
        scope=scope,
        principal_id=principal_id,
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    scope: str,
    principal_id: str,
    *,
    client: AuthenticatedClient,
    body: PutUsagePrincipalTiersScopePrincipalIdBody | Unset = UNSET,
) -> Response[Error | PutUsagePrincipalTiersScopePrincipalIdResponse200]:
    """Update principal_tiers

    Args:
        scope (str):
        principal_id (str):
        body (PutUsagePrincipalTiersScopePrincipalIdBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PutUsagePrincipalTiersScopePrincipalIdResponse200]
    """

    kwargs = _get_kwargs(
        scope=scope,
        principal_id=principal_id,
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    scope: str,
    principal_id: str,
    *,
    client: AuthenticatedClient,
    body: PutUsagePrincipalTiersScopePrincipalIdBody | Unset = UNSET,
) -> Error | PutUsagePrincipalTiersScopePrincipalIdResponse200 | None:
    """Update principal_tiers

    Args:
        scope (str):
        principal_id (str):
        body (PutUsagePrincipalTiersScopePrincipalIdBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PutUsagePrincipalTiersScopePrincipalIdResponse200
    """

    return (
        await asyncio_detailed(
            scope=scope,
            principal_id=principal_id,
            client=client,
            body=body,
        )
    ).parsed
