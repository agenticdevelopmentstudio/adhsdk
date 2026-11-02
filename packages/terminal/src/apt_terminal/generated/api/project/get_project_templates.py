from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.project_template import ProjectTemplate
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    workspace: str | Unset = UNSET,
    kind: str | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["workspace"] = workspace

    params["kind"] = kind

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/project/templates",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | list[ProjectTemplate] | None:
    if response.status_code == 200:
        response_200 = []
        _response_200 = response.json()
        for response_200_item_data in _response_200:
            response_200_item = ProjectTemplate.from_dict(response_200_item_data)

            response_200.append(response_200_item)

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
) -> Response[Error | list[ProjectTemplate]]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    workspace: str | Unset = UNSET,
    kind: str | Unset = UNSET,
) -> Response[Error | list[ProjectTemplate]]:
    """List the templates in the caller's reach (non-deleted, by name)

     Ordered by name, case-folded — this list is a picker, like the programs list. Capped lower than the
    other pickers (200) because every row carries its BODY, which is the one thing a chooser has to
    preview and the one thing that makes a template row big.

    Args:
        workspace (str | Unset):
        kind (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | list[ProjectTemplate]]
    """

    kwargs = _get_kwargs(
        workspace=workspace,
        kind=kind,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    workspace: str | Unset = UNSET,
    kind: str | Unset = UNSET,
) -> Error | list[ProjectTemplate] | None:
    """List the templates in the caller's reach (non-deleted, by name)

     Ordered by name, case-folded — this list is a picker, like the programs list. Capped lower than the
    other pickers (200) because every row carries its BODY, which is the one thing a chooser has to
    preview and the one thing that makes a template row big.

    Args:
        workspace (str | Unset):
        kind (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | list[ProjectTemplate]
    """

    return sync_detailed(
        client=client,
        workspace=workspace,
        kind=kind,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    workspace: str | Unset = UNSET,
    kind: str | Unset = UNSET,
) -> Response[Error | list[ProjectTemplate]]:
    """List the templates in the caller's reach (non-deleted, by name)

     Ordered by name, case-folded — this list is a picker, like the programs list. Capped lower than the
    other pickers (200) because every row carries its BODY, which is the one thing a chooser has to
    preview and the one thing that makes a template row big.

    Args:
        workspace (str | Unset):
        kind (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | list[ProjectTemplate]]
    """

    kwargs = _get_kwargs(
        workspace=workspace,
        kind=kind,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    workspace: str | Unset = UNSET,
    kind: str | Unset = UNSET,
) -> Error | list[ProjectTemplate] | None:
    """List the templates in the caller's reach (non-deleted, by name)

     Ordered by name, case-folded — this list is a picker, like the programs list. Capped lower than the
    other pickers (200) because every row carries its BODY, which is the one thing a chooser has to
    preview and the one thing that makes a template row big.

    Args:
        workspace (str | Unset):
        kind (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | list[ProjectTemplate]
    """

    return (
        await asyncio_detailed(
            client=client,
            workspace=workspace,
            kind=kind,
        )
    ).parsed
