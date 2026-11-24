from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.post_v1_integrations_provider_configs_by_id_test_body import (
    PostV1IntegrationsProviderConfigsByIdTestBody,
)
from ...models.post_v1_integrations_provider_configs_by_id_test_response_200 import (
    PostV1IntegrationsProviderConfigsByIdTestResponse200,
)
from ...models.stripe_error import StripeError
from ...types import UNSET, Response, Unset


def _get_kwargs(
    id: str,
    *,
    body: PostV1IntegrationsProviderConfigsByIdTestBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/v1/integrations/provider_configs/{id}/test".format(
            id=quote(str(id), safe=""),
        ),
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostV1IntegrationsProviderConfigsByIdTestResponse200 | StripeError | None:
    if response.status_code == 200:
        response_200 = PostV1IntegrationsProviderConfigsByIdTestResponse200.from_dict(
            response.json()
        )

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

    if response.status_code == 503:
        response_503 = StripeError.from_dict(response.json())

        return response_503

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[PostV1IntegrationsProviderConfigsByIdTestResponse200 | StripeError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
    body: PostV1IntegrationsProviderConfigsByIdTestBody | Unset = UNSET,
) -> Response[PostV1IntegrationsProviderConfigsByIdTestResponse200 | StripeError]:
    """Test a saved integration against its provider

     One answer, for every provider that can be asked. No body.

    FOR A GITHUB APP THE TEST IS THE ADOPT. The only way to prove an app id and private key are real is
    to mint a JWT and enumerate the installations the app can see, and that enumeration is exactly what
    creates the connection rows and warms the repository cache. So pressing Test on a saved GitHub
    integration is also what makes its orgs appear in the repository picker — deliberate, and reported
    back under `adopted`.

    Every other provider is probed READ-ONLY against the validation endpoint its template declares; a
    provider whose template declares none is a 400 naming that fact rather than a green tick it did not
    earn.

    A refused credential is 200 with `ok: false`. 404 when the config is absent or not owned by the
    ecosystem.

    Replaces POST /integrations/ecosystems/{ecosystemId}/provider-configs/{configId}/test.

    Args:
        id (str):
        body (PostV1IntegrationsProviderConfigsByIdTestBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1IntegrationsProviderConfigsByIdTestResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    *,
    client: AuthenticatedClient,
    body: PostV1IntegrationsProviderConfigsByIdTestBody | Unset = UNSET,
) -> PostV1IntegrationsProviderConfigsByIdTestResponse200 | StripeError | None:
    """Test a saved integration against its provider

     One answer, for every provider that can be asked. No body.

    FOR A GITHUB APP THE TEST IS THE ADOPT. The only way to prove an app id and private key are real is
    to mint a JWT and enumerate the installations the app can see, and that enumeration is exactly what
    creates the connection rows and warms the repository cache. So pressing Test on a saved GitHub
    integration is also what makes its orgs appear in the repository picker — deliberate, and reported
    back under `adopted`.

    Every other provider is probed READ-ONLY against the validation endpoint its template declares; a
    provider whose template declares none is a 400 naming that fact rather than a green tick it did not
    earn.

    A refused credential is 200 with `ok: false`. 404 when the config is absent or not owned by the
    ecosystem.

    Replaces POST /integrations/ecosystems/{ecosystemId}/provider-configs/{configId}/test.

    Args:
        id (str):
        body (PostV1IntegrationsProviderConfigsByIdTestBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1IntegrationsProviderConfigsByIdTestResponse200 | StripeError
    """

    return sync_detailed(
        id=id,
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
    body: PostV1IntegrationsProviderConfigsByIdTestBody | Unset = UNSET,
) -> Response[PostV1IntegrationsProviderConfigsByIdTestResponse200 | StripeError]:
    """Test a saved integration against its provider

     One answer, for every provider that can be asked. No body.

    FOR A GITHUB APP THE TEST IS THE ADOPT. The only way to prove an app id and private key are real is
    to mint a JWT and enumerate the installations the app can see, and that enumeration is exactly what
    creates the connection rows and warms the repository cache. So pressing Test on a saved GitHub
    integration is also what makes its orgs appear in the repository picker — deliberate, and reported
    back under `adopted`.

    Every other provider is probed READ-ONLY against the validation endpoint its template declares; a
    provider whose template declares none is a 400 naming that fact rather than a green tick it did not
    earn.

    A refused credential is 200 with `ok: false`. 404 when the config is absent or not owned by the
    ecosystem.

    Replaces POST /integrations/ecosystems/{ecosystemId}/provider-configs/{configId}/test.

    Args:
        id (str):
        body (PostV1IntegrationsProviderConfigsByIdTestBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostV1IntegrationsProviderConfigsByIdTestResponse200 | StripeError]
    """

    kwargs = _get_kwargs(
        id=id,
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    *,
    client: AuthenticatedClient,
    body: PostV1IntegrationsProviderConfigsByIdTestBody | Unset = UNSET,
) -> PostV1IntegrationsProviderConfigsByIdTestResponse200 | StripeError | None:
    """Test a saved integration against its provider

     One answer, for every provider that can be asked. No body.

    FOR A GITHUB APP THE TEST IS THE ADOPT. The only way to prove an app id and private key are real is
    to mint a JWT and enumerate the installations the app can see, and that enumeration is exactly what
    creates the connection rows and warms the repository cache. So pressing Test on a saved GitHub
    integration is also what makes its orgs appear in the repository picker — deliberate, and reported
    back under `adopted`.

    Every other provider is probed READ-ONLY against the validation endpoint its template declares; a
    provider whose template declares none is a 400 naming that fact rather than a green tick it did not
    earn.

    A refused credential is 200 with `ok: false`. 404 when the config is absent or not owned by the
    ecosystem.

    Replaces POST /integrations/ecosystems/{ecosystemId}/provider-configs/{configId}/test.

    Args:
        id (str):
        body (PostV1IntegrationsProviderConfigsByIdTestBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostV1IntegrationsProviderConfigsByIdTestResponse200 | StripeError
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            body=body,
        )
    ).parsed
