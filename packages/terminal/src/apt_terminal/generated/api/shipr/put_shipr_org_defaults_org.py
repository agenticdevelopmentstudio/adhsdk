from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.put_shipr_org_defaults_org_body import PutShiprOrgDefaultsOrgBody
from ...models.shipr_org_defaults import ShiprOrgDefaults
from ...types import UNSET, Response, Unset


def _get_kwargs(
    org: str,
    *,
    body: PutShiprOrgDefaultsOrgBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    params: dict[str, Any] = {}

    params["workspace"] = workspace

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "put",
        "url": "/shipr/org-defaults/{org}".format(
            org=quote(str(org), safe=""),
        ),
        "params": params,
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | ShiprOrgDefaults | None:
    if response.status_code == 200:
        response_200 = ShiprOrgDefaults.from_dict(response.json())

        return response_200

    if response.status_code == 400:
        response_400 = Error.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = Error.from_dict(response.json())

        return response_401

    if response.status_code == 403:
        response_403 = Error.from_dict(response.json())

        return response_403

    if response.status_code == 404:
        response_404 = Error.from_dict(response.json())

        return response_404

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | ShiprOrgDefaults]:
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
    body: PutShiprOrgDefaultsOrgBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> Response[Error | ShiprOrgDefaults]:
    """Set one org’s defaults

     UPSERT, because “the defaults for this org” is one row whether or not anybody has written it yet. IT
    PROVISIONS NOTHING AND CHANGES NO EXISTING MIRROR — a default is read when a mirror is born, so
    writing one re-aims the next repository and leaves every registered one where the operator put it.
    An ABSENT field is left alone rather than reset, so a request about environments cannot quietly
    restore the suffix.

    Args:
        org (str):
        workspace (str | Unset):
        body (PutShiprOrgDefaultsOrgBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | ShiprOrgDefaults]
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
    body: PutShiprOrgDefaultsOrgBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> Error | ShiprOrgDefaults | None:
    """Set one org’s defaults

     UPSERT, because “the defaults for this org” is one row whether or not anybody has written it yet. IT
    PROVISIONS NOTHING AND CHANGES NO EXISTING MIRROR — a default is read when a mirror is born, so
    writing one re-aims the next repository and leaves every registered one where the operator put it.
    An ABSENT field is left alone rather than reset, so a request about environments cannot quietly
    restore the suffix.

    Args:
        org (str):
        workspace (str | Unset):
        body (PutShiprOrgDefaultsOrgBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | ShiprOrgDefaults
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
    body: PutShiprOrgDefaultsOrgBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> Response[Error | ShiprOrgDefaults]:
    """Set one org’s defaults

     UPSERT, because “the defaults for this org” is one row whether or not anybody has written it yet. IT
    PROVISIONS NOTHING AND CHANGES NO EXISTING MIRROR — a default is read when a mirror is born, so
    writing one re-aims the next repository and leaves every registered one where the operator put it.
    An ABSENT field is left alone rather than reset, so a request about environments cannot quietly
    restore the suffix.

    Args:
        org (str):
        workspace (str | Unset):
        body (PutShiprOrgDefaultsOrgBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | ShiprOrgDefaults]
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
    body: PutShiprOrgDefaultsOrgBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> Error | ShiprOrgDefaults | None:
    """Set one org’s defaults

     UPSERT, because “the defaults for this org” is one row whether or not anybody has written it yet. IT
    PROVISIONS NOTHING AND CHANGES NO EXISTING MIRROR — a default is read when a mirror is born, so
    writing one re-aims the next repository and leaves every registered one where the operator put it.
    An ABSENT field is left alone rather than reset, so a request about environments cannot quietly
    restore the suffix.

    Args:
        org (str):
        workspace (str | Unset):
        body (PutShiprOrgDefaultsOrgBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | ShiprOrgDefaults
    """

    return (
        await asyncio_detailed(
            org=org,
            client=client,
            body=body,
            workspace=workspace,
        )
    ).parsed
