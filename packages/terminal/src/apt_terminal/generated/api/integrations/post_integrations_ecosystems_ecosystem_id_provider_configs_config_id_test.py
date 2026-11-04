from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.integration_test_result import IntegrationTestResult
from ...models.problem_details import ProblemDetails
from ...types import Response


def _get_kwargs(
    ecosystem_id: str,
    config_id: str,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/integrations/ecosystems/{ecosystem_id}/provider-configs/{config_id}/test".format(
            ecosystem_id=quote(str(ecosystem_id), safe=""),
            config_id=quote(str(config_id), safe=""),
        ),
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> IntegrationTestResult | ProblemDetails | None:
    if response.status_code == 200:
        response_200 = IntegrationTestResult.from_dict(response.json())

        return response_200

    if response.status_code == 400:
        response_400 = ProblemDetails.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = ProblemDetails.from_dict(response.json())

        return response_401

    if response.status_code == 403:
        response_403 = ProblemDetails.from_dict(response.json())

        return response_403

    if response.status_code == 404:
        response_404 = ProblemDetails.from_dict(response.json())

        return response_404

    if response.status_code == 503:
        response_503 = ProblemDetails.from_dict(response.json())

        return response_503

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[IntegrationTestResult | ProblemDetails]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    ecosystem_id: str,
    config_id: str,
    *,
    client: AuthenticatedClient,
) -> Response[IntegrationTestResult | ProblemDetails]:
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

    Args:
        ecosystem_id (str):
        config_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[IntegrationTestResult | ProblemDetails]
    """

    kwargs = _get_kwargs(
        ecosystem_id=ecosystem_id,
        config_id=config_id,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    ecosystem_id: str,
    config_id: str,
    *,
    client: AuthenticatedClient,
) -> IntegrationTestResult | ProblemDetails | None:
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

    Args:
        ecosystem_id (str):
        config_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        IntegrationTestResult | ProblemDetails
    """

    return sync_detailed(
        ecosystem_id=ecosystem_id,
        config_id=config_id,
        client=client,
    ).parsed


async def asyncio_detailed(
    ecosystem_id: str,
    config_id: str,
    *,
    client: AuthenticatedClient,
) -> Response[IntegrationTestResult | ProblemDetails]:
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

    Args:
        ecosystem_id (str):
        config_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[IntegrationTestResult | ProblemDetails]
    """

    kwargs = _get_kwargs(
        ecosystem_id=ecosystem_id,
        config_id=config_id,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    ecosystem_id: str,
    config_id: str,
    *,
    client: AuthenticatedClient,
) -> IntegrationTestResult | ProblemDetails | None:
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

    Args:
        ecosystem_id (str):
        config_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        IntegrationTestResult | ProblemDetails
    """

    return (
        await asyncio_detailed(
            ecosystem_id=ecosystem_id,
            config_id=config_id,
            client=client,
        )
    ).parsed
