from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.post_persona_provider_templates_id_verify_body import (
    PostPersonaProviderTemplatesIdVerifyBody,
)
from ...models.provider_template_verify_result import ProviderTemplateVerifyResult
from ...types import UNSET, Response, Unset


def _get_kwargs(
    id: str,
    *,
    body: PostPersonaProviderTemplatesIdVerifyBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/persona/provider-templates/{id}/verify".format(
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
) -> Error | ProviderTemplateVerifyResult | None:
    if response.status_code == 200:
        response_200 = ProviderTemplateVerifyResult.from_dict(response.json())

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
) -> Response[Error | ProviderTemplateVerifyResult]:
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
    body: PostPersonaProviderTemplatesIdVerifyBody | Unset = UNSET,
) -> Response[Error | ProviderTemplateVerifyResult]:
    """Probe the live provider with a caller-supplied key — never stored — to verify kind/baseUrl speak the
    claimed contract (admin)

    Args:
        id (str):
        body (PostPersonaProviderTemplatesIdVerifyBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | ProviderTemplateVerifyResult]
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
    body: PostPersonaProviderTemplatesIdVerifyBody | Unset = UNSET,
) -> Error | ProviderTemplateVerifyResult | None:
    """Probe the live provider with a caller-supplied key — never stored — to verify kind/baseUrl speak the
    claimed contract (admin)

    Args:
        id (str):
        body (PostPersonaProviderTemplatesIdVerifyBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | ProviderTemplateVerifyResult
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
    body: PostPersonaProviderTemplatesIdVerifyBody | Unset = UNSET,
) -> Response[Error | ProviderTemplateVerifyResult]:
    """Probe the live provider with a caller-supplied key — never stored — to verify kind/baseUrl speak the
    claimed contract (admin)

    Args:
        id (str):
        body (PostPersonaProviderTemplatesIdVerifyBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | ProviderTemplateVerifyResult]
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
    body: PostPersonaProviderTemplatesIdVerifyBody | Unset = UNSET,
) -> Error | ProviderTemplateVerifyResult | None:
    """Probe the live provider with a caller-supplied key — never stored — to verify kind/baseUrl speak the
    claimed contract (admin)

    Args:
        id (str):
        body (PostPersonaProviderTemplatesIdVerifyBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | ProviderTemplateVerifyResult
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
            body=body,
        )
    ).parsed
