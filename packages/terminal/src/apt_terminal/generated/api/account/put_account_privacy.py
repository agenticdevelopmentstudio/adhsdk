from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.privacy_grant import PrivacyGrant
from ...models.put_account_privacy_body import PutAccountPrivacyBody
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    body: PutAccountPrivacyBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "put",
        "url": "/account/privacy",
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | PrivacyGrant | None:
    if response.status_code == 200:
        response_200 = PrivacyGrant.from_dict(response.json())

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
) -> Response[Error | PrivacyGrant]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    body: PutAccountPrivacyBody | Unset = UNSET,
) -> Response[Error | PrivacyGrant]:
    """Set one card row's audience (upsert; PUBLIC/HUB only, 0 = only-me)

    Args:
        body (PutAccountPrivacyBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PrivacyGrant]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    body: PutAccountPrivacyBody | Unset = UNSET,
) -> Error | PrivacyGrant | None:
    """Set one card row's audience (upsert; PUBLIC/HUB only, 0 = only-me)

    Args:
        body (PutAccountPrivacyBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PrivacyGrant
    """

    return sync_detailed(
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    body: PutAccountPrivacyBody | Unset = UNSET,
) -> Response[Error | PrivacyGrant]:
    """Set one card row's audience (upsert; PUBLIC/HUB only, 0 = only-me)

    Args:
        body (PutAccountPrivacyBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PrivacyGrant]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    body: PutAccountPrivacyBody | Unset = UNSET,
) -> Error | PrivacyGrant | None:
    """Set one card row's audience (upsert; PUBLIC/HUB only, 0 = only-me)

    Args:
        body (PutAccountPrivacyBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PrivacyGrant
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
        )
    ).parsed
