from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.ai_processing_config_set import AiProcessingConfigSet
from ...models.ai_processing_config_set_input import AiProcessingConfigSetInput
from ...models.error import Error
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    body: AiProcessingConfigSetInput | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/processing/admin/config-sets",
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> AiProcessingConfigSet | Error | None:
    if response.status_code == 201:
        response_201 = AiProcessingConfigSet.from_dict(response.json())

        return response_201

    if response.status_code == 400:
        response_400 = Error.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = Error.from_dict(response.json())

        return response_401

    if response.status_code == 403:
        response_403 = Error.from_dict(response.json())

        return response_403

    if response.status_code == 409:
        response_409 = Error.from_dict(response.json())

        return response_409

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[AiProcessingConfigSet | Error]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    body: AiProcessingConfigSetInput | Unset = UNSET,
) -> Response[AiProcessingConfigSet | Error]:
    """Create an LLM config set (admin)

     A set names a personas service plus a model, or no service = the node local LLM. A paid service may
    sit on any host its kind speaks — an OpenAI-compatible service (Groq, Cerebras, Fireworks, Together,
    …) is kind openai with its own base URL. A service whose kind no node can run, or a model the
    service does not offer, is 400; a duplicate name is 409.

    Args:
        body (AiProcessingConfigSetInput | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[AiProcessingConfigSet | Error]
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
    body: AiProcessingConfigSetInput | Unset = UNSET,
) -> AiProcessingConfigSet | Error | None:
    """Create an LLM config set (admin)

     A set names a personas service plus a model, or no service = the node local LLM. A paid service may
    sit on any host its kind speaks — an OpenAI-compatible service (Groq, Cerebras, Fireworks, Together,
    …) is kind openai with its own base URL. A service whose kind no node can run, or a model the
    service does not offer, is 400; a duplicate name is 409.

    Args:
        body (AiProcessingConfigSetInput | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        AiProcessingConfigSet | Error
    """

    return sync_detailed(
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    body: AiProcessingConfigSetInput | Unset = UNSET,
) -> Response[AiProcessingConfigSet | Error]:
    """Create an LLM config set (admin)

     A set names a personas service plus a model, or no service = the node local LLM. A paid service may
    sit on any host its kind speaks — an OpenAI-compatible service (Groq, Cerebras, Fireworks, Together,
    …) is kind openai with its own base URL. A service whose kind no node can run, or a model the
    service does not offer, is 400; a duplicate name is 409.

    Args:
        body (AiProcessingConfigSetInput | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[AiProcessingConfigSet | Error]
    """

    kwargs = _get_kwargs(
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    body: AiProcessingConfigSetInput | Unset = UNSET,
) -> AiProcessingConfigSet | Error | None:
    """Create an LLM config set (admin)

     A set names a personas service plus a model, or no service = the node local LLM. A paid service may
    sit on any host its kind speaks — an OpenAI-compatible service (Groq, Cerebras, Fireworks, Together,
    …) is kind openai with its own base URL. A service whose kind no node can run, or a model the
    service does not offer, is 400; a duplicate name is 409.

    Args:
        body (AiProcessingConfigSetInput | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        AiProcessingConfigSet | Error
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
        )
    ).parsed
