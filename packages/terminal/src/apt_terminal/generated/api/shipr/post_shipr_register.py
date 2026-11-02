from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.post_shipr_register_body import PostShiprRegisterBody
from ...models.post_shipr_register_response_201 import PostShiprRegisterResponse201
from ...models.post_shipr_register_response_202 import PostShiprRegisterResponse202
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    body: PostShiprRegisterBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    params: dict[str, Any] = {}

    params["workspace"] = workspace

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/shipr/register",
        "params": params,
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | PostShiprRegisterResponse201 | PostShiprRegisterResponse202 | None:
    if response.status_code == 201:
        response_201 = PostShiprRegisterResponse201.from_dict(response.json())

        return response_201

    if response.status_code == 202:
        response_202 = PostShiprRegisterResponse202.from_dict(response.json())

        return response_202

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

    if response.status_code == 409:
        response_409 = Error.from_dict(response.json())

        return response_409

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | PostShiprRegisterResponse201 | PostShiprRegisterResponse202]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    body: PostShiprRegisterBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> Response[Error | PostShiprRegisterResponse201 | PostShiprRegisterResponse202]:
    """Register a source repository and queue its provisioning

     Find-or-create on the dev repo, then a register run. Re-registering is the ordinary path — it is how
    branch protection someone turned off gets repaired. What the repository deploys (how many mirrors,
    under what names) is read from its own `.shipr` by the run, not supplied here.

    Args:
        workspace (str | Unset):
        body (PostShiprRegisterBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PostShiprRegisterResponse201 | PostShiprRegisterResponse202]
    """

    kwargs = _get_kwargs(
        body=body,
        workspace=workspace,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    body: PostShiprRegisterBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> Error | PostShiprRegisterResponse201 | PostShiprRegisterResponse202 | None:
    """Register a source repository and queue its provisioning

     Find-or-create on the dev repo, then a register run. Re-registering is the ordinary path — it is how
    branch protection someone turned off gets repaired. What the repository deploys (how many mirrors,
    under what names) is read from its own `.shipr` by the run, not supplied here.

    Args:
        workspace (str | Unset):
        body (PostShiprRegisterBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PostShiprRegisterResponse201 | PostShiprRegisterResponse202
    """

    return sync_detailed(
        client=client,
        body=body,
        workspace=workspace,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    body: PostShiprRegisterBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> Response[Error | PostShiprRegisterResponse201 | PostShiprRegisterResponse202]:
    """Register a source repository and queue its provisioning

     Find-or-create on the dev repo, then a register run. Re-registering is the ordinary path — it is how
    branch protection someone turned off gets repaired. What the repository deploys (how many mirrors,
    under what names) is read from its own `.shipr` by the run, not supplied here.

    Args:
        workspace (str | Unset):
        body (PostShiprRegisterBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | PostShiprRegisterResponse201 | PostShiprRegisterResponse202]
    """

    kwargs = _get_kwargs(
        body=body,
        workspace=workspace,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    body: PostShiprRegisterBody | Unset = UNSET,
    workspace: str | Unset = UNSET,
) -> Error | PostShiprRegisterResponse201 | PostShiprRegisterResponse202 | None:
    """Register a source repository and queue its provisioning

     Find-or-create on the dev repo, then a register run. Re-registering is the ordinary path — it is how
    branch protection someone turned off gets repaired. What the repository deploys (how many mirrors,
    under what names) is read from its own `.shipr` by the run, not supplied here.

    Args:
        workspace (str | Unset):
        body (PostShiprRegisterBody | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | PostShiprRegisterResponse201 | PostShiprRegisterResponse202
    """

    return (
        await asyncio_detailed(
            client=client,
            body=body,
            workspace=workspace,
        )
    ).parsed
